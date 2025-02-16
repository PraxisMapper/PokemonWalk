extends Node
class_name PraxisOfflineData

#Once we read a file from disk, keep it in memory. Odds are high the player will read it again.
static var allData = {}

#TODO: call this function instead of checking individually in every spot.
static func OfflineDataExists(plusCode):
	if FileAccess.file_exists("res://OfflineData/Full/" + plusCode.substr(0,2) + "/" + plusCode.substr(0,4) + ".zip"):
		return true
	if FileAccess.file_exists("user://Data/Full/" + plusCode.substr(0,4)+ ".zip"):
		return true
	if FileAccess.file_exists("user://Data/Full/" + plusCode.substr(0,6)+ ".json"):
		return true
	return false
	
#TODO: make this just GetData
static func GetDataFromZip(plusCode): #full, drawable offline data.
	if allData.has(plusCode):
		return allData[plusCode]
	
	#This needs to live nicely with the MinOffline version, and if the game is limited in
	#scope it could use the same source folder. The odds of the game using both built-in are 0.
	#though its possible it could include the minimum format as a fallback and download the full data.
	var code2 = plusCode.substr(0, 2)
	var code4 = plusCode.substr(2, 2)
	var zipReader = ZIPReader.new()
	
	#CHECK: if we have a single downloaded JSON file, use it.
	if FileAccess.file_exists("user://Data/Full/" + plusCode.substr(0,6) + ".json"):
		var soloFile = FileAccess.open("user://Data/Full/" + plusCode.substr(0,6) + ".json", FileAccess.READ)
		var json = JSON.new()
		json.parse(soloFile.get_as_text())
		
		var jsonData = json.data
		if jsonData == null: #no good data here? this area is missing or empty?
			return null
		return ProcessData(jsonData)

	#Now check if we have the zip file that should hold this data, built in or downloaded
	var err
	if FileAccess.file_exists("res://OfflineData/Full/" + code2 + "/" + code2 + code4 + ".zip"):
		err = await zipReader.open("res://OfflineData/Full/" + plusCode.substr(0,2) + "/" + plusCode.substr(0,4) + ".zip")
	elif FileAccess.file_exists("user://Data/Full/" + code2 + code4 + ".zip"):
		err = await zipReader.open("user://Data/Full/" + code2 + code4 + ".zip")

	if err != OK:
		print("No FullOffline data found (or zip corrupt/incomplete) for " + plusCode + ": " + str(err))
		return 
		
	var rawdata := await zipReader.read_file(plusCode + ".json")
	var realData = await rawdata.get_string_from_utf8()
	var json = JSON.new()
	await json.parse(realData)
	var jsonData = json.data
	if jsonData == null: #no file in this zip, this area is missing or empty.
		return 
	
	return ProcessData(jsonData)
	
static func ProcessData(jsonData):
	if jsonData == null: #may happen if data is partially loaded.
		return
		
	#This is envelope detection, so yes I want a big min and tiny max to start
	#because they'll get flipped to the right values on the first point.
	var minVector = Vector2i(20000,20000)
	var maxVector = Vector2i(0,0)
	for category in jsonData.entries:
		for entry in jsonData.entries[category]:
			minVector = Vector2i(20000,20000)
			maxVector = Vector2i(0,0)
			#entry.p is a string of coords separated by a pipe in the text file.
			#EX: 0,0|20,0|20,20|20,0|0,0 is a basic square.
			var coords = entry.p.split("|", false)
			var polyCoords = PackedVector2Array()
			for i in coords.size():
				var point = coords[i].split(",")
				var workVector = Vector2i(int(point[0]), int(point[1]))
				polyCoords.append(workVector)
				
				if workVector.x > maxVector.x:
					maxVector.x = workVector.x
				if workVector.y > maxVector.y:
					maxVector.y = workVector.y
				if workVector.x < minVector.x:
					minVector.x = workVector.x
				if workVector.y < minVector.y:
					minVector.y = workVector.y
				
			entry.p = polyCoords
			entry.envelope = Rect2(minVector, (maxVector - minVector))
	
	allData[jsonData.olc] = jsonData
	return jsonData
	
static func GetPlacesPresent(plusCode):
	var data = await GetDataFromZip(plusCode.substr(0,6))
	if data == null:
		return
	var point = PlusCodeToDataCoords(plusCode)
	#print("PlusCode " + plusCode + " translated to coords " + str(point))
	var results = []
	var size = plusCode.length()
	
	for category in data.entries:
		for entry in data.entries[category]:
			if entry.has("nid") and entry.nid != 0:
				if IsPointInPlace(point, entry, size, data.nameTable[str(int(entry.nid))]):
					results.push_back({ 
						name  = data.nameTable[str(int(entry.nid))],
						category = category,
						typeId = entry.tid
					})
	return results

static func IsPlusCodeInPlace(plusCode, place):
	var point = PlusCodeToDataCoords(plusCode)
	return IsPointInPlace(point, place, plusCode.size())
	
static func IsPointInPlace(point, place, size, name = "unnamed"):
	#NOTE: Rect2 has an origin in the top-left, so I generally want to make sure 
	#that I follow suit with the detected area. Y increases down, so I may need
	#to make sure that I adjust stuff properly. In particular, Cell11 sized points
	#should be the center of a Cell10 detection area, and Cell10s default to the
	#BOTTOM left corner and may need adjusted vertically? OR am I confusing
	#Godot map coords and my own data logic?
	
	#This is right, since the data source has bigger Y going DOWN.
	#Also, now centering this on the current point for Cell11 compatibility
	#instad of making the cell10 in question. May need to re-test this or analyse
	#it with Cell10 (since those are SW corners before, and now the center here)
	var cell10 = PackedVector2Array()
	cell10.append(Vector2(point + Vector2(-8, -12)))
	cell10.append(Vector2(point + Vector2(-8, 12)))
	cell10.append(Vector2(point + Vector2(8, 12)))
	cell10.append(Vector2(point + Vector2(8, -12)))
	cell10.append(Vector2(point+ Vector2(-8, -12)))

	if place.gt == 1:
		#JUST DO DISTANCE FOR POINTS
		return abs(point.distance_to(place.p[0])) <= 10.25 #Avg. of half a cell10 radius.
		#NOT ALL OF THIS.
		#We have a point. Expand that and check if these overlap.
		#NOTE: this constructor puts Point at the top-left, not the center. Shift it half-size.
		#var cell10Env = Rect2(point - Vector2(8, 12), Vector2(16, 25))
		#var placeEnv = Rect2(place.p[0] - Vector2(8, 12), Vector2(16, 25))
		#return cell10Env.intersects(placeEnv)
		#return Geometry2D.is_point_in_polygon(place.p[0], cell10)
	elif place.gt == 2:
		#its an open line
		var results =  Geometry2D.intersect_polyline_with_polygon(place.p, cell10)
		if results != null and results.size() > 0:
			return true
	elif place.gt == 3:
		#A closed shape. Check envelope first for speed.
		#This check is faster, but means the corner of your Cell10 must be inside
		#versus any part of the Cell10.
		#if place.envelope.has_point(point):
			#print(name + " in envelope! is in polygon: " + str(Geometry2D.is_point_in_polygon(point, place.p)))
			#return Geometry2D.is_point_in_polygon(point, place.p)
		#print(name + " Not in envelope")
		#return false
		#This below is for putting our current Cell10 (or surrounding sized area)
		#against the polygon. This is better for Cell11 movement and "Close enough" inclusions.
		var cell10Env = Rect2(point - Vector2(8, 12), point + Vector2(8, 12))
		var envelopeCheck = cell10Env.intersects(place.envelope, true)
		if envelopeCheck == true:
			var results = Geometry2D.intersect_polygons(cell10, place.p)
			if results != null and results.size() > 0:
				return true
	return false

static func PlusCodeToDataCoords(plusCode):
	#This is the Cell10 coords, because we multiply the value by the cell12 pixels on the axis.
	#Increasing Y here goes DOWN.
	plusCode = plusCode.replace("+", "")
	var testPointY = (PlusCodes.GetLetterIndex(plusCode[6]) * 500) + (PlusCodes.GetLetterIndex(plusCode[8]) * 25)
	var testPointX = (PlusCodes.GetLetterIndex(plusCode[7]) * 320) + (PlusCodes.GetLetterIndex(plusCode[9]) * 16)
	#var point = Vector2(testPointX / 16, testPointY / 25) #for reducing geometries to Cell10 sizes
	if plusCode.length() > 10:
		testPointX += PlusCodes.GetLetterIndex(plusCode[10]) % 4
		testPointY += int(PlusCodes.GetLetterIndex(plusCode[10]) / 5)
	
	var point = Vector2(testPointX, testPointY) #for using full precision data
	return point
