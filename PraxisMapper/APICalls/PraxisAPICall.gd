extends Node
class_name PraxisAPICall

#This function works in a single call, but the UI tends not to update while this is running, so we
#dont really want to use this one too much. In most cases you will want to use PraxisEndpoints instead
#of this class, but it remains here for now as an alternative.


# Based on the HTTPClient demo in the official docs. Used to make getting data a single function call.
# This simple class can do HTTP requests; it will not block, but it needs to be polled.

#NOTE: this works, but it seems to cause the app to not process anything else while it's running in a scene.

#For a game with a custom plugin, it'll basically want a node that creates an instance of this node,
#and hits call_url() with the correct parameters, then process the result accordingly and return that.
var http
var lastResponseCode #can be checked if this returns null for more info
var lastError #can be checked if this returns null for more info.

static var _isReauthing = false

signal result(data: Array)

func _init():
	var err = 0
	http = HTTPClient.new() # Create the Client. 

	var split = PraxisServer.serverURL.split(":")
	if (split.size() == 3): #http:\\url:port
		err =  http.connect_to_host(split[0] + ":" + split[1], int(split[2])) # Connect to host/port.
	elif (split.size() == 2 and !split[0].begins_with("http")): #url:port
		err =  http.connect_to_host(split[0], int(split[1])) # Connect to host/port.
	else: # url
		err = http.connect_to_host(PraxisServer.serverURL)

	assert(err == OK) # Make sure connection is OK.
	
	# Wait until resolved and connected.
	while http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING:
		http.poll()
		if not OS.has_feature("web"):
			OS.delay_msec(25)
		else:
			await get_tree().process_frame

	print(http.get_status())
	assert(http.get_status() == HTTPClient.STATUS_CONNECTED) # Check if the connection was made successfully.

func call_url(endpoint, method = HTTPClient.METHOD_GET, body = ''):
	lastError = ''
	lastResponseCode = 0
	# Some headers
	var headers = [
		"AuthKey: " + PraxisServer.authKey,
		"PraxisAuthKey: " + PraxisServer.headerKey,
		"User-Agent: Pirulo/1.0 (Godot)",
		"Accept: */*"
	]
	
	if !endpoint.begins_with("/"):
		endpoint = "/" + endpoint

	var err = http.request(method, endpoint, headers, body) # Request a page from the site (this one was chunked..)
	if (err != OK):
		lastError = error_string(err)
		return null

	while http.get_status() == HTTPClient.STATUS_REQUESTING:
		# Keep polling for as long as the request is being processed.
		http.poll()
		if OS.has_feature("web"):
			# Synchronous HTTP requests are not supported on the web,
			# so wait for the next main loop iteration.
			await get_tree().process_frame
		else:
			OS.delay_msec(25)

	assert(http.get_status() == HTTPClient.STATUS_BODY or http.get_status() == HTTPClient.STATUS_CONNECTED) # Make sure request finished well.
	if (http.get_status() != HTTPClient.STATUS_BODY and http.get_status() != HTTPClient.STATUS_CONNECTED):
		lastError = "Request Failed: " + http.get_status()
		return

	var statusCode = http.get_response_code()
	lastResponseCode = statusCode
	if (statusCode == 419):
		#reauth. TODO: better locking.
		if (_isReauthing == true):
			while _isReauthing == true:
				if OS.has_feature("web"):
					await get_tree().process_frame
				else:
					OS.delay_msec(25)
		else:		
			_isReauthing = true
			await self.Login(PraxisServer.username, PraxisServer.password)
			_isReauthing = false
		return await call_url(endpoint, method, body)
	elif(statusCode != 200 and statusCode != 204):
		lastError = str(statusCode)
		return "Error: " + str(statusCode)
	
	if http.has_response():
		# Getting the HTTP Body
		var rb = PackedByteArray() # Array that will hold the data.
		while http.get_status() == HTTPClient.STATUS_BODY:
			# While there is body left to be read
			http.poll()
			# Get a chunk.
			var chunk = http.read_response_body_chunk()
			if chunk.size() == 0:
				if not OS.has_feature("web"):
					# Got nothing, wait for buffers to fill a bit.
					OS.delay_usec(10)
				else:
					await get_tree().process_frame
			else:
				rb = rb + chunk # Append to read buffer.
		# Done!
		
		result.emit(rb) # an alternate way to get this info, but may not work if this node is shared.
		return rb #Let the caller decode this data the way they expect to have it.
	
	return true

#Pre-made calls for stock endpoints
#/Server controller APIs
func GetServerBounds(): # Server's covered area in S|W|N|E order/format
	var data = await call_url("/Server/Bounds")
	return data.get_string_from_utf8()
	
func ServerTest(): # always returns 'OK'
	var data = await call_url("/Server/Test")
	return data.get_string_from_utf8()

func MOTD(): #Message of the Day
	var data = await call_url("/Server/MOTD")
	return data.get_string_from_utf8()
	
func RandomPoint(): # A random point somewhere inside server bounds
	var data = await call_url("/Server/RandomPoint")
	return data.get_string_from_utf8()
	
func GDPRExport(): #All data available on the user as a string.
	var data = await call_url("/Server/GdprExport")
	return data.get_string_from_utf8()

func DeleteAccount():
	var data = await call_url("/Server/Account", HTTPClient.METHOD_DELETE)
	return data.get_string_from_utf8()

func Login(account, password):
	var data = await call_url("/Server/Login/" + account + "/" + password)
	return data.get_string_from_utf8()
	
func CreateAccount(account,password):
	var data = await call_url("/Server/CreateAccount/" + account + "/" + password, HTTPClient.METHOD_PUT)
	return data.get_string_from_utf8() #true or false

func ChangePassword(account, oldPassword, newPassword):
	var data = await call_url("/Server/ChangePassword/" + account + "/" + oldPassword + "/" + newPassword, HTTPClient.METHOD_PUT)
	return data.get_string_from_utf8()

#Data endpoint API calls. For games that don't have a dedicated plugin or early development testing.
#Sets return true/false, Gets usually return JSON data.
func SetAreaValue(plusCode, key, value, expiresIn = null):
	var url = "/Data/Area/" + plusCode + "/" + key
	if (expiresIn != null):
		url += "/noval/" + str(expiresIn)
	
	var data = await call_url(url, HTTPClient.METHOD_PUT, value)
	return data.get_string_from_utf8()
	
func GetAreaValue(plusCode, key):
	var data = await call_url("/Data/Area/" + plusCode + "/" + key)
	return data.get_string_from_utf8()
	
#TODO: Server doesn't currently allow for body values with expiration on Player.
func SetPlayerValue(account, key, value, expiresIn = null):
	var url = "/Data/Player/" + account + "/" + key
	if (expiresIn != null):
		url += "/" + value + "/" + str(expiresIn)
	
	var data = await call_url(url, HTTPClient.METHOD_PUT, value)
	return data.get_string_from_utf8()
	
func GetPlayerValue(account, key):
	var data = await call_url("/Data/Player/" + account + "/" + key)
	return data.get_string_from_utf8()

#TODO: Server doesn't currently allow for body values with expiration on Place
func SetPlaceValue(place, key, value, expiresIn = null):
	var url = "/Data/Place/" + place + "/" + key
	if (expiresIn != null):
		url += "/" + value + "/" + str(expiresIn)
	
	var data = await call_url(url, HTTPClient.METHOD_PUT, value)
	return data.get_string_from_utf8()

func GetPlaceValue(place, key):
	var data = await call_url("/Data/Place/" + place + "/" + key)
	return data.get_string_from_utf8()
	
func GetGlobalValue(key):
	var data = await call_url("/Data/Global/" + key)
	return data.get_string_from_utf8()

func SetGlobalValue(key, value):
	var data = await call_url("/Data/Global/" + key, HTTPClient.METHOD_PUT, value)
	return data.get_string_from_utf8()
	
func DeleteGlobalValue(key):
	var data = await call_url("/Data/Global/" + key, HTTPClient.METHOD_DELETE)
	return data.get_string_from_utf8()
	
func GetAllPlayerData(player):
	var data = await call_url("/Data/Player/All/" + player)
	return data.get_string_from_utf8()

func GetAllAreaData(player):
	var data = await call_url("/Data/Area/All/" + player)
	return data.get_string_from_utf8()

func GetAllPlaceData(place):
	var data = await call_url("/Data/Place/All/" + place)
	return data.get_string_from_utf8()

#SecureData endpoint API calls. 
func SetSecureAreaValue(plusCode, key, value, password, expiresIn = null):
	#TODO: server doesnt support value in body and expiration together.
	var url = "/SecureData/Area/" + plusCode + "/" + key
	if (expiresIn != null):
		url += "/" + value + "/" + password + "/"+ str(expiresIn)
	else:
		url += "/" + password
	
	var data = await call_url(url, HTTPClient.METHOD_PUT, value)
	return data.get_string_from_utf8()
	
func GetSecureAreaValue(plusCode, key, password):
	var data = await call_url("/SecureData/Area/" + plusCode + "/" + key + "/" + password)
	return data.get_string_from_utf8()
	
#TODO: Server doesn't currently allow for body values with expiration on Player.
func SetSecurePlayerValue(account, key, value, password, expiresIn = null):
	var url = "/SecureData/Player/" + account + "/" + key
	if (expiresIn != null):
		url += "/" + value + "/" + password + "/"+ str(expiresIn)
	else:
		url += "/" + password
	
	var data = await call_url(url, HTTPClient.METHOD_PUT, value)
	return data.get_string_from_utf8()
	
func GetSecurePlayerValue(account, key, password):
	var data = await call_url("/SecureData/Player/" + account + "/" + key + "/" + password)
	return data.get_string_from_utf8()

#TODO: Server doesn't currently allow for body values with expiration on Place
func SetSecurePlaceValue(place, key, value, password, expiresIn = null):
	var url = "/SecureData/Place/" + place + "/" + key
	if (expiresIn != null):
		url += "/" + value + "/" + password + "/"+ str(expiresIn)
	else:
		url += "/" + password
	
	var data = await call_url(url, HTTPClient.METHOD_PUT, value)
	return data.get_string_from_utf8()

func GetSecurePlaceValue(place, key, password):
	var data = await call_url("/SecureData/Place/" + place + "/" + key)
	return data.get_string_from_utf8()
	
#These don't return a value.
func IncrementSecurePlaceValue(place, key, changeAmount, password, expiresIn = null):
	var url = "/SecureData/Place/Increment/" + place + "/" + key + "/" + password  + "/" + changeAmount
	if (expiresIn != null):
		url += "/"+ str(expiresIn)
	
	var data = await call_url(url, HTTPClient.METHOD_PUT)
	return data.get_string_from_utf8()
	
func IncrementSecurePlayerValue(account, key, changeAmount, password, expiresIn = null):
	var url = "/SecureData/Player/Increment/" + account + "/" + key + "/" + password  + "/" + changeAmount
	if (expiresIn != null):
		url += "/"+ str(expiresIn)
	
	var data = await call_url(url, HTTPClient.METHOD_PUT)
	return data.get_string_from_utf8()

func IncrementSecureAreaValue(plusCode, key, changeAmount, password, expiresIn = null):
	var url = "/SecureData/Area/Increment/" + plusCode+ "/" + key + "/" + password + "/" + changeAmount
	if (expiresIn != null):
		url += "/"+ str(expiresIn)
	
	var data = await call_url(url, HTTPClient.METHOD_PUT)
	return data.get_string_from_utf8()

#MapTile endpoints API calls. Returns a PNG in byte array format.
func DrawMapTile(plusCode, styleSet, onlyLayer): #Normal map tiles. styleSet and onlyLayer are optional.
	var url = '/MapTile/Area/' + plusCode
	if (styleSet != null):
		url += "/" + styleSet
		if (onlyLayer != null):
			url += "/" + onlyLayer

	var data = await call_url(url)
	return data
	
func DrawMapTileAreaData(plusCode, styleSet): #loads drawable area data inside the given area.
	var url = '/MapTile/AreaData/' + plusCode
	if (styleSet != null):
		url += "/" + styleSet

	var data = await call_url(url)
	return data
	
func ExpireTiles(place, styleSet): #expires all map tiles in styleSet that contain place.
	var url = "/MapTile/Expire/" + place + "/" + styleSet
	await call_url(url)
	
func GetTileGenerationID(plusCode, styleSet): #Gets the current generation ID (creation count) for a tile. -1 is "expired"
	var url = "/MapTile/Generatiion/" + plusCode + "/" + styleSet
	await call_url(url)

#Demo endpoint API calls, so this can server immediately as a test client.

func DemoSplatterEnter(plusCode): #Grants the player 1 splat point when walking into a Cell10 the first time in 24 hours
	var url = "/Splatter/Enter/" + plusCode
	var data = await call_url(url)
	return data.get_string_from_utf8() #count of current splat points
	
func DemoSplatterSplat(plusCode, radius): #Spend points to make a splat of radius (integer) size if player has enough points.
	var url = "/Splatter/Splat/" + plusCode + "/" + radius
	await call_url(url)
	#When done, update 'splatter' maptiles.
	
func DemoSplatterTest(plusCode8): #Creates random splats all over the given Cell8. Return the image of the given Cell8 after.
	var url = "/Splatter/Test/" + plusCode8
	var data = await call_url(url)
	return data
	#When done, update 'splatter' maptiles.

func DemoUnroutineEnter(plusCode): #if at a Place, add it to the Visited list.
	var url = "/Unroutine/Enter/" + plusCode
	await call_url(url)
	
func DemoUnroutinePickTarget(plusCode):
	var url = "/Unroutine/Target/" + plusCode
	var data = await call_url(url, HTTPClient.METHOD_PUT)
	return data.get_string_from_utf8() #target info JSON

func DemoUnroutineGetCurrentTarget():
	var url = "/Unroutine/Target"
	var data = await call_url(url)
	return data.get_string_from_utf8() #target info JSON
	
func DemoUnroutineGetAllVisited():
	var url = "/Unroutine/Visited"
	var data = await call_url(url)
	return data.get_string_from_utf8() #all places JSON
