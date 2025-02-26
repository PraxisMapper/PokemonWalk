extends Node2D

var sortMode = "order" #Name, order, etc.
var plDisplay = preload("res://Components/PoGoMiniDisplay.tscn")
var plFullDisplay = preload("res://Components/PoGoFullDisplay.tscn")

var sortedList
signal rightClicked(item)
signal leftClicked(item)

var currentItemToAdd = 0
var allItems
const sizeVec = Vector2(96, 96)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameGlobals.pokemonMutex.lock()
	sortedList = GameGlobals.pokemon.values()
	GameGlobals.pokemonMutex.unlock()
	allItems = sortedList.size() - 1
	leftClicked.connect(PopDetails) #default behavior
	FillGrid()

const itemsPerFrame = 3
func _process(time):
	var itemsLeft = 0
	if currentItemToAdd < allItems and itemsLeft < itemsPerFrame:
		var cc = Control.new()
		cc.set_size(sizeVec)
		cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cc.custom_minimum_size = sizeVec
		var display = plDisplay.instantiate()
		
		display.data = sortedList[currentItemToAdd]
		cc.add_child(display)
		$sc/gc.add_child(cc)
		display.leftClicked.connect(emitLeft) 
		currentItemToAdd += 1
		itemsLeft += 1

func ChangeSort():
	if (sortMode == "power"):
		sortMode = "order"
		$btnSortKey.text = "Order Caught"
	elif sortMode == "order":
		sortMode = "name"
		$btnSortKey.text = "Name"
	elif sortMode == "name":
		sortMode = "power"
		$btnSortKey.text = "Combat Power"
	FillGrid()

func FillGrid():
	for x in $sc/gc.get_children():
		$sc/gc.remove_child(x)
		x.queue_free()
	await get_tree().process_frame
	
	sortedList.sort_custom(SortList)
	$lblCount.text = "Current Inventory: " + str(sortedList.size())
	currentItemToAdd = 0

func SortList(a, b):
	if sortMode == "order": #the order they were caught in, which should be the order of the dict.
		var timeCaughtA = int(a.id.split("_")[2])
		var timeCaughtB = int(b.id.split("_")[2])
		return timeCaughtA < timeCaughtB
	elif sortMode == "power":
		return a.combatPower > b.combatPower
	elif sortMode == "name":
		return a.name < b.name
	#TODO other options later.
	return a
	
func emitLeft(data):
	leftClicked.emit(data)

func emitRight(data):
	rightClicked.emit(data)

func PopDetails(data):
	var fullDisplay = plFullDisplay.instantiate()
	fullDisplay.pokemonData = data
	fullDisplay.updateList.connect(FillGrid)
	add_child(fullDisplay)

func DisconnectDefault():
	leftClicked.disconnect(PopDetails)

func SmartClearInventory():
	#A pretty decent take on auto-transferring pokemon.
	#Rules:
	#1: Sort pokemon by combat power
	#2: keep the top half of them.
	#3: after that, keep 1 copy of each pokemon.
	
	GameGlobals.pokemonMutex.lock()
	var entries = GameGlobals.pokemon.values()
	entries.sort_custom(SmartClearSort)
	var counter = 0
	var size = entries.size() / 2
	var alreadySeen = []
	for e in entries:
		if !alreadySeen.has(e.key):
			alreadySeen.append(e.key)
			counter += 1
			continue
		if counter < size:
			counter += 1
			continue
		
		#now, this pokemon is not in the top half, and isn't unique. Transfer it.
		if (GameGlobals.playerData.candyByFamily.has(e.family)):
			GameGlobals.playerData.candyByFamily[e.family] += 1
		else:
			GameGlobals.playerData.candyByFamily[e.family] = 1
		GameGlobals.pokemon.erase(e.id)
		GameGlobals.playerData.pokemonTransferred += 1
	GameGlobals.pokemonMutex.unlock()
	GameGlobals.Save()
	_ready()

func SmartClearSort(a, b):
	return a.combatPower > b.combatPower

func Close():
	queue_free()
