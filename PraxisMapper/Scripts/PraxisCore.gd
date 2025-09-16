extends Node

#Any universally-helpful functions that aren't specific to an operating mode go here
#Server calls go to PraxisServer. Offline data loading goes to PraxisOfflineData.

#This variable should exist for debugging purposes, but I've provided a few choices for convenience.
var debugStartingPlusCode = "85633QG4VV" #Elysian Park, Los Angeles, CA, USA
#var debugStartingPlusCode = "87G8Q2JMGF" #Central Park, New York City, NY, USA
#var debugStartingPlusCode = "8FW4V75W25" #Eiffel Tower Garden, France
#var debugStartingPlusCode = "9C3XGV349C" #The Green Park, London, UK
#var debugStartingPlusCode = "8Q7XMQJ595" #Kokyo Kien National Garden, Tokyo, Japan
#var debugStartingPlusCode = "8Q336FJCRV" #Peoples Park, Shanghai, China
#var debugStartingPlusCode = "7JWVP5923M" #Shalimar Bagh, Delhi, India
#var debugStartingPlusCode = "86FRXXXPM8" #Ohio State University, Columbus, OH, USA

var prettyPrintSaveData = false
var errorLog = "user://errors.log"

#System global values
#Resolution of PlusCode cells in degrees
const resolutionCell12Lat = .000025 / 5
const resolutionCell12Lon = .00003125 / 4; 
const resolutionCell11Lat = .000025;
const resolutionCell11Lon = .00003125; 
const resolutionCell10 = .000125; 
const resolutionCell8 = .0025; 
const resolutionCell6 = .05; 
const resolutionCell4 = 1; 
const resolutionCell2 = 20;
const metersPerDegree = 111111
const oneMeterLat = 1 / metersPerDegree

const safetyTips = [
	"Pay more attention to your surroundings than your phone.",
	 "If a place isn't safe to go to, don't go there! You can re-roll destinations.",
]

#system config values. These are for Cell12 resolution images from detailed data.
var mapTileWidth = 320 
var mapTileHeight = 500

var autoPrecision = true #let the game decide on plusCode to use based on GPS results
var precision = 10 #use this value always for plusCode size if autoPrecision is false

#storage values for global access at any time.
var currentPlusCode = debugStartingPlusCode #The Cell10 we are currently in.
var lastPlusCode = '' #the previous Cell10 we visited.

#Local proxy-play values, if we want to pretend we're somewhere else.
var proxyPlay = false #set to true to use
var proxyCode = "85633QG4VV" #Set this to the in-game starting point we'll pretend to be at.
var proxyBase = Vector2(0,0) #Math values for proxy play logic
var playerStart = Vector2(0,0) #This is the player's first detected position when proxy-playing.

#signals for components that need to respond to it.
signal plusCode_changed(current, previous) #For when you just need to know your grid position changed
signal location_changed(dictionary) #For stuff that wants raw GPS data or small changes in position.
var last_location = {
	latitude = 1,
	longitude = 1,
	speed = 1
} # is the entire GPS data dictionary
var current_gps_packet = {}

#Plugin for gps info
var gps_provider

func SetProxyPlay(state):
	proxyPlay = state
	if proxyPlay == true:
		proxyBase = PlusCodes.Decode(proxyCode)
		if currentPlusCode != "":
			playerStart = PlusCodes.Decode(currentPlusCode)
		lastPlusCode = currentPlusCode
		currentPlusCode = proxyCode
		PraxisCore.plusCode_changed.emit(currentPlusCode, lastPlusCode)

func ForceChange(newCode):
	if newCode.find("+") == -1:
		newCode = newCode.substr(0,8) + "+" + newCode.substr(8)
	lastPlusCode = currentPlusCode
	currentPlusCode = newCode
	PraxisCore.plusCode_changed.emit(currentPlusCode, lastPlusCode)
	
func GetFixedRNGForPluscode(pluscode):
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(pluscode)
	return rng
	
func on_monitoring_location_result(location: Dictionary) -> void:
	if proxyPlay == true:
		var playerRealPoint = Vector2(location["longitude"], location["latitude"])
		if playerStart == Vector2(0,0):
			playerStart = playerRealPoint
		
		var diff = playerStart - playerRealPoint
		var inGamePoint = proxyBase - diff
		location["longitude"] = inGamePoint.x
		location["latitude"] = inGamePoint.y
	
	print("location change detected, firing off.")
	last_location = location
	location_changed.emit(location)
	print("location change signal fired.")
	var plusCode = ""
	var accuracy = float(location["accuracy"])
	if (autoPrecision and accuracy <= 6) or precision == 11:
		plusCode = PlusCodes.EncodeLatLonSize(location["latitude"], location["longitude"], 11)
	else:
		plusCode = PlusCodes.EncodeLatLonSize(location["latitude"], location["longitude"], 10)
	
	print("Detected plus code: " + plusCode)
	
	if (plusCode != currentPlusCode):
		lastPlusCode = currentPlusCode
		currentPlusCode = plusCode
		plusCode_changed.emit(currentPlusCode, lastPlusCode)
		print("new plusCode: " + plusCode)
		
func perm_check(permName, wasGranted):
	if permName == "android.permission.ACCESS_FINE_LOCATION" and wasGranted == true:
		print("enabling GPS")
		gps_provider.onLocationUpdates.connect(on_monitoring_location_result)
		gps_provider.StartListening()

func _ready():
	DirAccess.make_dir_absolute("user://MapTiles")
	DirAccess.make_dir_absolute("user://NameTiles")
	DirAccess.make_dir_absolute("user://BoundsTiles")
	DirAccess.make_dir_absolute("user://TerrainTiles")
	DirAccess.make_dir_absolute("user://Offline")
	DirAccess.make_dir_absolute("user://Backups")
	DirAccess.make_dir_absolute("user://Data") #used to store tracker data in JSON, rather than images.
	DirAccess.make_dir_absolute("user://Data/Min") 
	DirAccess.make_dir_absolute("user://Data/Full") 
	
	get_tree().on_request_permissions_result.connect(perm_check)
	
	#ensure we have an error log to write to
	if !FileAccess.file_exists(errorLog):
		var log = FileAccess.open(errorLog, FileAccess.WRITE)
		log.close()
	
	var platform = OS.get_name()
	print(platform)
	if platform == "Android":
		gps_provider = Engine.get_singleton("PraxisMapperGPSPlugin")
		if gps_provider != null:
			var perms = OS.get_granted_permissions()
			if perms.find("android.permission.ACCESS_FINE_LOCATION") > -1:
				print("enabling GPS")
				gps_provider.onLocationUpdates.connect(on_monitoring_location_result)
				gps_provider.StartListening()
	elif platform == "Web":
		#Engage new web app location update loop instead of android plugin.
		print("Starting web location provider")
		var evalString = "startListening();"
		var evalResults = JavaScriptBridge.eval(evalString)
		var webTimer = Timer.new()
		add_child(webTimer)
		webTimer.timeout.connect(WebLocationUpdate)
		webTimer.wait_time = 0.5
		webTimer.start()
	else:
		print("GPS Provider not loaded (probably debugging on PC)")
			
		currentPlusCode = debugStartingPlusCode
		var debugControlScene = preload("res://PraxisMapper/Controls/DebugMovement.tscn")
		var debugControls = debugControlScene.instantiate()
		add_child(debugControls)
		debugControls.position.x = 0
		debugControls.position.y = 0
		debugControls.z_index = 200

func WebLocationUpdate():
	var evalString = "currentPos();"
	var evalResults = JavaScriptBridge.eval(evalString)
	print("Web location results:" + evalResults)
	if evalResults != "<null>":
		var loc = JSON.parse_string(evalResults)
		on_monitoring_location_result(loc.coords)
	
func GetStyle(style):
	var styleData = FileAccess.open("res://PraxisMapper/Styles/" + style + ".json", FileAccess.READ)
	if (styleData == null):
		return null
	else:
		var json = JSON.new()
		json.parse(styleData.get_as_text())
		return json.get_data()

#This needs to be called by a node that exists in a tree, not just a static script, so its here.
func MakeMinimizedOfflineTiles(plusCode):
	var offlineNode = preload("res://PraxisMapper/MinimizedOffline/MinOfflineTiles.tscn")
	var offlineInst = offlineNode.instantiate()
	add_child(offlineInst)
	await offlineInst.GetAndProcessData(plusCode)
	remove_child.call_deferred(offlineInst)
	
func MakeOfflineTiles(plusCode, scale = 1):
	var offlineNode = preload("res://PraxisMapper/FullOffline/FullOfflineTiles.tscn")
	var offlineInst = offlineNode.instantiate()
	add_child(offlineInst)
	await offlineInst.GetAndProcessData(plusCode, scale)
	remove_child(offlineInst)

func GetCell8Tile(plusCode8):
	if FileAccess.file_exists("user://MapTiles/" + plusCode8 + ".png"):
		return ImageTexture.create_from_image(Image.load_from_file("user://MapTiles/" + plusCode8 + ".png"))
	
	var results = await MakeOneOfflineTiles(plusCode8)
	return results

func MakeOneOfflineTiles(plusCode, scale = 1):
	var offlineNode = preload("res://PraxisMapper/FullOffline/FullSingleTile.tscn")
	var offlineInst = offlineNode.instantiate()
	add_child(offlineInst)
	var texture = await offlineInst.GetAndProcessData(plusCode, scale)
	remove_child(offlineInst)
	return texture 
	
func DistanceDegreesToMetersLat(degrees):
	return degrees * metersPerDegree

func DistanceDegreesToMetersLon(degrees, latDegrees):
	return degrees * metersPerDegree * cos(deg_to_rad(latDegrees))

func DistanceMetersToDegreesLat(meters):
	return meters * oneMeterLat

func DistanceMetersToDegreesLon(meters, latDegrees):
	return meters * oneMeterLat * cos(deg_to_rad(latDegrees))

func MetersToFeet(meters):
	return meters * 3.281

func GetCompassHeading():
	var gravity: Vector3 = Input.get_gravity()
	var pitch = atan2(gravity.z, -gravity.y) #rotation.x
	var roll = atan2(-gravity.x, -gravity.y)  #rotation.z
	var magnet = Input.get_magnetometer().rotated(-Vector3.FORWARD, roll).rotated(Vector3.RIGHT, pitch)
	
	var yaw_magnet = atan2(-magnet.x, magnet.z)
	return -yaw_magnet #Negative to match rotation values in Godot

#Convenience function
func LoadData(fileName):
	var recentFile = FileAccess.open(fileName, FileAccess.READ)
	if (recentFile == null):
		var errorCode = FileAccess.get_open_error()
		WriteErrorLog("Error reading data from " + fileName + ": " + str(errorCode) + " | " + str(Time.get_unix_time_from_system()))
		return
	else:
		var json = JSON.new()
		var dataLoading = recentFile.get_as_text()
		var errorParse = json.parse(dataLoading)
		if errorParse != OK:
			var errorLine = json.get_error_line()
			var errorMessage = json.get_error_message()
			WriteErrorLog("First Chars: " + dataLoading.substr(0,50))
			WriteErrorLog("Error parsing data from " + fileName + ": " + str(errorParse) + " | Line " + str(errorLine) + ": " + errorMessage + " | " + str(Time.get_unix_time_from_system()))
		var info = json.get_data()
		if info is Dictionary:
			if info.size() == 0:
				WriteErrorLog("Got empty dictionary from " + fileName + " | " + str(Time.get_unix_time_from_system()))
		recentFile.close()
		return info

var lastErrorData = ""
#Convenience function
func SaveData(fileName, dictionary):
	var recentFile = FileAccess.open(fileName, FileAccess.WRITE)
	if (recentFile == null):
		var errorCode = FileAccess.get_open_error()
		print(errorCode)
		WriteErrorLog("Error saving data to " + fileName + ": " + str(errorCode) + " | " + str(Time.get_unix_time_from_system()))
		lastErrorData = "Opening Save File"
		return false
	
	var json = JSON.new()
	var stringified = json.stringify(dictionary, '\t' if prettyPrintSaveData == true else '')
	if stringified == null or stringified.length() < 5: #Should be empty on failure, allowing room for an empty dict "{}".
		WriteErrorLog("Error changing data to JSON for " + fileName + " | " + str(Time.get_unix_time_from_system()))
		lastErrorData = "Stringify to JSON"
		return false
		#TODO: how to save this out? I can't stringify this dictionary.
		#var devDumpFilePath = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
		#if !devDumpFilePath.ends_with("/"):
			#devDumpFilePath += "/"
		#devDumpFilePath += "lastFailedStringify.txt"
		#var devDumpFile = FileAccess.open(devDumpFilePath, FileAccess.WRITE)
		
		
	var stored = recentFile.store_string(stringified)
	if stored == false:
		var storeError = recentFile.get_error()
		print(storeError)
		WriteErrorLog("Error storing data to " + fileName + ": " + str(storeError) + " | " + str(Time.get_unix_time_from_system()))
		lastErrorData = "Saving data"
		recentFile.close()
		return false
	recentFile.close()
	return true

func PlusCodeToScreenCoords(plusCodeCoords, plusCodeScreenBase):
	pass
	#There really should be a way to just calculate out what coordinates I need all the time centrally
	#If my tiles are always the same size, I can do that here.
	#take the first8 of PlusCodeScreenBase, and then work down the character pair differences
	#until I have a solid running total.

#TODO: backport to core components?
var errorMutex = Mutex.new()
func ReadErrorLog():
	errorMutex.lock()
	var file = FileAccess.open(errorLog, FileAccess.READ_WRITE)
	var data = file.get_as_text()
	file.close()
	errorMutex.unlock()
	return data

func WriteErrorLog(errorData):
	errorMutex.lock()
	var file = FileAccess.open(errorLog, FileAccess.READ_WRITE)
	file.seek_end()
	file.store_line(errorData)
	file.close()
	errorMutex.unlock()
