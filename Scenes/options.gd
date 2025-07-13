extends Node2D
class_name OptionsScene

func _ready():
	$chkSound.button_pressed = GameGlobals.playerData.soundEnabled
	$chkShowLocation.button_pressed = GameGlobals.playerData.showLocation

func ToggleSound(enabled):
	GameGlobals.playerData.soundEnabled = enabled
	GameGlobals.Save()

var locationtoggledCount = 0
func ToggleLocation(enabled):
	GameGlobals.playerData.showLocation = enabled
	locationtoggledCount +=1
	#Obscure location for cheat code testing
	if (locationtoggledCount == 3 and !GameGlobals.playerData.secretsGranted.has("1") and PraxisCore.currentPlusCode.begins_with("8FW5X7")):
		var secret1 = PokemonGenerator.MakeMobilePokemon('FERALIGATR')
		secret1.isShiny = true
		secret1.IVs[0] = randi_range(12,15)
		secret1.IVs[1] = randi_range(12,15)
		secret1.IVs[2] = randi_range(12,15)
		secret1.caughtSpeed = 1.5
		GameGlobals.pokemon[secret1.id] = secret1
		GameGlobals.playerData.stardust += 10000
		GameGlobals.playerData.secretsGranted.append("1")
		$AudioStreamPlayer.stream = SoundSystem.secretSound
		$AudioStreamPlayer.play()
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
	#$FileDialog.files_selected.disconnect(ImportData)
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

func DownloadCell4Data():
	$GetFile.getCell4File(PraxisCore.currentPlusCode.substr(0,4))
	
func RestoreWindow():
	$crRestore.position.x = 40
	
	var files = DirAccess.get_files_at("user://Backups/")
	var rawDates = []
	for f in files:
		var parts = f.split("-")
		if !rawDates.has(int(parts[0])):
			rawDates.append(int(parts[0]))
	rawDates.sort()
	rawDates.reverse()
	
	var time = Time.get_unix_time_from_system()
	
	#1 = 1 second
	#60 = 1 minute
	#3600 = 1 hour
	#86400 = 1 day
	for d in rawDates:
		var diff = time - d
		var daysOld = int(diff / 86400)
		diff = diff - (daysOld * 86400)
		var hoursOld = int(diff / 3600)
		diff = diff - (hoursOld * 3600)
		var minutesOld = int(diff / 60)
		diff = diff - (minutesOld * 60)
		var secondsOld = int(diff)
		
		var dispString = ""
		if daysOld > 0:
			dispString += str(daysOld) + " days, "
		if hoursOld > 0:
			dispString += str(hoursOld) + " hours, "
		if minutesOld > 0:
			if daysOld == 0:
				dispString += str(minutesOld) + " minutes, "
		if secondsOld > 0:
			if hoursOld == 0:
				dispString += str(secondsOld) + " seconds "
		dispString += "(" + str(d) + ")"
		
		$crRestore/ItemList.add_item(dispString)

func RestoreReal():
	var picked = $crRestore/ItemList.get_selected_items()
	if picked.size() == 0:
		return
	
	var item = $crRestore/ItemList.get_item_text(picked[0])
	var timestamp = item.split("(")[1].split(")")[0]
	
	GameGlobals.RestoreBackup(timestamp)
	Close()

func RestoreCancel():
	$crRestore.position.x = 1000

func ViewErrors():
	$crError.position.x = 40
	var errorData = PraxisCore.ReadErrorLog()
	var errors = errorData.split("\n")
	errors.reverse()
	
	for e in errors:
		$crError/sc/lblErrors.text += e + "\n"

func ErrorLogCancel():
	$crError.position.x = 2000
