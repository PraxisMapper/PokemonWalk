extends RefCounted
class_name AreaScanner

#TODO: set styleData from outside or load a default choice Remember this only works on
#minimized suggestedMini data, so probably force-load that.
var styleData #loaded from outside

func PickPlace(area, terrainID = 0, requirement = ""):
	#Find a place in placeData that isn't visited and is allowed by options
	#and is not ignored.
	
	var possiblePlaces = ScanForPlaces(area, terrainID, requirement)
	if possiblePlaces.size() == 0:
		print("No allowable places here!")
		return null

	var chosenPlace = possiblePlaces[randi() % possiblePlaces.size()]
	return chosenPlace

func ReadPlaces(plusCode, terrainID, requirements, options = null, ignoreList = null, visitedPlaces = null):
	#The core function for finding places. Scans an area for places that match
	#the terrainID and requirements values, and returns the list of matches.
	var possiblePlaces = []
	if options == null:
		options = {}
	if ignoreList == null:
		ignoreList = {}
	var areaData = MinimizedOffline.GetDataFromZip(plusCode)
	var ignoreArray = []
	if ignoreList.has(plusCode):
		ignoreArray = ignoreList[plusCode]
	if areaData == null:
		#print("No data on this area")
		return possiblePlaces
	
	for place in areaData.entries["suggestedmini"]:
		if !place.has("nid"): #not picking unnamed places as destinations
			continue

		var name = areaData.nameTable[str(place.nid)]
		if visitedPlaces != null and visitedPlaces.GetInfo(name, plusCode).size() > 0: #exclude visited places
			continue
		if ignoreArray.find(name) >= 0:
			continue
		place.name = name
		
		#Options filters applied now #TODO: bring in line with FullAreaScanner?
		if (options.size() > 0):
			if place.tid == 1 and options.suggestParks == false:
				continue
			elif place.tid == 2 and options.suggestUniversities == false:
				continue
			elif place.tid == 3 and options.suggestNatureReserves == false:
				continue
			elif place.tid == 4 and options.suggestCemeteries == false:
				continue
			elif place.tid == 5 and options.suggestHistorical == false:
				continue
			elif place.tid >= 6 and options.suggestArtsCulture == false: # >= because this will become 18 tids
				continue
			elif terrainID != 0 and place.tid != terrainID:
				continue
		else: #No options passed in, only use terrainID
			if terrainID != 0 and place.tid != terrainID:
				continue
			
		#Set parent info for use later
		for maybeParent in areaData.entries["suggestedmini"]:
			if maybeParent.r < place.r:
				continue
			if IsInside(maybeParent, place):
				if maybeParent.has("nid"):
					place.parentName = areaData.nameTable[str(maybeParent.nid)]
				else:
					place.parentName = "an unnamed " + str(maybeParent.tid) # + GameGlobals.styleData[str(maybeParent.tid)].name
				continue
		
		var center = place.c.split(",")
		var xCode8 = int(center[0]) / 20 #ERROR: got a place with coord 400, should be 0-399.
		#Temp fix
		if (xCode8 == 20):
			xCode8 -= 1
		var yCode8 = int(center[1]) / 20
		if (yCode8 == 20):
			yCode8 -= 1
		var xCode10 = int(center[0]) % 20
		var yCode10 = int(center[1]) % 20
		place.area = plusCode +  PlusCodes.CODE_ALPHABET_[yCode8]+ PlusCodes.CODE_ALPHABET_[xCode8] + "+" + PlusCodes.CODE_ALPHABET_[yCode10]+ PlusCodes.CODE_ALPHABET_[xCode10]
		#make this slightly easier to refer to later.
		place.radius = place.r
		
		#if we only want sub-places, apply that check now
		if (!requirements.contains("sub") or place.has("parentName")):
			possiblePlaces.push_back(place)
	return possiblePlaces
	
func ScanForPlaces(plusCode, terrainID = 0, requirements = "", fixedDistance = 0):
	#The function that handles where to call ReadPlaces for.
	#Default is to scan a distance of 0 and 1. Scans all sectors at the same distance 
	#before returning a combined list of places. 
	#PickPlaces does the actual selection of a single one of the possible places.
	
	var possiblePlaces = []
	var scannedAreas = []
	var startDistance = 1
	var maxDistance = 10 #if you can't find a valid place within the surrounding Cell4, you can't go to one.
	var keepGoing = true
	
	if requirements.contains("far"): #Skip everything too close to the player
		startDistance = 3
		for x in [-2, -1, 0, -1, 2]:
			for y in [-2, -1, 0 -1, 2]:
				scannedAreas.append(PlusCodes.ShiftCode(plusCode, x, y))
	elif fixedDistance != 0: #Only scan stuff at the given range, not inner areas.
		startDistance = fixedDistance
		maxDistance = fixedDistance
		for x in range(-(fixedDistance -1), fixedDistance):
			for y in range(-(fixedDistance -1), fixedDistance):
				scannedAreas.append(PlusCodes.ShiftCode(plusCode, x, y))
	else: #Scan the current area (Distance 0) before looping on Distance 1+
		var placesHere = ReadPlaces(plusCode, terrainID, requirements)
		possiblePlaces.append_array(placesHere)
		scannedAreas.append(plusCode)

	while maxDistance >= startDistance and keepGoing == true:
		for x in range(-startDistance, startDistance + 1):
			for y in range(-startDistance, startDistance + 1):
				var thisCode = PlusCodes.ShiftCode(plusCode, x, y)
				if scannedAreas.find(thisCode) > 0:
					continue
				
				var thesePlaces = ReadPlaces(thisCode, terrainID, requirements)
				possiblePlaces.append_array(thesePlaces)
				scannedAreas.append(thisCode)
		if possiblePlaces.size() > 0:
			keepGoing = false
		startDistance += 1
		
	if possiblePlaces.size() > 0:
		return possiblePlaces

	#Nothing showed up? Still here? That's a problem.
	return null

func IsInside(outerPlace, innerPlace):
	if outerPlace.r <=2: #This is the minimum size, don't treat this as being able to have inner places
		return false
	
	if outerPlace.c == innerPlace.c: #this is the the same place.
		return false
	
	#Places with the same name are the same place, not parent/child.
	if (outerPlace.has("nid") and innerPlace.has("nid") and outerPlace.nid == innerPlace.nid):
		return false
	
	var outerCoords = outerPlace.c.split(",")
	var innerCoords = innerPlace.c.split(",")
	var a = Vector2(int(outerCoords[0]), int(outerCoords[1]))
	var b = Vector2(int(innerCoords[0]), int(innerCoords[1]))
	var distance = a.distance_to(b)
	
	return distance <= outerPlace.r
