extends Node2D
class_name PlaceTracker

#keys are [plusCode6][placeName], value is dictionary (type, time visited)
#EX: [223344][Main Park] = {type = 50, timeFirstVisisted = 12345.679}
var allPlaces = {} 
var category = "mapTiles" #Use a separate PlaceTracker for adminBoundaries
#NOTE: if you want a custom filename for multiple placetrackers, set this value after calling _ready()
var fileName = "user://Data/PlaceTracker" + category + ".json"
var styleData = {}
var styleDataFull = {}
var checkedPlusCode = ""
var currentData # Whats the difference between currentData and currentPlaces? is Data the source info?
#These store the image used, so we don't have to load all of these from disk every call. 
#TODO: try to remove these 2 tiles and just use the raw data.
var currentNameTile
var currentTerrainTile
var currentPlaces = [] #This should stay, is the most useful data for this.
var autoRun = true

signal place_changed(newplace)

func _ready():
	styleData = PraxisCore.GetStyle("suggestedmini") 
	styleDataFull = PraxisCore.GetStyle(category) 
	fileName = "user://Data/PlaceTracker" + category + ".json"
	Load()
	if (autoRun == true):
		PraxisCore.plusCode_changed.connect(AutoCheck)

func Load():
	allPlaces = PraxisCore.LoadData(fileName)
	if (allPlaces == null):
		allPlaces = {}

func Save():
	PraxisCore.SaveData(fileName, allPlaces)
	
func Clear():
	allPlaces = {}
	
func AutoCheck(current, old):
	var prevPlaces = currentPlaces
	await CheckForPlace(current)

	if (prevPlaces != currentPlaces):
		var dirty = false
		place_changed.emit(currentPlaces)

		for r in currentPlaces: #Results returns 1 entry, we want them all
			#TODO: there's still something wrong here in some case, probably when there's
			#no map data. I think its the difference between [] and [""]? This might fix it.
			if (r == ""):
				continue
			var parts = r.split("|")
			if HasVisited(parts[0], current.substr(0,6)) == false:
				Add(parts[0], parts[1], current.substr(0,6))
				dirty = true
		if dirty:
			Save()

func Add(place, type, plusCode6):
	if (allPlaces.has(plusCode6) == false):
		allPlaces[plusCode6] = {}
	if (allPlaces[plusCode6].has(place) == false):
		allPlaces[plusCode6][place] = { type = type,  timeFirstVisited = Time.get_unix_time_from_system()}

func isFirstVisit(place, plusCode6):
	if (allPlaces.has(plusCode6) and allPlaces[plusCode6].has(place)):
		return false
	return true;

func GetInfo(place, plusCode6):
	if !allPlaces.has(plusCode6):
		return {}
	if !allPlaces[plusCode6].has(place):
		return {}
	
	return allPlaces[plusCode6][place]

func SetInfo(place, plusCode6, data_dict):
	allPlaces[plusCode6][place] = data_dict
	Save()
	
func HasVisited(name, plusCode6):
	if allPlaces.has(plusCode6) == false or allPlaces[plusCode6].has(name) == false:
		return false
	return true

func CheckForPlace(plusCode10):
	#TOOD: sort out returns. Sometimes its Array, sometimes its PackedStringArray
	plusCode10 = plusCode10.replace("+", "")
	#if we have full data, use it instead.
	if PraxisOfflineData.OfflineDataExists(plusCode10.substr(0,6)):
		return await CheckForPlaceFull(plusCode10)
	
	#This is the Minimized Offline format check:
	#400x400, each pixel is a Cell10.	
	var filename = PraxisCore.currentPlusCode.substr(0,6)
	if (filename != checkedPlusCode.substr(0,6)):
		#load new data. These are drawn by GameGlobals if they're available to draw
		#TODO: I should be able to get away from using image tiles now, just check the source data.
		#TODO: do i already have this code in a class somewhere? MinimizedOffline/AreaScanner?
		currentData = MinimizedOffline.GetDataFromZip(filename)
		currentNameTile = Image.load_from_file("user://NameTiles/" + filename + ".png")
		currentTerrainTile = Image.load_from_file("user://TerrainTiles/" + filename + ".png")
		checkedPlusCode = filename
	
	var currentPlace = GetDataOnPoint(plusCode10)
	currentPlaces = [currentPlace]
	var placeInfo = []
	if (currentPlace == ""):
		return [""]
		
	if (currentPlace != "|"):
		placeInfo = currentPlace.split("|")
		if (placeInfo[0] == ""):
			placeInfo[0] = "unnamed " + placeInfo[1]
	return placeInfo

func GetDataOnPoint(plusCode10):
	var filename = plusCode10.substr(0,6)
	var pixelX = (PlusCodes.GetLetterIndex(plusCode10[7]) * 20)  + PlusCodes.GetLetterIndex(plusCode10[9])
	var pixelY = 399 - (PlusCodes.GetLetterIndex(plusCode10[6]) * 20) - PlusCodes.GetLetterIndex(plusCode10[8])

	var name = ""
	var terrain = ""

	var pixel = currentNameTile.get_pixel(pixelX, pixelY)
	var nameTableId = pixel.r8 + (pixel.g8 * 255) + (pixel.b8 * 65535)
	if nameTableId > 0:
		name = currentData.nameTable[str(nameTableId)]
	pixel = currentTerrainTile.get_pixel(pixelX, pixelY)
	var terrainTableId = pixel.r8 + (pixel.g8 * 255) + (pixel.b8 * 65535)
	if terrainTableId > 0:
		terrain = styleData[str(terrainTableId)].name
	
	if (name == "" and terrainTableId == 0):
		return "" # may need to be "|"?
	
	return name + "|" + terrain
	
func GetDataOnPointNoImage(plusCode10):
	pass
	#TODO: a rewritten version of the above function, that just uses the offline data
	#instead of parsing an image pixel by pixel.
	#Data should already be loaded, so pull it from AllData, then check all
	#entries based on distance from center
	
	
func CheckForPlaceFull(plusCode10):
	#this is for using the full drawable data to detect which place you're at
	
	plusCode10 = plusCode10.replace("+", "")
	var data = await GetDataOnPointFull(plusCode10)
	currentPlaces = data
	if data.size() == 0:
		return [""]
		
	var smallest = data.back()
	return smallest.split("|") #if split, doesnt updateCurrentPlace?

func GetDataOnPointFull(plusCode10):
	var results = []
	var places = await PraxisOfflineData.GetPlacesPresent(plusCode10)
	for place in places:
		if place.category == category:
			results.push_back(place.name + "|" + str(place.typeId))
	
	return results

func TotalPlaces():
	var total = 0
	if allPlaces == null:
		return total
	for k in allPlaces.keys():
		total += allPlaces[k].size()
	return total

func TotalPlacesOfType(typeId):
	var total = 0
	for k in allPlaces.keys():
		for k2 in allPlaces[k]:
			if allPlaces[k][k2].type == typeId:
				total += 1
	return total
