extends Node2D
#This scene will be the pokedex info, showing which pokemon forms you have and
#have not found yet.
#May also include a scanner to find where they spawn nearby.

var showing = "all"
var currentItemToAdd = 0
var displayedItems = GameGlobals.baseData.pokemon.keys()
var allCount = displayedItems.size()
const sizeVec = Vector2(96, 96)
var plDisplay = preload("res://Components/PoGoMiniDisplay.tscn")
var haveInSet = 0

var scanner = FullAreaScanner.new()


func _ready() -> void:
	pass # Replace with function body.

const itemsPerFrame = 3
func _process(delta: float) -> void:
	var itemsLeft = 0
	if currentItemToAdd < allCount and itemsLeft < itemsPerFrame:
		var currentData = GameGlobals.baseData.pokemon[displayedItems[currentItemToAdd]]
		var pokemonFound = GameGlobals.playerData.pokedex.has(currentData.key)
		var cc = Control.new()
		cc.set_size(sizeVec)
		cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cc.custom_minimum_size = sizeVec
		var display = plDisplay.instantiate()
		
		display.skipOnStart = true
		display.SetPokedexInfo(currentData.key, pokemonFound)
		cc.add_child(display)
		$sc/gc.add_child(cc)
		display.leftClicked.connect(showPokedexInfo) 
		currentItemToAdd += 1
		itemsLeft += 1
		if pokemonFound:
			haveInSet += 1
			$lblCount.text = str(haveInSet) + "/" + str(allCount)

func showPokedexInfo(data):
	#data has .key and .isCaught fields.
	var baseData = GameGlobals.baseData.pokemon[data.key]
	$PokeInfo/txrPokemon.texture = load(PokemonHelpers.GetPokemonFrontSprite(baseData.key, false, "M"))
	
	#fill in boxes with stuff
	if data.isCaught:
		$PokeInfo/lblName.text = baseData.name
		if baseData.formName != null:
			$PokeInfo/lblName.text += " (" + baseData.formName + ")"
		var desc = ""
		desc += "Types: "
		for t in baseData.types:
			desc += t + ", "
		desc += "\n"
	
		if baseData.generation != null:
			desc += "Generation: " + baseData.generation + "\n"
		if baseData.color != null:
			desc += "Color: " + baseData.color + "\n"
		if baseData.shape != null:
			desc += "Shape: " + baseData.shape + "\n"
		if baseData.habitat != null:
			desc += "Habitat: " + baseData.habitat + "\n"
		$PokeInfo/lblDesc.text = desc
	else:
		$PokeInfo/lblDesc.text = "Find this pokemon to learn its details"
		$PokeInfo/txrPokemon.modulate = "000000"
		$PokeInfo/lblName.text = "????"

	var searchKey = baseData.family
	$PokeInfo/lblFindable.text = "Areas Nearby: Searching..."
	$PokeInfo.position.x = 0
	await RenderingServer.frame_post_draw
	if baseData.habitat == "Rare" or baseData.habitat == "Legendary":
		$PokeInfo/lblFindable.text = "Areas Nearby: " +  await FindNearbyRaids(searchKey, PraxisCore.currentPlusCode.substr(0,8))
	else:
		$PokeInfo/lblFindable.text = "Areas Nearby: " +  await FindNearbySpawns(searchKey, PraxisCore.currentPlusCode.substr(0,8))

func ClosePokeInfo():
	$PokeInfo.position.x = 900
	
func FindNearbyRaids(key, locationCell8, searchRange = -1):
	var found = ""
	if (searchRange == -1):
		for dist in range(0,10):
			found = await FindNearbyRaids(key, locationCell8, dist)
			if (found != "Not nearby this week"):
				return found
	
	for x in range(-searchRange, searchRange):
		for y in range(-searchRange, searchRange):
			var code = PlusCodes.ShiftCode(locationCell8, x, y)
			var spawnData = SpawnLogic.PickRaidBoss(code)
			if spawnData == key:
				found = code
				var dist = PlusCodes.GetDistanceCell8s(locationCell8, code)
				found += abs(dist.x) + " tiles " + ("east, " if dist.x > 0 else "west, ")
				found += abs(dist.y) + " tiles " + ("north" if dist.y > 0 else "south")
				var dir = PlusCodes.GetDirection(locationCell8, code)
				found += ", " + str(dist) + " maptiles, heading " + str(dir)
				if PraxisOfflineData.OfflineDataExists(code):
					var place = await scanner.PickPlace(code, "mapTiles")
					found = code + ", near " + place.name
				return found
	
	return "Not nearby this week"
	
func FindNearbySpawns(key, locationCell8, searchRange = -1):
	var found = ""
	if (searchRange == -1):
		for dist in range(0,10):
			found = await FindNearbySpawns(key, locationCell8, dist)
			if (found != "Not available nearby"):
				return found
	
	for x in range(-searchRange, searchRange):
		for y in range(-searchRange, searchRange):
			var code = PlusCodes.ShiftCode(locationCell8, x, y)
			var spawnData = SpawnLogic.SpawnTable(code)
			if spawnData.has(key):
				found = code
				var dist = PlusCodes.GetDistanceCell8s(code, locationCell8)
				found += ", " + str(abs(dist.x)) + " tiles " + ("east, " if dist.x > 0 else "west, ")
				found += str(abs(dist.y)) + " tiles " + ("north" if dist.y > 0 else "south")
				#var dir = PlusCodes.GetDirection(locationCell8, code)
				#found += ", " + " heading " + str(dir)
				if PraxisOfflineData.OfflineDataExists(code):
					var place = await scanner.PickPlace(code, "mapTiles")
					found += ", near " + place.name
				return found

	return "Not available nearby"

func Close():
	queue_free()

func ChangeSort():
	var setItems 
	displayedItems.clear()
	match showing: #this is when we move to the next value
		"all": 
			$btnSortKey.text = "Uncaught"
			showing = "uncaught"
			setItems = GameGlobals.baseData.pokemon.keys()
			displayedItems = []

			for a in setItems:
				if !GameGlobals.playerData.pokedex.has(a):
					displayedItems.append(a)
		"uncaught":
			$btnSortKey.text = "Kanto"
			showing = "gen1"
			setItems = GameGlobals.baseData.pokemon.keys()
			for pokemon in setItems:
				if GameGlobals.baseData.pokemon[pokemon].generation == "1":
					displayedItems.append(pokemon)
		"gen1":
			$btnSortKey.text = "Johto"
			showing = "gen2"
			setItems = GameGlobals.baseData.pokemon.keys()
			for pokemon in setItems:
				if GameGlobals.baseData.pokemon[pokemon].generation == "2":
					displayedItems.append(pokemon)
		"gen2":
			$btnSortKey.text = "Hoenn"
			showing = "gen3"
			setItems = GameGlobals.baseData.pokemon.keys()
			for pokemon in setItems:
				if GameGlobals.baseData.pokemon[pokemon].generation == "3":
					displayedItems.append(pokemon)
		"gen3":
			$btnSortKey.text = "Sinnoh"
			showing = "gen4"
			setItems = GameGlobals.baseData.pokemon.keys()
			for pokemon in setItems:
				if GameGlobals.baseData.pokemon[pokemon].generation == "4":
					displayedItems.append(pokemon)
		"gen4":
			$btnSortKey.text = "Unova"
			showing = "gen5"
			setItems = GameGlobals.baseData.pokemon.keys()
			for pokemon in setItems:
				if GameGlobals.baseData.pokemon[pokemon].generation == "5":
					displayedItems.append(pokemon)
		"gen5":
			$btnSortKey.text = "Kalos"
			showing = "gen6"
			setItems = GameGlobals.baseData.pokemon.keys()
			for pokemon in setItems:
				if GameGlobals.baseData.pokemon[pokemon].generation == "6":
					displayedItems.append(pokemon)
		"gen6":
			$btnSortKey.text = "Alola"
			showing = "gen7"
			setItems = GameGlobals.baseData.pokemon.keys()
			for pokemon in setItems:
				if GameGlobals.baseData.pokemon[pokemon].generation == "7":
					displayedItems.append(pokemon)
		"gen7":
			$btnSortKey.text = "Galar"
			showing = "gen8"
			setItems = GameGlobals.baseData.pokemon.keys()
			for pokemon in setItems:
				if GameGlobals.baseData.pokemon[pokemon].generation == "8":
					displayedItems.append(pokemon)
		"gen8":
			$btnSortKey.text = "Paldea"
			showing = "gen9"
			setItems = GameGlobals.baseData.pokemon.keys()
			for pokemon in setItems:
				if GameGlobals.baseData.pokemon[pokemon].generation == "9":
					displayedItems.append(pokemon)
		"gen9":
			$btnSortKey.text = "Fusions"
			showing = "fusion"
			setItems = GameGlobals.baseData.pokemon.keys()
			for pokemon in setItems:
				if GameGlobals.baseData.pokemon[pokemon].family == "FUSION":
					displayedItems.append(pokemon)
		"fusion":
			$btnSortKey.text = "All"
			showing = "all"
			displayedItems = GameGlobals.baseData.pokemon.keys()

	allCount = displayedItems.size()
	$lblCount.text = "0/" + str(allCount)
	FillGrid()
	
func FillGrid():
	haveInSet = 0
	for x in $sc/gc.get_children():
		$sc/gc.remove_child(x)
		x.queue_free()
	await get_tree().process_frame
	currentItemToAdd = 0
