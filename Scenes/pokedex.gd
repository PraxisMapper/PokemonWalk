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
	
		desc += "Generation: " + baseData.generation + "\n"
		desc += "Color: " + baseData.color + "\n"
		desc += "Shape: " + baseData.shape + "\n"
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
	match showing: #this is when we move to the next value
		"all": 
			$btnSortKey.text = "Uncaught"
			showing = "uncaught"
			var setItems = GameGlobals.baseData.pokemon.keys()
			displayedItems = []

			for a in setItems:
				if !GameGlobals.playerData.pokedex.has(a):
					displayedItems.append(a)
		"uncaught":
			$btnSortKey.text = "All"
			showing = "all"
			displayedItems = GameGlobals.baseData.pokemon.keys()
	allCount = displayedItems.size()
	FillGrid()
	
func FillGrid():
	for x in $sc/gc.get_children():
		$sc/gc.remove_child(x)
		x.queue_free()
	await get_tree().process_frame
	currentItemToAdd = 0
