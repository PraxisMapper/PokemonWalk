extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var code = PraxisCore.currentPlusCode
	
	#TODO functionalize this check
	var currentString = Time.get_datetime_dict_from_system(true)
	var yearAsSeconds= Time.get_unix_time_from_datetime_string(str(currentString.year) + "-01-01")
	var secondsIntoYear = Time.get_unix_time_from_system() - yearAsSeconds
	var weeksIntoYear = int(secondsIntoYear / (60 * 60 * 24 * 7))
	var weekEventPokemon = SpawnLogic.eventEntries[weeksIntoYear]
	var eventDesc = weekEventPokemon.name
	
	var spawnTable = SpawnLogic.SpawnTable(code.substr(0,8))
	var writeup = "In " + code.substr(0,8) + " today you can find:\n"
	
	if Time.get_datetime_dict_from_system().day == 27:
		writeup += "Its Shiny Day! 2X shiny chance!\n"
	
	for k in spawnTable.keys():
		if k == "total":
			continue
		
		var odds = snapped(float(spawnTable[k]) / spawnTable.total * 100.0, 2)
		#print(str(GameGlobals.baseData.pokemon[k]))
		if GameGlobals.baseData.pokemon[k].formName != null:
			writeup += str(odds) + "% chance: " + GameGlobals.baseData.pokemon[k].name + "(" + GameGlobals.baseData.pokemon[k].formName + ")\n" 
		else:
			writeup += str(odds) + "% chance: " + GameGlobals.baseData.pokemon[k].name + "\n" 
	
	var raidSpawns = SpawnLogic.RaidSpawnTable()	
	var rngLocal = RandomNumberGenerator.new()
	rngLocal.seed  = PraxisCore.currentPlusCode.substr(0,8).hash()
	
	for w in weeksIntoYear:
		rngLocal.randf() #make the same number of random pulls so we get the same result next.
	var thisWeekResults = rngLocal.randf()
	var picked = int((raidSpawns.size() - 1) * thisWeekResults)
	
	writeup += "\n It's " + eventDesc
	writeup += "\n\n\nThis weeks raid boss here is: " + GameGlobals.baseData.pokemon[raidSpawns[picked]].name
	
	$lblInfo.text = writeup
	
	
func Close():
	queue_free()
