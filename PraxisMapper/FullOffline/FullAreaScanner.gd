extends RefCounted
class_name FullAreaScanner

#Like AreaScanner for minimized data, but with the full drawing data.
#will include roads, named buildings, and such.
var styleData

func PickPlace(area, category, terrainID = 0, requirement = ""):
	var possiblePlaces = await ScanForPlaces(area, category, terrainID, requirement)
	if possiblePlaces.size() == 0:
		print("No allowable places here for type " + str(terrainID) + "!")
		return null

	var chosenPlace = possiblePlaces[randi() % possiblePlaces.size()]
	return chosenPlace

func ReadPlaces(plusCode, category, terrainID, requirements, options = [], ignoreList = null, visitedPlaces = null):
	#category is style and entries
	styleData = PraxisCore.GetStyle(category)
	var possiblePlaces = []
	if options == null:
		options = {}
	if ignoreList == null:
		ignoreList = {}
	var areaData = await PraxisOfflineData.GetDataFromZip(plusCode)
	var ignoreArray = []
	if ignoreList.has(plusCode):
		ignoreArray = ignoreList[plusCode]
	if areaData == null:
		#print("No data on this area")
		return possiblePlaces
	
	for place in areaData.entries[category]:
		if !place.has("nid") or place.nid == 0: #ignore all unnamed places #TODO: backport == 0 check to mainline
			continue
				
		if terrainID != 0 and place.tid != terrainID:
			continue
		
		#These options are more complicated, and will be brough in here as just a list of values
		if options.size() > 0 and options.find(place.tid) == -1:
			continue
		
		var name = areaData.nameTable[str(place.nid)]
		if visitedPlaces != null and visitedPlaces.GetInfo(name, plusCode).size() > 0: #exclude visited places
			continue
		if ignoreArray.find(name) >= 0:
			continue
			
			
		#TODO: there's no 'inner' place detection on this right now. I assume that
		#the caluclations will be much more complex here, running every calculated center
		#against every polygon using PraxisOfflineData.IsPointInPlace().
			
		var reportedData = {}
		reportedData.name = name
		reportedData.type = styleData[str(place.tid)].name
		
		#Estimate center. For horseshoe-shaped places, this will often not actually be in-bounds.
		var centerVector = Vector2i(0,0)
		if place.p.size() == 1:
			centerVector = Vector2i(place.p[0])
		elif place.p[0] != place.p[place.p.size() - 1]:
			var i = place.p.size() / 2
			if place.p.size() == 2: #special case
				centerVector = Vector2i(place.p[0])
				centerVector += Vector2i(place.p[1])
				centerVector /= 2
			elif place.p.size() % 2 == 1: #odd
				centerVector = Vector2i(place.p[i]) 
			else: #Even
				centerVector = Vector2i(place.p[i])
				centerVector += Vector2i(place.p[i + 1])
				centerVector /= 2
		else:
			#shapes and closed geometry.
			var min = Vector2i(6400,10000)
			var max = Vector2i(0,0)
			for point in place.p:
				if point.x < min.x:
					min.x = point.x
				if point.y < min.y:
					min.y = point.y
				if point.x > max.x:
					max.x = point.x
				if point.y > max.y:
					max.y = point.y
			centerVector = (min + max) / 2
			
		var xCode8 = centerVector.x / 320
		var xCode10 = centerVector.x / 16 % 20
		var yCode8 = centerVector.y / 500
		var yCode10 = centerVector.y / 25 % 20
		
		#quick hack
		if xCode8 == 20:
			xCode8 = 19
		if yCode8 == 20:
			yCode8 = 19
		if xCode10 == 20:
			xCode10 = 19
		if yCode10 == 20:
			yCode10 = 19
		
		var centerCode = plusCode + PlusCodes.CODE_ALPHABET_[yCode8]+ PlusCodes.CODE_ALPHABET_[xCode8] + "+" + PlusCodes.CODE_ALPHABET_[yCode10]+ PlusCodes.CODE_ALPHABET_[xCode10]
		reportedData.area = centerCode
		possiblePlaces.push_back(reportedData)
	
	return possiblePlaces

func ScanForPlaces(plusCode, category, terrainID = 0, requirements = "", fixedDistance = 0):
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
		var placesHere = await ReadPlaces(plusCode, category, terrainID, requirements)
		possiblePlaces.append_array(placesHere)
		scannedAreas.append(plusCode)
	
	while maxDistance >= startDistance and keepGoing == true:
		for x in range(-startDistance, startDistance + 1):
			for y in range(-startDistance, startDistance + 1):
				var thisCode = PlusCodes.ShiftCode(plusCode, x, y)
				if scannedAreas.find(thisCode) > 0:
					continue
				
				var thesePlaces = await ReadPlaces(thisCode, category, terrainID, requirements)
				possiblePlaces.append_array(thesePlaces)
				scannedAreas.append(thisCode)
		if possiblePlaces.size() > 0:
			keepGoing = false
		startDistance += 1
		
	if possiblePlaces.size() > 0:
		return possiblePlaces

	#Nothing showed up? Still here? That's a problem.
	return []

func IsInside(outerPlace, innerPlace):
	#This should not be used here. Making 1 point and calling
	#PraxisOfflineData.IsPointInPlace() for all polygons until 1 is found would be optimal.
	return false
