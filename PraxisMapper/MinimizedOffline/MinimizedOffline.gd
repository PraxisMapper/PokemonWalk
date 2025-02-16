extends Node
class_name MinimizedOffline

static func GetDataFromZip(plusCode):
	#Godot checks all files in the assets folder for something, so to cut down on
	#the file count at startup we use ~200 zip files each holding ~200 zip files.
	#So first, check if the code4 zip exists. If not, ppull it from the code2 zip.
	#Then read the code4 zip and pull out the actual code6 data
	var code2 = plusCode.substr(0, 2)
	var code4 = plusCode.substr(2, 2)        
	
	print("loading data for " + plusCode)
	if !FileAccess.file_exists("user://Data/Min/" + code2 + code4 + ".zip"):
		var zipReaderA = ZIPReader.new()
		var err = zipReaderA.open("res://OfflineData/Min/" + code2 + ".zip")
		if (err != OK):
			print("Read Error on " + code2 + ".zip: " + error_string(err))
			return null
		
		var innerFile = zipReaderA.read_file(code2 + code4 + ".zip")
		var destFile = FileAccess.open("user://Data/Min/" + code2 + code4 + ".zip", FileAccess.WRITE)
		destFile.store_buffer(innerFile)
		destFile.close()
	else:
		print("zip file exists and is ready to go.")
	
	var zipReaderB = ZIPReader.new()
	var err = zipReaderB.open("user://Data/Min/" + code2 + code4 + ".zip")
	if (err != OK):
		print("Read Error on " + code2 + code4 + ".zip: " + error_string(err))
		return null

	var rawdata := zipReaderB.read_file(plusCode.substr(0,6) + ".json")
	if (rawdata != null and rawdata.size() > 0):
		print("raw data loaded")
	else:
		print("no data found or loaded from zip.")
	var realData = rawdata.get_string_from_utf8()
	var json = JSON.new()
	json.parse(realData)
	if json.data == null:
		print("failed to process raw data, check json?")
		#TODO: return fake data so it draws an empty tile?
		#return {olc = plusCode, entities = {suggestedmini = {}}}
	
	return json.data

static func GetStyle(style):
	return PraxisCore.GetStyle("suggestedmini")
