extends Node2D
class_name PossiblePokemon

var spawnList

#TODO: make this a support node that doesn't listen to the signal, just takes in
#the one value it uses. Using this setup as-is for testing/development.
# Called when the node enters the scene tree for the first time.
func _ready():
	PraxisCore.plusCode_changed.connect(CalcPossiblePokemon)
	CalcPossiblePokemon(PraxisCore.currentPlusCode, "")
	var spritepath = PokemonHelpers.GetPokemonFrontSprite(spawnList[0], false, "male")
	var image = Image.load_from_file(spritepath)
	var texture = ImageTexture.create_from_image(image)
	$spriteTest.texture = texture

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

static func CalcPossiblePokemon(current, old):
	var cell8 = current.substr(0,8)
	
	var areaRng = RandomNumberGenerator.new()
	areaRng.seed = cell8.hash()
	
	var count = GameGlobals.baseData.familiesByHabitat.size()
	
	#Last 2 habitats are "Rare" and "Legendary", we exclude those specifically.
	var habitat = areaRng.randi() % (GameGlobals.baseData.familiesByHabitat.size() - 2)
	
	var possibleFamilies = GameGlobals.baseData.familiesByHabitat.values()[habitat]
	var options = possibleFamilies.size()
	
	#TODO: encouter rate table.
	#COmmons should be most of them obviously, 
	#Legendary(s?) should be very rare but also there's 200 of them, so lets not make it stupid hard to find.
	var basePokemonHere = []
	
	#First, grab a bunch of pokemon from 1 particular habitat.
	var fillTableTo =  GameGlobals.commonPokemonPerArea
	while (basePokemonHere.size() < fillTableTo):
		var nextId = areaRng.randi() % options
		var nextPokemon = possibleFamilies[nextId]
		if basePokemonHere.find(nextPokemon) == -1:
			basePokemonHere.push_back(nextPokemon)
	
	#Now pick a type, and load a few of anything with that type
	var typeChoice = areaRng.randi() % GameGlobals.baseData.pokemonByType.size()
	var thisType = GameGlobals.baseData.pokemonByType.values()[typeChoice]
	options = thisType.size()
	
	fillTableTo +=  GameGlobals.uncommonPokemonPerArea
	while (basePokemonHere.size() < fillTableTo):
		var nextId = areaRng.randi() % options
		var nextPokemon = thisType[nextId]
		if basePokemonHere.find(nextPokemon) == -1:
			basePokemonHere.push_back(nextPokemon)

	#last, pick a rare one (you pick fewer rares because their table is half the size of the legendary table)
	fillTableTo += GameGlobals.rarePokemnPerArea
	while (basePokemonHere.size() < fillTableTo):
		var rareId = areaRng.randi() % GameGlobals.baseData.familiesByHabitat["Rare"].size()
		var rarePokemon = GameGlobals.baseData.familiesByHabitat["Rare"][rareId]
		if basePokemonHere.find(rarePokemon) == -1:
			basePokemonHere.push_back(rarePokemon)

	#And legendaries (more than 1, because there's nearly 200 of these)
	fillTableTo += GameGlobals.legendaryPokemnPerArea
	while (basePokemonHere.size() < fillTableTo):
		var legendId = areaRng.randi() % GameGlobals.baseData.familiesByHabitat["Legendary"].size()
		var legendPokemon = GameGlobals.baseData.familiesByHabitat["Legendary"][legendId]
		if basePokemonHere.find(legendPokemon) == -1:
			basePokemonHere.push_back(legendPokemon)
	
	return basePokemonHere
	#spawnList = basePokemonHere
