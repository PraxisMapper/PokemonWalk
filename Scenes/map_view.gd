extends Node2D
#The main walk-around page. Other pages are drawn in the middle.

var spawnInfoWindowPL = preload("res://Components/ShowSpawnInfo.tscn")
var inventoryScreenPL = preload("res://Scenes/PoGoInventory.tscn")
var infoScreenPL = preload("res://Components/PoGoFullDisplay.tscn")

func _ready() -> void:
	$ScrollingCenteredMap/TileDrawerQueued/Banner.position = Vector2(182 + 96 + 170 ,237 + 268 + 230 + 35)
	$ScrollingCenteredMap/TileDrawerQueued/Banner.visible = false

	PraxisCore.plusCode_changed.connect(plusCodeChanged)
	$recentTracker.newRecent.connect(firstDailyCellVisit)
	$recentTracker.timeDiffSeconds = 60 * 60 #Resets every hour, not day
	$recentTracker.RemoveOld()
	plusCodeChanged(PraxisCore.currentPlusCode, "")
	
	$header/PoGoMiniDisplay.leftClicked.connect(BuddyInfo)
	$header/PoGoMiniDisplay.rightClicked.connect(ChangeBuddy)
	
	if GameGlobals.currentSpawnTable.is_empty():
		GameGlobals.currentSpawnTable = SpawnLogic.SpawnTable(PraxisCore.currentPlusCode.substr(0,8))
	
	GameGlobals.updateHeader.connect(UpdateHeader)
	UpdateHeader()

func _process(delta: float) -> void:
	$playerArrow.rotation = PraxisCore.GetCompassHeading()

func UpdateHeader():
	$header/lblCoins.text = "Coins: " + str(GameGlobals.playerData.currentCoins) + " Stardust: " +str(GameGlobals.playerData.stardust)
	
	#Balance notes: when this is * 1000, it takes way too long for your player level to increase.
	#Reduced it to 100, so it should be 10x faster. I expect this is a reasonable amount.
	var prevLevel = ((GameGlobals.playerData.currentLevel - 1) ** 2 * 100)
	var thisLevel = ((GameGlobals.playerData.currentLevel) ** 2 * 100) - prevLevel
	$header/lblXp.text = "Level " + str(GameGlobals.playerData.currentLevel) + " XP: " + str(GameGlobals.playerData.currentXp - prevLevel) + "/" + str(thisLevel)
	
	if (GameGlobals.playerData.unlockedSpawnData.has(PraxisCore.currentPlusCode.substr(0,8))):
		$footer/btnSpawns.text  = "View Spawn Info"
	else:
		$footer/btnSpawns.text = "Learn Spawns: 100 Coins"
	
	$header/PoGoMiniDisplay.SetInfo(GameGlobals.pokemon[GameGlobals.playerData.buddy])

func BuddyInfo(data):
	var infoscreen = infoScreenPL.instantiate()
	infoscreen.pokemonData = GameGlobals.pokemon[GameGlobals.playerData.buddy]
	$popup.add_child(infoscreen)

func ChangeBuddy(data):
	#Pop open a new inventory window, that lets you pick one item and set it as your buddy
	var inv = inventoryScreenPL.instantiate()
	
	clearPopup()
	$popup.add_child(inv)
	inv.DisconnectDefault()
	inv.leftClicked.connect(SetBuddy)
	
func SetBuddy(data):
	$header/PoGoMiniDisplay.SetInfo(data)
	GameGlobals.playerData.buddy = data.id
	GameGlobals.Save()
	clearPopup()

func firstDailyCellVisit(cell10):
	var newCoins = randi_range(3,8) + int(GameGlobals.playerData.currentLevel / 10)
	GameGlobals.playerData.currentCoins += newCoins
	var eventResults = randi_range(1, 6) # 1-4: coins: 5-6: combat
	if eventResults <= 4:
		$walkNotice/txrOpponent.visible = false
		$walkNotice/lblMessage.text = "You got " + str(newCoins) + " coins"
	else:
		#combat
		$walkNotice/txrOpponent.visible = true
		var opponentFamily = SpawnLogic.PickSpawn(GameGlobals.currentSpawnTable)
		var opponent = PokemonGenerator.MakeMobilePokemon(opponentFamily)
		#TODO: small chance of evolving the base pokemon in the wild.
		if (randf() < 0.1):
			pass
			#TODO: switch key to one of the evolutions.
		
		$walkNotice/txrOpponent.texture = load(PokemonHelpers.GetPokemonFrontSprite(opponent.key, false, "M"))
		var results = PoGoAutoBattle.Battle1v1(GameGlobals.pokemon[GameGlobals.playerData.buddy], opponent)
		print(results)
		if (results == 1):
			if GameGlobals.playerData.autoCatch and GameGlobals.playerData.currentCoins >= 10:
				GameGlobals.playerData.currentCoins -= 10
				GameGlobals.pokemon[opponent.id] = opponent
				$walkNotice/lblMessage.text = "Earned " + str(newCoins) + " coins and you caught a " + opponent.name + "!"
			else:
				$walkNotice/lblMessage.text = "Earned " + str(newCoins) + " and you defeated a " + opponent.name
			var family = GameGlobals.baseData.allFamilies[opponent.family]
			var familyIndex = family.find(opponent.key.split("_")[0])
			if (familyIndex < 0):
				familyIndex = 0
			var xp = 100
			var stardust = 100
			var candy = 1
			if family.size() == 3 and familyIndex > 0:
				xp += 150 * familyIndex
				stardust += 100 * familyIndex
				candy += 2 * familyIndex
			elif family.size() == 2 and familyIndex == 1:
				xp += 150
				stardust += 100
				candy = 3
			elif family.size() == 1:
				xp = 250
				stardust = 250
				candy = 3

			GameGlobals.GrantPlayerXP(xp)
			GameGlobals.playerData.stardust += stardust
			
			if (GameGlobals.playerData.candyByFamily.has(opponent.family)):
				GameGlobals.playerData.candyByFamily[opponent.family] += 3
			else:
				GameGlobals.playerData.candyByFamily[opponent.family] = 3
		elif results == 2:
			$walkNotice/lblMessage.text = "Earned " + str(newCoins) + " and you lost to a " + opponent.name
	
	$walkNotice.visible = true
	$walkNotice/tmrHide.start()
	GameGlobals.Save()

func HideWalkNotice():
	$walkNotice.visible = false

func UpdateRaidButton(cell8):
	if (GameGlobals.playerData.dailyClearedRaids.has(cell8)):
		$footer/btnRaid.text = "Raid Cleared"
		$footer/btnRaid.disabled = true
	else:
		$footer/btnRaid.text = "Fight Local Raid"
		$footer/btnRaid.disabled = false

func plusCodeChanged(current, old):
	var workthread = Thread.new()
	workthread.start(CheckPlaces.bind(current))
	
	$header/lblLocation.text = "Location: " + current
	#Quick check to enable raids, needs done before raid status is checked.
	CheckRaidReset()
	
	#check for the spawn table
	var cell8 = current.substr(0,8)
	if cell8 != old.substr(0,8):
		#rebuild spawn table.
		GameGlobals.currentSpawnTable = SpawnLogic.SpawnTable(cell8)
		UpdateRaidButton(cell8)

	#Later, I wont want to call this on every change
	#These might need varied with the number of tiles visible on screen at once.
	var xDiff = 3
	var yDiff = 3
	
	var baseCell = current.substr(0,6)
	var cellsToLoad = PlusCodes.GetNearbyCells(baseCell, 1)
	for c2l in cellsToLoad:
		if !PraxisOfflineData.OfflineDataExists(c2l):
			$GetFile.skipTween = true
			print("Getting new map file")
			$GetFile.AddToQueue(c2l)
	$ScrollingCenteredMap.plusCode_changed(PraxisCore.currentPlusCode, PraxisCore.lastPlusCode)
	UpdateHeader()
	workthread.wait_to_finish()

func SpawnInfo():
	if (GameGlobals.playerData.unlockedSpawnData.has(PraxisCore.currentPlusCode.substr(0,8))):
		clearPopup()
		var info = spawnInfoWindowPL.instantiate()
		$popup.add_child(info)
	elif GameGlobals.playerData.currentCoins >= 100:
		GameGlobals.playerData.currentCoins -= 100
		GameGlobals.playerData.unlockedSpawnData.append(PraxisCore.currentPlusCode.substr(0,8))
		GameGlobals.Save()
		UpdateHeader()

func clearPopup():
	for c in $popup.get_children():
		c.queue_free()

func CheckPlaces(current):
	var text = "Places:"
	var places = await PraxisOfflineData.GetPlacesPresent(current)
	if places != null:
		for place in places:
			if place.category != "adminBoundsFilled":
				text += place.name + ', '
	BuddyBonusSystem.UpdateBonus(GameGlobals.playerData.buddy, places, current) 
	BuddyBonusSystem.AddDistance(GameGlobals.playerData.buddy, 1) #add 1 cell to our distance walked.
	call_deferred("UpdatePlacesList", text)

func UpdatePlacesList(placesList):
	$header/lblPlaces.text = placesList

func ShowPokemonInventory():
	clearPopup()
	var inventory = inventoryScreenPL.instantiate()
	$popup.add_child(inventory)
	
func CheckRaidReset():
		#check if raids need reset first
	var currentString = Time.get_datetime_dict_from_system(true)
	var today = Time.get_unix_time_from_datetime_string(str(currentString.year) + "-" + str(currentString.month) + "-" + str(currentString.day))
	if GameGlobals.playerData.raidsLastCleared < today - (60 * 60 * 24): #is last cleared from midnight the day before
		GameGlobals.playerData.dailyClearedRaids.clear()
		GameGlobals.playerData.raidsLastCleared = today
		GameGlobals.Save()

func RaidBattle():
	#Determine which raid boss to fight here, pass info to battle scene, run it.
	var raidScene = preload("res://Scenes/PoGoGymFight.tscn").instantiate()
	clearPopup()

	if GameGlobals.playerData.dailyClearedRaids.has(PraxisCore.currentPlusCode.substr(0,8)):
		#TODO: consider making this a separate control on $popup so it clears away
		#automatically with other buttons, like all the other popups do.
		$boxAlreadyWon.position.x = 0
		return
	
	var raidSpawns = SpawnLogic.RaidSpawnTable()
	#TODO: functionalize this block
	var currentString = Time.get_datetime_dict_from_system(true)
	var yearAsSeconds= Time.get_unix_time_from_datetime_string(str(currentString.year) + "-01-01")
	var secondsIntoYear = Time.get_unix_time_from_system() - yearAsSeconds
	var weeksIntoYear = int(secondsIntoYear / (60 * 60 * 24 * 7))
	
	var rngLocal = RandomNumberGenerator.new()
	rngLocal.seed  = PraxisCore.currentPlusCode.substr(0,8).hash()
	
	for w in weeksIntoYear:
		rngLocal.randf() #make the same number of random pulls so we get the same result next.
	var thisWeekResults = rngLocal.randf()
	var picked = int((raidSpawns.size() - 1) * thisWeekResults)
	print("total of " + str(raidSpawns.size()) + " options, picked " + str(picked))
	var boss = PokemonGenerator.MakeMobilePokemon(raidSpawns[picked])
	
	#Raid upgrades. However it is we picked the boss, we need to upgrade them some.
	#No matter what, their IVs are good
	boss.IVs[0] = randi_range(12,15)
	boss.IVs[1] = randi_range(12,15)
	boss.IVs[2] = randi_range(12,15)
	
	#Their level gets set to a high value. This might vary based on which thing we're fighting.
	#Remember, my level 50 is level 25 by existing player's expectations. Not actually that hard to beat.
	boss.level = 50 #Was 70, but you'll need too long to get pokemon that strong.
	
	#Update this so the fight goes correctly
	boss.combatPower = PokemonHelpers.GetCombatPower(boss)
	raidScene.boss = boss
	
	#this will get replaced with the 6 entries in the displays, auto-picked initially.
	raidScene.party = [{}, {}, {}, {}, {}, {}]
	$popup.add_child(raidScene)

func HideAlreadyWon():
	$boxAlreadyWon.position.x = 600

#func DebugSpawnPokemon(key):
	#var p = PokemonGenerator.MakeMobilePokemon(key)
	#GameGlobals.pokemon[p.id] = p

func ShowHelp():
	Dialogic.start('HelpTimeline')
