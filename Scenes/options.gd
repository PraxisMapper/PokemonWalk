extends Node2D
class_name OptionsScene

func _ready():
	$chkSound.button_pressed = GameGlobals.playerData.soundEnabled

func ToggleSound(enabled):
	GameGlobals.playerData.soundEnabled = enabled
	GameGlobals.Save()

func Close():
	queue_free()

func SaveFolder(path):
	$FileDialog.files_selected.disconnect(SaveFolder)
	SaveFile("PokemonWalkExport.zip")
	
func SaveFile(passedpath):
	SaveFile2()

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
	
	GameGlobals.UpdateSaveVersion()
	
	GameGlobals.Save()
	$crInfo.visible = true
	$crInfo/lblInfo.text = "Data Imported"
