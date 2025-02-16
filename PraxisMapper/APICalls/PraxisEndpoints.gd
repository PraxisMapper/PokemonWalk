extends Node2D
class_name PraxisEndpoints

@onready var request: HTTPRequest = $HTTPRequest
#this version uses signals insted of waiting for a response in a single call.
#this will let other things process more reliably and is the better design pattern to follow.

signal response_data(body)

func response_received(result, responseCode, headers, body):
	print('response received:' + str(responseCode) + "| " + str(result))

	request.request_completed.disconnect(response_received)
	if responseCode >= 200 and responseCode < 299:
		response_data.emit(body)
	elif responseCode == PraxisServer.reauthCode:
		PraxisServer.Reauth()
		response_data.emit("ERROR")
	else:
		response_data.emit("ERROR")

func callEndpoint(url, method = null, body = null):
	var headers = [
		"AuthKey: " + PraxisServer.authKey,
		"PraxisAuthKey: " + PraxisServer.headerKey,
		"User-Agent: Pirulo/1.0 (Godot)",
		"Accept: */*"
	]
	if (method == null):
		method = HTTPClient.METHOD_GET
	elif (method == HTTPClient.METHOD_PUT):
		if body != null:
			headers.append("Content-Length: " + body.size())
		else:
			headers.append("Content-Length: 0")
	request.request_completed.connect(response_received)
	var ok
	if (body != null): 
		ok = request.request(PraxisServer.serverURL + url, headers, method, body)
	else:
		ok = request.request(PraxisServer.serverURL + url, headers, method)
	print(PraxisServer.serverURL + url)
	print('request called')
	
	#TODO: check if OK isn't OK and handle pre-call errors.
	
	#this probably doesn't work. ACTUALLY - it might, possibly needs to be self.response_received
	#var results = await response_received
	#print('results awaited successfully')
	#return results

func Login(server, username, password):
	callEndpoint(server + "/Server/Login/" + username + "/" + password)
	
func GetServerBounds(): # Server's covered area in S|W|N|E order/format
	callEndpoint("/Server/Bounds")
	
func ServerTest(): # always returns 'OK'
	callEndpoint("/Server/Test")

func MOTD(): #Message of the Day
	callEndpoint("/Server/MOTD")
	
func RandomPoint(): # A random point somewhere inside server bounds
	callEndpoint("/Server/RandomPoint")
	
func GDPRExport(): #All data available on the user as a string.
	callEndpoint("/Server/GdprExport")	

func DeleteAccount():
	callEndpoint("/Server/Account", HTTPClient.METHOD_DELETE)
	
func CreateAccount(account,password):
	callEndpoint("/Server/CreateAccount/" + account + "/" + password, HTTPClient.METHOD_PUT)

func ChangePassword(account, oldPassword, newPassword):
	callEndpoint("/Server/ChangePassword/" + account + "/" + oldPassword + "/" + newPassword, HTTPClient.METHOD_PUT)

#Data endpoint API calls. For games that don't have a dedicated plugin or early development testing.
#Sets return true/false, Gets usually return JSON data.
func SetAreaValue(plusCode, key, value, expiresIn = null):
	var url = "/Data/Area/" + plusCode + "/" + key
	if (expiresIn != null):
		url += "/noval/" + str(expiresIn)
	callEndpoint(url, HTTPClient.METHOD_PUT, value)
	
func GetAreaValue(plusCode, key):
	callEndpoint("/Data/Area/" + plusCode + "/" + key)
	
#TODO: Server doesn't currently allow for body values with expiration on Player.
func SetPlayerValue(account, key, value, expiresIn = null):
	var url = "/Data/Player/" + account + "/" + key
	if (expiresIn != null):
		url += "/" + value + "/" + str(expiresIn)
	callEndpoint(url, HTTPClient.METHOD_PUT, value)
	
func GetPlayerValue(account, key):
	callEndpoint("/Data/Player/" + account + "/" + key)

#TODO: Server doesn't currently allow for body values with expiration on Place
func SetPlaceValue(place, key, value, expiresIn = null):
	var url = "/Data/Place/" + place + "/" + key
	if (expiresIn != null):
		url += "/" + value + "/" + str(expiresIn)
	callEndpoint(url, HTTPClient.METHOD_PUT, value)

func GetPlaceValue(place, key):
	callEndpoint("/Data/Place/" + place + "/" + key)
	
func GetGlobalValue(key):
	callEndpoint("/Data/Global/" + key)

func SetGlobalValue(key, value):
	callEndpoint("/Data/Global/" + key, HTTPClient.METHOD_PUT, value)
	
func DeleteGlobalValue(key):
	callEndpoint("/Data/Global/" + key, HTTPClient.METHOD_DELETE)
	
func GetAllPlayerData(player):
	callEndpoint("/Data/Player/All/" + player)

func GetAllAreaData(player):
	callEndpoint("/Data/Area/All/" + player)

func GetAllPlaceData(place):
	callEndpoint("/Data/Place/All/" + place)

#SecureData endpoint API calls. 
func SetSecureAreaValue(plusCode, key, value, password, expiresIn = null):
	#TODO: server doesnt support value in body and expiration together.
	var url = "/SecureData/Area/" + plusCode + "/" + key
	if (expiresIn != null):
		url += "/" + value + "/" + password + "/"+ str(expiresIn)
	else:
		url += "/" + password
	callEndpoint(url, HTTPClient.METHOD_PUT, value)
	
func GetSecureAreaValue(plusCode, key, password):
	callEndpoint("/SecureData/Area/" + plusCode + "/" + key + "/" + password)
	
#TODO: Server doesn't currently allow for body values with expiration on Player.
func SetSecurePlayerValue(account, key, value, password, expiresIn = null):
	var url = "/SecureData/Player/" + account + "/" + key
	if (expiresIn != null):
		url += "/" + value + "/" + password + "/"+ str(expiresIn)
	else:
		url += "/" + password
	callEndpoint(url, HTTPClient.METHOD_PUT, value)
	
func GetSecurePlayerValue(account, key, password):
	callEndpoint("/SecureData/Player/" + account + "/" + key + "/" + password)

#TODO: Server doesn't currently allow for body values with expiration on Place
func SetSecurePlaceValue(place, key, value, password, expiresIn = null):
	var url = "/SecureData/Place/" + place + "/" + key
	if (expiresIn != null):
		url += "/" + value + "/" + password + "/"+ str(expiresIn)
	else:
		url += "/" + password
	callEndpoint(url, HTTPClient.METHOD_PUT, value)

func GetSecurePlaceValue(place, key, password):
	callEndpoint("/SecureData/Place/" + place + "/" + key)
	
#These don't return a value.
func IncrementSecurePlaceValue(place, key, changeAmount, password, expiresIn = null):
	var url = "/SecureData/Place/Increment/" + place + "/" + key + "/" + password  + "/" + changeAmount
	if (expiresIn != null):
		url += "/"+ str(expiresIn)
	callEndpoint(url, HTTPClient.METHOD_PUT)
	
func IncrementSecurePlayerValue(account, key, changeAmount, password, expiresIn = null):
	var url = "/SecureData/Player/Increment/" + account + "/" + key + "/" + password  + "/" + changeAmount
	if (expiresIn != null):
		url += "/"+ str(expiresIn)
	callEndpoint(url, HTTPClient.METHOD_PUT)

func IncrementSecureAreaValue(plusCode, key, changeAmount, password, expiresIn = null):
	var url = "/SecureData/Area/Increment/" + plusCode+ "/" + key + "/" + password + "/" + changeAmount
	if (expiresIn != null):
		url += "/"+ str(expiresIn)
	callEndpoint(url, HTTPClient.METHOD_PUT)

#MapTile endpoints API calls. Returns a PNG in byte array format.
func DrawMapTile(plusCode, styleSet, onlyLayer = null): #Normal map tiles. styleSet and onlyLayer are optional.
	var url = '/MapTile/Area/' + plusCode
	if (styleSet != null):
		url += "/" + styleSet
		if (onlyLayer != null):
			url += "/" + onlyLayer
	callEndpoint(url)
	
func DrawMapTileAreaData(plusCode, styleSet): #loads drawable area data inside the given area.
	var url = '/MapTile/AreaData/' + plusCode
	if (styleSet != null):
		url += "/" + styleSet
	callEndpoint(url)
	
func ExpireTiles(place, styleSet): #expires all map tiles in styleSet that contain place.
	callEndpoint("/MapTile/Expire/" + place + "/" + styleSet)
	
func GetTileGenerationID(plusCode, styleSet): #Gets the current generation ID (creation count) for a tile. -1 is "expired"
	callEndpoint("/MapTile/Generatiion/" + plusCode + "/" + styleSet)

#Demo endpoint API calls, so this can server immediately as a test client.
func DemoSplatterEnter(plusCode): #Grants the player 1 splat point when walking into a Cell10 the first time in 24 hours
	callEndpoint("/Splatter/Enter/" + plusCode)
	
func DemoSplatterSplat(plusCode, radius): #Spend points to make a splat of radius (integer) size if player has enough points.
	callEndpoint("/Splatter/Splat/" + plusCode + "/" + radius)
	
func DemoSplatterTest(plusCode8): #Creates random splats all over the given Cell8. Return the image of the given Cell8 after.
	callEndpoint("/Splatter/Test/" + plusCode8)

func DemoUnroutineEnter(plusCode): #if at a Place, add it to the Visited list.
	callEndpoint("/Unroutine/Enter/" + plusCode)
	
func DemoUnroutinePickTarget(plusCode):
	var url = "/Unroutine/Target/" + plusCode
	callEndpoint(url, HTTPClient.METHOD_PUT)

func DemoUnroutineGetCurrentTarget():
	callEndpoint("/Unroutine/Target")
	
func DemoUnroutineGetAllVisited():
	callEndpoint("/Unroutine/Visited")
