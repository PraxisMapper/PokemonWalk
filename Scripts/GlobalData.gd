extends Node
class_name GlobalData

#This is accessed via GameGlobals autoload
#Hold player info, game info loaded from files, etc.
#Access everything from GameGlobals autoload node.
signal updateHeader
signal updateData

var currentPlace = ["", ""]

var baseData = {}
var playerData = {
	version = 6,
	saveCreated = Time.get_unix_time_from_system(),
	currentXp = 0,
	currentLevel = 1,
	currentCoins = 0,
	stardust = 0, #for leveling pokemon and unlocking stuff on them.
	buddy = "", #key to which pokemon is our buddy for leveling/combat purposes. points to an entry
	#in another collection somewhere. the pokemon collection if possible.
	#Right, remember pogo combat was only at gyms, and you picked your team every time.
	#so for auto-combat, we'll use your buddy.
	candyByFamily = {}, #This gets filled in as candies are acquired from catching.
	items = {}, #items to customize or boost pokemon more, like TMs or IV boosts.
	autoCatch = true,
	autoHeal = true,
	unlockedSpawnData = [], #array of cell8s player has paid for
	dailyClearedRaids = [], #list of Cell8s the player's won a raid in today
	raidsLastCleared = 0, #unix timestamp, reset all on midnight
	#TODO: store a hash and validate it? Or do I not care about hackers that much?
	#Probably easier to save this encrypted instead.
	allowFusions = false, #set to true once unlocked
	pokemonTransferred = 0, #tracked for story stuff.
	soundEnabled = true,
	showLocation = true,
	pokedex = [],
	secretsGranted = [],
	shinyPityCount = 0,
}
var styleData = {}
var cachedAreaData = {}
var pokemonMutex = Mutex.new()
var pokemon = {}
var currentSpawnTable = {}
var gymData = {} #may be managed later. 

#If a pokemon is caught below the speed limit, it gets a signficant power boost.
#Initial value 5.5 m/s (12 mph / 20kph). Chosen because this is the best marathon speed on record.
var speedLimit = 5.5 
#The additional combat power mod added to a pokemon caught by walking (or removed from one caught by driving)
var speedBuff = .15
#This is how much extra stuff (xp, candy, stardust) you get for walking, versus driving.
var walkingMultiplier = 4 
#shiny pokemon are slightly stronger
var shinyBuff = .1
#pokemon caught as events, versus wild spawns, might get a power tweak?
#var eventMod = 0.1


#variables that I didn't end up using.
var commonPokemonPerArea = 6
var uncommonPokemonPerArea = 4
var rarePokemonPerArea = 1
var legendaryPokemonPerArea = 2

func _ready():
	#Load core data.
	var json = JSON.new()
	var dataFile = FileAccess.open("res://Assets/DataFiles/pokemonData.json", FileAccess.READ)
	var dataRaw = json.parse(dataFile.get_as_text())
	baseData = json.get_data()

	var implementedEntries = 0
	var badEntries = 0
	var partialEntries = 0
	#Dynamically update the move list to indicate which ones dont work.
	var me = MoveEffects.new() # referencing this now.
	var processedMoves = baseData.moves
	for move in processedMoves:
		var thisMove = processedMoves[move]
		if thisMove.functioncode != "None" and !me.has_method(thisMove.functioncode):
			if thisMove.power == null:
				thisMove.name = "Unimplemented" 
				badEntries += 1
			else:
				thisMove.name = "(D)" + thisMove.name
				partialEntries += 1
		else:
			implementedEntries += 1
				
	print("Move list has " + str(badEntries) + " items that do nothing")
	print("Move list has " + str(partialEntries) + " items that need a function")
	print("Move list has " + str(implementedEntries) + " with code in place")
	
	styleData = PraxisCore.GetStyle("suggestedmini")
	Load()
	
	#If some error caused a player's candy to go negative, fix it.
	for family in playerData.candyByFamily:
		if playerData.candyByFamily[family] < 0:
			playerData.candyByFamily[family] = 1

	#Check for a data-wipe error
	if pokemon.size() == 0 and playerData.buddy != "": #we HAD pokemon, and now we dont
		print("Total collection loss detected!")
		PraxisCore.WriteErrorLog("Total collection loss detected on startup!")
		pass #TODO: what action can be done here? Restore backup? Alert player?
		

	if (playerData.buddy == ""):
		if pokemon.size() > 0:
			playerData.buddy = pokemon.keys()[0]
		else:
			var starter = PokemonGenerator.MakeMobilePokemon(SpawnLogic.starters.pick_random())
			pokemon[starter.id] = starter
			playerData.candyByFamily[starter.family] = 1
			playerData.buddy = starter.id
			GameGlobals.playerData.pokedex.append(starter.key)
		Save()
		
	if UpdateSaveVersion():
		Save()
	
	MakeBackups()
	
func UpdateSaveVersion():
	var results = false
	if playerData.version < 1: #Shouldn't get here, this was for early dev.
		playerData.version = 1
		results = true
	if playerData.version < 2: #Release 3 of Pokemon Walk
		playerData.version = 2
		playerData.pokemonTransferred = 0
		for p in pokemon:
			pokemon[p].caughtSpeed = -1
			pokemon[p].isEvent = false
			pokemon[p].location = "Unknown"
			pokemon[p].buddyBoost = pokemon[p].buddyPlaces.size() * 0.01
			if pokemon[p].distanceWalked >0:
				print("Break")
			print("distanceWalked is: " + str(pokemon[p].distanceWalked))
			pokemon[p].distanceTravelled = pokemon[p].distanceWalked #now tracking actual walking vs all movement
			pokemon[p].distanceWalked = 0
			print("distancetravelled is: " + str(pokemon[p].distanceTravelled))
			print("distanceWalked is: " + str(pokemon[p].distanceWalked))
		results = true
	if playerData.version < 3: #Release 5 of Pokemon Walk
		playerData.version = 3
		if !playerData.has("soundEnabled"):
			playerData.soundEnabled = true
		if !playerData.has("showLocation"):
			playerData.showLocation = true
		for p in pokemon:
			pokemon[p].combatPower = PokemonHelpers.GetCombatPower(pokemon[p])
		results = true
	if playerData.version < 4: #Release 6 of Pokemon Walk
		playerData.version = 4
		playerData.pokedex = []
		if playerData.currentLevel >= 25:
			playerData.allowFusions = true # Was 'alllowFusions', which didn't work.
		for p in pokemon:
			#Add each existing pokemon to the pokedex now.
			if playerData.pokedex.find(pokemon[p].key) == -1:
				playerData.pokedex.append(pokemon[p].key)
		results = true
	if playerData.version < 5: #Release 7 of Pokemon Walk
		playerData.version = 5
		#Yes this is duplicated. There was a typo that made this fail in V6.
		if playerData.currentLevel >= 25: 
			playerData.allowFusions = true
		results = true
	if playerData.version < 6:  #release 10
		playerData.version = 6
		playerData.secretsGranted = []
		playerData.shinyPityCount = 0
		pokemonMutex.lock()
		for p in pokemon:
			var data = pokemon[p]
			data.isShiny = false #randf() <= .0009765625 #People will re-import to get shinies, skip this
			pokemon[p] = data
		pokemonMutex.unlock()
		results = true
	
	#Always do this, data sanity check.
	if playerData.has("pokedex") == false:
		playerData.pokedex = []
		results = true
	
	var levelCap = (playerData.currentLevel + 5) * 2
	for p in pokemon:
		if pokemon[p].level > levelCap:
			pokemon[p].level = levelCap
	return results
	
func Load():
	var loadplayerData = PraxisCore.LoadData("user://saveData.json") 
	if (loadplayerData != null):
		playerData = loadplayerData
	pokemonMutex.lock()
	print("loading pokemon")
	pokemon = PraxisCore.LoadData("user://pokemonCollection.json")
	if pokemon == null:
		print("pokemon collection failed to load!")
		pokemon = {}
	print("Pokemon collection size: " + str(pokemon.size()))
	pokemonMutex.unlock()
	
	#TODO: restore this if/when gyms are added.
	#gymData = PraxisCore.LoadData("user://gymData.json")
	if gymData == null:
		gymData = {}
	
	if playerData.keys().size() == 0:
		DefaultPlayerData()
		Save()
	
func Save():
	var success = true
	success = success and PraxisCore.SaveData("user://saveData.json", playerData)
	if success == false:
		print("Failed on saving user data!")
	pokemonMutex.lock()
	success = success and PraxisCore.SaveData("user://pokemonCollection.json", pokemon)
	if success == false:
		print("Failed on saving pokemon data!")
	pokemonMutex.unlock()
	#success = success and PraxisCore.SaveData("user://gymData.json", gymData)
	#if success == false:
		#print("Failed on saving Gym data!")
	return success
	
func MakeBackups():
	print("making backups")
	var date =  int(Time.get_unix_time_from_system())
	PraxisCore.SaveData("user://Backups/" + str(date) + "-saveData.backup.json", playerData) 
	PraxisCore.SaveData("user://Backups/" + str(date) + "-pokemonCollection.backup.json", pokemon) 
	PraxisCore.SaveData("user://Backups/" + str(date) + "-gymData.backup.json", gymData) 

func RestoreBackup(date):
	print("restoring backups")
	playerData = PraxisCore.LoadData("user://Backups/" + str(date) + "-saveData.backup.json") 
	pokemon = PraxisCore.LoadData("user://Backups/" + str(date) + "-pokemonCollection.backup.json") 
	gymData = PraxisCore.LoadData("user://Backups/" + str(date) + "-gymData.backup.json") 
	UpdateSaveVersion()

func GrantPlayerXP(amount):
	playerData.currentXp += amount
	if playerData.currentXp >= 100 * (playerData.currentLevel ** 2):
		playerData.currentLevel += 1
		if playerData.currentLevel >= 25:
			playerData.allowFusions = true
	

#NOTE: this was for a full-combat setup, but I might keep it for the mobile style as well.
func DefaultPlayerData():
	playerData.version = 0 #for tracking changes
	playerData.team = [0, 1, 2, 3, 4, 5] #is now ID pointers to entries in allCaught
	playerData.allCaught = [] #all actual pokemon entries. 
	
	#TODO: starting team should be 6 random-ish pokemon from the real common sets
	#bird, bug, weak critter, plant, cute thing, baby
	#this at least lets you immediately get into the 6v6 setup
	
	var birds = ["PIDGEY", "HOOTHOOT", "TAILLOW", "STARLY", "PIDOVE", "FLETCHLING", "PIKIPEK", "ROOKIDEE", "WATTREL"]
	var bugs = ["CATERPIE", "WEEDLE", "LEDYBA", "WURMPLE", "COMBEE", "KRICKETOT", "SEWADDLE", "SCATTERBUG",
	 "GRUBBIN", "BLIPBUG", "TAROUNTULA", "NYMBLE"]
	var critters = ["RATTATA", "SENTRET", "ZIGZAGOON", "BIDOOF", "PATRAT", "BUNNELBY", "YUNGOOS", "SKWOVET", "LECHONK"]
	var plant = ["ODDISH", "BELLSPROUT", "HOPPIP", "SEEDOT", "BUDEW", "COTTONEE", "SKIDDO", "FOMANTIS", "GOSSIFLEUR", "SMOLIV"]
	var cute = ["PICHU", "IGGLYBUFF", "TOGEPI", "AZURILL", "PLUSLE", "MINUN", "PACHIRISU", "EMOLGA", "DEDENNE",
	"TOGEDEMARU", "MIMIKYU", "MORPEKO", "PAWMI"] #"not-pikachu"s and mascot
	
	playerData.allCaught.push_back(PokemonHelpers.NewPokemonDataByKey(birds[randi() % birds.size()]))
	playerData.allCaught.push_back(PokemonHelpers.NewPokemonDataByKey(bugs[randi() % bugs.size()]))
	playerData.allCaught.push_back(PokemonHelpers.NewPokemonDataByKey(critters[randi() % critters.size()]))
	playerData.allCaught.push_back(PokemonHelpers.NewPokemonDataByKey(plant[randi() % plant.size()]))
	playerData.allCaught.push_back(PokemonHelpers.NewPokemonDataByKey(cute[randi() % cute.size()]))
	playerData.allCaught.push_back(PokemonHelpers.NewPokemonDataByKey(SpawnLogic.starters.pick_random()))
	
	#NOTE: when filling these in, they should get 150 XP or so to start, that makes them level 5ish.
	for i in 6:
		playerData.allCaught[i].xp = 150
	
	playerData.startingCell6Today = ""
	playerData.today = Time.get_date_string_from_system()
	
#TODO: this one isn't in PraxisMapper? Or because it's suggestedmini only?
func ScanArea(areaData, terrainID):
	var possiblePlaces = []
	for place in areaData.entries["suggestedmini"]:
		if (place.has("nid")):
			possiblePlaces.push_back({name = areaData.nameTable[str(place.nid)], area = areaData.olc, type = place.tid, geoType = place.gt})
	return possiblePlaces
