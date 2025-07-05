extends Node
class_name PokemonHelpers

# TODO: remember I'm making abilities and types arrays to allow for possible fusions.

static func GetPokemonFrontSprite(pokemonKey, isShiny, gender):
	#Naming rules:
	#base path: Assets/Front
	#if shiny? append " shiny"
	#add "/"
	#add pokemon key (all caps name)
	#if form ID != 0: add "_" + formId (should be in the key passed in)
	#else if genders are visibly different and this is a female: add "_female"
	#NOTE: currently theres no flag for which species use a female sprite. May just have to check for
	#the presence of that filename.
	#add .png. Thats the file name to get.
	
	var spriteName = "res://Assets/Front/"
	
	
	#else:
		#spriteName += "/"
	
	if (gender == "f"):
		if ResourceLoader.exists(spriteName + pokemonKey + "_female.png"):
			spriteName += pokemonKey + "_female.png"
	else:
		spriteName += pokemonKey + ".png"
	
	#NOTE: ResourceLoader is necessary to get these sprites in the released game.
	#The textures are compressed and no longer on disk, so FileAccess.file_exists always fails on mobile.
	if pokemonKey.contains("_"):
		#If this form doesnt have a separate sprite, use the base one.
		print("Looking for filename " + spriteName)
		if !ResourceLoader.exists(spriteName):
			print("File not found, getting " + spriteName.split("_")[0] + ".png instead")
			spriteName = spriteName.split("_")[0] + ".png"
			
	#Now that all keys are applied, do a shiny check
	if isShiny:
		var shinyCheck = spriteName.replace("Front/", "Front/shiny/")
		if ResourceLoader.exists(shinyCheck):
			spriteName = shinyCheck
		else:
			print("No shiny form found for " + pokemonKey)

	return spriteName
	
static func NewPokemonData(pokemonNumber):
	#TODO: This may require moving some source data round, in case forms/variants arent in order.
	var entry = GameGlobals.baseData.pokemon.keys()[pokemonNumber] #should work for number, need to fix display.
	return NewPokemonDataByKey(entry)

static func NewPokemonDataByKey(pokemonKey):
	var shinyOdds= .0009765625 #1 in 1024 is shiny.
	if Time.get_datetime_dict_from_system().day == 27:
		shinyOdds = .001953125 #1 in 512 is shiny on Shiny Day
	var data = {
		key = pokemonKey, #baseData.pokemon[pokemonKey], #pokemonKey, #PIKACHU, in baseData.allPokemon
		xp = 0, #This gets saved per pokemon
		item = {}, #ITEM, in baseData.items when i get there.
		isShiny = randf() <= shinyOdds,
		gender = "m",
		abilityId = 0, #which entry in the abilities array is this pokemon's ability.
		nature = "",
		knownMoves = ["", "", "", ""], # Keys of move names in baseData.moves. NOTE: moves is baseline data
		ivs = [randi_range(1, 31),randi_range(1, 31),randi_range(1, 31),randi_range(1, 31),randi_range(1, 31),randi_range(1, 31)],
		evs = [0,0,0,0,0,0],
		hp = 1,
		personality = "random"
	}
	#New pokemon get 4 moves off their default list. Other moves will come from TMs or such.
	var pickedMoves = 4
	var possibleMoves = GameGlobals.baseData.pokemon[pokemonKey].moves
	if (possibleMoves.size() < 4):
		data.knownMoves = possibleMoves.duplicate()
	else:
		var i = 0
		while i < pickedMoves: 
			var nextMove = possibleMoves.pick_random()
			if !data.knownMoves.has(nextMove):
				data.knownMoves[i] = nextMove
				i += 1
	
	return data
	
static func GetTeamSlotInfo(teamSlotId):
	return GameGlobals.playerData.allCaught[GameGlobals.playerData.team[teamSlotId]]
	
static func SaveBackToPlayerData(collectionSlot, data):
	#the reverse of hydratePokemon
	var playerData = GameGlobals.baseData.pokemon[collectionSlot]
	playerData.xp = data.xp
	playerData.item = data.item #some items could be used!
	playerData.evs = playerData.evs #i COULD implement this too.
	

static func hydratePokemon(instanceData):
	var baseData = GameGlobals.baseData.pokemon[instanceData.key]
	var fullPokemon = baseData.duplicate(true)
	
	#now merge the 2 together.
	fullPokemon.xp = instanceData.xp
	fullPokemon.item = instanceData.item
	fullPokemon.isShiny = instanceData.isShiny
	fullPokemon.gender = instanceData.gender
	fullPokemon.abilityId = instanceData.abilityId
	fullPokemon.nature = instanceData.nature
	fullPokemon.knownMoves = instanceData.knownMoves
	fullPokemon.ivs = instanceData.ivs
	fullPokemon.evs = instanceData.evs
	
	#TODO: this might not matter, if we just treat each battle as a full heal.
	#for km in fullPokemon.knownMoves:
		#km.pp = int(fullPokemon.knownMoves[km].totalPP)
	
	#Calculate parameters here, like final stats and level and such.
	fullPokemon.level = CalculateCurrentLevel(fullPokemon)
	fullPokemon.stats = CaculateStats(fullPokemon)
	fullPokemon.statStages = [0,0,0,0,0,0,0,0] 
	#actual pokemon stages are stat multipliers, and have fixed entries -6 to 6
	#NOTE: statStages[6] is Accuracy, and [7] is Evasion, which dont have stats per pokemon.
	fullPokemon.hp = fullPokemon.stats[0]
	fullPokemon.permStatusEffect = null #Burn, paralyze, etc
	fullPokemon.tempStatusEffect = [] #can be multiple things. Confusion, drowsy, etc.
	
	#get sprite here
	fullPokemon.sprite = GetPokemonFrontSprite(instanceData.key, instanceData.isShiny, instanceData.gender)
	
	#AI selection type here.
	fullPokemon.personality = instanceData.personality
	
	#set up initial special handlers. Currently guesses for now.
	fullPokemon.onEnterBattle = null
	fullPokemon.beforeHit = null
	fullPokemon.afterHit = null
	fullPokemon.afterTurn = null
	fullPokemon.onFaint = null
	
	
	#Some quick Debug info
	print("Hydrated " + fullPokemon.name)
	print("Level: " + str(fullPokemon.level) + " HP: " + str(fullPokemon.hp))
	
	return fullPokemon

static func CalculateCurrentLevel(pokemon):
	var growthRate = GameGlobals.baseData.pokemon[pokemon.key].growthrate
	var level = 1
	
	#if growthRate == "Medium": #Medium Fast on wiki
	#Everyone is Medium growth until I get around to this.
	level = pokemon.xp ** (1.0 / 3.0)
	#elif growthRate == "Parabolic": #Medium Slow on wiki. This math is stupid.
		#var base = pokemon.xp ** (1.0 / 3.0)
		#base *= (6 / 5)
		#base -= (15 * (n ** 2))
		#base += (100 * n)
		#base -= 140
		#level = exp +140 
		
	
	return int(level)

static func CaculateStats(pokemon):
	var baseStats = GameGlobals.baseData.pokemon[pokemon.key].baseStats
	var ivs = pokemon.ivs
	var evs = pokemon.evs
	var nature = GetNatureTable(pokemon.nature)
	
	#TODO: multiply stuff by nature table values.
	var hp = ((((baseStats[0] * 2) + ivs[0] + (evs[0] / 4)) * pokemon.level) / 100) + pokemon.level + 10
	#TODO: Shedinja ability overrules HP, forces it to 1.
	var atk = (((((baseStats[1] * 2) + ivs[1] + (evs[1] / 4)) * pokemon.level) / 100) + 5) * nature[1]
	var def = (((((baseStats[2] * 2) + ivs[2] + (evs[2] / 4)) * pokemon.level) / 100) + 5) * nature[2]
	var spatk = (((((baseStats[3] * 2) + ivs[3] + (evs[3] / 4)) * pokemon.level) / 100) + 5) * nature[3]
	var spdef = (((((baseStats[4] * 2) + ivs[4] + (evs[4] / 4)) * pokemon.level) / 100) + 5) * nature[4]
	var spd = (((((baseStats[5] * 2) + ivs[5] + (evs[5] / 4)) * pokemon.level) / 100) + 5) * nature[5]
	
	return [int(hp), int(atk), int(def), int(spatk), int(spdef), int(spd)]

static func GetNatureTable(nature):
	#Everyone gets a blank nature until I feel like punching in all 25 entries.
	return [1, 1, 1, 1, 1, 1] 
	
static func ExpGainedFromDefeat(winner, loser):
	var granted = ((int(loser.baseexp) * loser.level) / 5)
	granted *= (((loser.level * 2) + 10) / ((loser.level + winner.level + 10) ** 2.5)) + 1
	
	#TODO: special considerations
	if winner.item.has("LuckyEgg"):
		granted *= 1.5
	
	return int(granted)
	
static func GetAccuracyEvasionStageModifier(pokemon, stage):
	var numerator = 3
	var denominator = 3
	if stage > 0:
		numerator += stage
	if stage < 0:
		denominator += stage
	return numerator / denominator

static func GetStatStageModifier(stage):
	var numerator = 2
	var denominator = 2
	if stage > 0:
		numerator += stage
	if stage < 0:
		denominator += stage
	return numerator / denominator
	
static func GetCurrentStat(pokemon, statIndex):
	return pokemon.stats[statIndex] * GetStatStageModifier(pokemon.statStages[statIndex])

static func GetCombatPower(pogoData):
	var base = GameGlobals.baseData.pokemon[pogoData.key]
	var powermultiplier = PoGoLevelCurves.GetCombatPowerMultiplier(pogoData)
	
	var cp = 0
	cp = base.PoGoAtk * (base.PoGoDef ** 0.5) * (base.PoGoSta ** 0.5) * (powermultiplier ** 2) * 0.1
	cp = floor(max(10, cp))
	return cp

static func GetStardustUpgradeCost(pokemonData):
	#calculate based on level. Pass in all data in case I make changes in the future.
	var cost = 0
	var increase = 200
	var increments = pokemonData.level / 4
	var boostsDone = 0
	#every 4 boosts, the cost increases by a value.
	#its 200 for 20 boosts, then 300 for 20 boosts, 500 for 20, 1000 after that.
	
	#BALANCE NOTE: the original math here was cumulative. 
	#Turns out, that ends up requiring a whole days worth of walking and winning
	#every fight to max out one pokemon. That's nonsense. Now, with this flat value
	#it takes about an hour of perfect victories instead. Losing fights make this take
	#longer, of course. But I'd rather an experienced player spend an hour walking to power 
	#up one good pokemon than a whole day for each.
	cost = 200# * pokemonData.level #minimum cost per level
	if pokemonData.level >= 20: #cost is 300 after this point
		cost += 100 # * (pokemonData.level - 20)
	if pokemonData.level >= 40: #500 per boost here
		cost += 200#  * (pokemonData.level - 40)
	if pokemonData.level >= 60: #and 1k from now on.
		cost += 500#  * (pokemonData.level - 60)
		
	return cost

static func BoostPokemon(key):
	#Load selected pokemon, boost, recalc combat power, save.
	var instanceData = GameGlobals.pokemon[key]
	var base = GameGlobals.baseData.pokemon[instanceData.key]
	
	var stardustCost = GetStardustUpgradeCost(instanceData)
	if GameGlobals.baseData.playerData.stardust > stardustCost:
		GameGlobals.baseData.playerData.stardust -= stardustCost
		instanceData.level += 1
		instanceData.combatPower = PokemonHelpers.GetCombatPower(instanceData)
		GameGlobals.Save()

static func Transfer(pokemonId, skipSave = false):
	var baseData =  GameGlobals.pokemon[pokemonId]
	var pokemonData = GameGlobals.baseData.pokemon[baseData.key]

	var candyGrind = 1
	var idx = baseData.family.find(pokemonData.key)
	if (idx > -1):
		candyGrind = 1 + (idx * 2)
	if (GameGlobals.playerData.candyByFamily.has(pokemonData.family)):
		GameGlobals.playerData.candyByFamily[pokemonData.family] += candyGrind
	else:
		GameGlobals.playerData.candyByFamily[pokemonData.family] = candyGrind
	GameGlobals.pokemon.erase(pokemonId)
	GameGlobals.playerData.pokemonTransferred += 1
	if !skipSave: #when multi-transferring, we save manually after all transfers.
		GameGlobals.Save()
