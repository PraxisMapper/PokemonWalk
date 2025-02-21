extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func Close():
	queue_free()

#func Export():
	##Set FileDialog properties
	#$FileDialog.root_subfolder = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	#$FileDialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	#$FileDialog.title = "Export Data"
	##$FileDialog.Access = FileDialog.ACCESS_FILESYSTEM
	#$FileDialog.position.x = 20
	##Make a zip file, put all the user's current data into that,
	##save it to some place the user allows us to.
	#$FileDialog.visible = true
	#$FileDialog.show()
	#
	#var okbtn = $FileDialog.get_ok_button()
	#okbtn.ahcor
	#okbtn.position.x = 100
	#
	#var cancelbtn = $FileDialog.get_cancel_button()
	#cancelbtn.position.x = 300
	#
	#$FileDialog.file_selected.connect(SaveFile)
	#$FileDialog.dir_selected.connect(SaveFolder)
	
func SaveFolder(path):
	$FileDialog.files_selected.disconnect(SaveFolder)
	SaveFile("PokemonWalkExport.zip")
	
func SaveFile(passedpath):
	SaveFile2()

#I might want this one, but I still need to let the user pick which one to import?
func SaveFile2():
	var path = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS) + "/PokemonWalkExport.zip"
	$FileDialog.files_selected.disconnect(SaveFile)
	print("Path is :" + path)
	var writer = ZIPPacker.new()
	var err = writer.open(path)
	if (err != OK):
		print("Cancelling save: " + str(err))
		return
		
	writer.start_file("pokemonCollection.json")
	writer.write_file(JSON.stringify(GameGlobals.pokemon).to_utf8_buffer())
	writer.close_file()
	
	writer.start_file("saveData.json")
	writer.write_file(JSON.stringify(GameGlobals.playerData).to_utf8_buffer())
	writer.close_file()
	
	writer.start_file("gymData.json")
	writer.write_file(JSON.stringify(GameGlobals.gymData).to_utf8_buffer())
	writer.close_file()
	
	writer.close()
	$crInfo.visible = true
	
	#queue_free()
	
#func Import():
	##Set FileDialog properties.
	##ask the user to pick a zip file, read it,
	##set the values of our data as the passed in json files, save as normal.
	#$FileDialog.root_subfolder = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	#$FileDialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	#$FileDialog.title = "Import Data"
	##$FileDialog.Access = FileDialog.ACCESS_FILESYSTEM
	#$FileDialog.position.x = 0
	##Make a zip file, put all the user's current data into that,
	##save it to some place the user allows us to.
	#$FileDialog.visible = true
	#$FileDialog.show()
	#
	#$FileDialog.file_selected.connect(ImportData)
	
func ImportData():
	$FileDialog.files_selected.disconnect(ImportData)
	var path = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS) + "/PokemonWalkExport.zip"
	var reader = ZIPReader.new()
	var err = reader.open(path)
	
	if err != OK:
		print("Cant import data: " + str(err))
		return
	
	var playerData = reader.read_file("saveData.json").get_string_from_utf8()
	GameGlobals.playerData = JSON.parse_string(playerData)
	
	var pokemon = reader.read_file("pokemonCollection.json").get_string_from_utf8()
	GameGlobals.pokemon = JSON.parse_string(pokemon)
	
	var gyms = reader.read_file("gymData.json").get_string_from_utf8()
	GameGlobals.gymData = JSON.parse_string(gyms)
	
	GameGlobals.Save()
	$crInfo.visible = true
	$crInfo/lblInfo.text = "Data Imported"
