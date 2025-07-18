extends Node2D
#The main walk-around page. Other pages are drawn in the middle.

var spawnInfoWindowPL = preload("res://Components/ShowSpawnInfo.tscn")
var inventoryScreenPL = preload("res://Scenes/PoGoInventory.tscn")
var infoScreenPL = preload("res://Components/PoGoFullDisplay.tscn")

func _ready() -> void:
	$ScrollingCenteredMap/TileDrawerQueued/Banner.position = Vector2(182 + 96 + 170 ,237 + 268 + 230 + 35)
	$ScrollingCenteredMap/TileDrawerQueued/Banner.visible = false

	PraxisCore.plusCode_changed.connect(plusCodeChanged)
	$recentTracker.newRecent.connect(recentCellVisit)
	$recentTracker.timeDiffSeconds = 60 * 60 #Resets every hour, not day
	$recentTracker.RemoveOld()
	plusCodeChanged(PraxisCore.currentPlusCode, "")
	
	$header/PoGoMiniDisplay.leftClicked.connect(BuddyInfo)
	$header/PoGoMiniDisplay.rightClicked.connect(ChangeBuddy) #This seems to have quit working in Godot 4.4?
	
	GameGlobals.updateData.connect(ForceRefresh)
	
	if GameGlobals.currentSpawnTable.is_empty():
		GameGlobals.currentSpawnTable = SpawnLogic.SpawnTable(PraxisCore.currentPlusCode.substr(0,8))
	
	GameGlobals.updateHeader.connect(UpdateHeader)
	UpdateHeader()

var debug = false
func _process(delta: float) -> void:
	$playerArrow.rotation = PraxisCore.GetCompassHeading()
	if debug:
		DebugUpdate() #for tracking down stuff on-device sometimes

func UpdateHeader():
	$header/lblCoins.text = "Coins: " + str(int(GameGlobals.playerData.currentCoins)) + " Stardust: " +str(int(GameGlobals.playerData.stardust))
	
	#Balance notes: when this is * 1000, it takes way too long for your player level to increase.
	#Reduced it to 100, so it should be 10x faster. I expect this is a reasonable amount.
	var prevLevel = ((GameGlobals.playerData.currentLevel - 1) ** 2 * 100)
	var thisLevel = ((GameGlobals.playerData.currentLevel) ** 2 * 100) - prevLevel
	$header/lblXp.text = "Level " + str(int(GameGlobals.playerData.currentLevel)) + " XP: " + str(int(GameGlobals.playerData.currentXp - prevLevel)) + "/" + str(int(thisLevel))
	
	if (GameGlobals.playerData.unlockedSpawnData.has(PraxisCore.currentPlusCode.substr(0,8))):
		$footer/btnSpawns.text  = "View Spawn Info"
	else:
		$footer/btnSpawns.text = "Learn Spawns: 100 Coins"
	
	#this hung once opening the game, lets see if this is a weird race condition
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
	MapSave("setting buddy")
	#GameGlobals.Save()
	clearPopup()

func recentCellVisit(cell10):
	var speedMul = GameGlobals.walkingMultiplier if PraxisCore.last_location.speed < GameGlobals.speedLimit else  1
	var newCoins = randi_range(3,8) + int(GameGlobals.playerData.currentLevel / 10) * speedMul
	GameGlobals.playerData.currentCoins += newCoins
	var eventResults = randi_range(1, 6) # 1-4: coins: 5-6: combat
	if eventResults <= 4:
		$walkNotice/txrOpponent.visible = false
		$walkNotice/lblMessage.text = "You got " + str(newCoins) + " coins"
		#print(GameGlobals.playerData.soundEnabled)
		if GameGlobals.playerData.soundEnabled:
			$AudioStreamPlayer.stream = SoundSystem.coinSound
			$AudioStreamPlayer.play()
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
		if (results == 1): #victory
			if GameGlobals.playerData.autoCatch and GameGlobals.playerData.currentCoins >= 10:
				if !opponent.isShiny:
					GameGlobals.playerData.shinyPityCount += 1
					#print(str(GameGlobals.playerData.shinyPityCount))
					if GameGlobals.playerData.shinyPityCount == 750: #everyone loves to be ahead of the curve.
						opponent.isShiny = true
						GameGlobals.playerData.shinyPityCount == 0
				else:
					print("wild shiny!")
				opponent.caughtSpeed = PraxisCore.last_location.speed
				opponent.combatPower = PokemonHelpers.GetCombatPower(opponent)
				if GameGlobals.playerData.soundEnabled:
					if opponent.isShiny:
						$AudioStreamPlayer.stream = SoundSystem.secretSound
					else:
						$AudioStreamPlayer.stream = SoundSystem.catchSound
					$AudioStreamPlayer.play()
				GameGlobals.playerData.currentCoins -= 10
				GameGlobals.pokemon[opponent.id] = opponent
				if GameGlobals.playerData.pokedex.find(opponent.key) == -1:
					GameGlobals.playerData.pokedex.append(opponent.key)
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
			xp *= speedMul
			stardust *= speedMul
			candy *= speedMul

			GameGlobals.GrantPlayerXP(xp)
			GameGlobals.playerData.stardust += stardust
			
			if (GameGlobals.playerData.candyByFamily.has(opponent.family)):
				GameGlobals.playerData.candyByFamily[opponent.family] += candy
			else:
				GameGlobals.playerData.candyByFamily[opponent.family] = candy
		elif results == 2:
			$walkNotice/lblMessage.text = "Earned " + str(newCoins) + " and you lost to a " + opponent.name
	
	$walkNotice.visible = true
	$walkNotice/tmrHide.start()
	#GameGlobals.Save()
	MapSave("entering Cell10")

func HideWalkNotice():
	$walkNotice.visible = false

func UpdateRaidButton(cell8):
	if (GameGlobals.playerData.dailyClearedRaids.has(cell8)):
		var currentString = Time.get_datetime_dict_from_system(true)
		var today = Time.get_unix_time_from_datetime_string(str(currentString.year) + "-" + str(currentString.month) + "-" + str(currentString.day))
		var tomorrow = today + 86400
		var unlockTime =  tomorrow - Time.get_unix_time_from_system()
		
		$footer/btnRaid.text = "Resets in " + str(int(unlockTime) / 3600) + ":" + str((int(unlockTime) % 3600) / 60)
		$footer/btnRaid.disabled = true
	else:
		$footer/btnRaid.text = "Fight Local Raid"
		$footer/btnRaid.disabled = false

func plusCodeChanged(current, old):
	var workthread = Thread.new()
	var workStarted = false
	var curCode = PlusCodes.RemovePlus(current)
	var oldCode = PlusCodes.RemovePlus(old)
	if (curCode.substr(0,10) != oldCode.substr(0,10)): #dont do this update if we did a Cell11 move.
		#print("starting work thread")
		workthread.start(CheckPlaces.bind(curCode))
		workStarted = true
	
	$lblSpeed.text = "Speed: " + str(PraxisCore.last_location.speed)
	
	$header/lblLocation.text = "Location: " + (current if GameGlobals.playerData.showLocation else "Hidden")
	#Quick check to enable raids, needs done before raid status is checked.
	CheckRaidReset()
	
	#check for the spawn table
	var cell8 = current.substr(0,8)
	UpdateRaidButton(cell8) # moved here so it unlocks if you're currently in it.
	if cell8 != old.substr(0,8):
		if GameGlobals.playerData.soundEnabled and !$footer/btnRaid.disabled:
			$AudioStreamPlayer.stream = SoundSystem.raidSound
			$AudioStreamPlayer.play()
		#rebuild spawn table.
		GameGlobals.currentSpawnTable = SpawnLogic.SpawnTable(cell8)

	var baseCell = current.substr(0,6)
	var cellsToLoad = PlusCodes.GetNearbyCells(baseCell, 1)
	for c2l in cellsToLoad:
		if !PraxisOfflineData.OfflineDataExists(c2l):
			$GetFile.skipTween = true
			#print("Getting new map file")
			$GetFile.AddToQueue(c2l)
	$ScrollingCenteredMap.plusCode_changed(PraxisCore.currentPlusCode, PraxisCore.lastPlusCode)
	UpdateHeader()
	if workStarted:
		#print("waiting for work thread")
		workthread.wait_to_finish()

func SpawnInfo():
	if (GameGlobals.playerData.unlockedSpawnData.has(PraxisCore.currentPlusCode.substr(0,8))):
		clearPopup()
		var info = spawnInfoWindowPL.instantiate()
		$popup.add_child(info)
	elif GameGlobals.playerData.currentCoins >= 100:
		GameGlobals.playerData.currentCoins -= 100
		GameGlobals.playerData.unlockedSpawnData.append(PraxisCore.currentPlusCode.substr(0,8))
		#GameGlobals.Save()
		MapSave("Unlocking spawn data")
		UpdateHeader()

func clearPopup():
	for c in $popup.get_children():
		c.queue_free()

func CheckPlaces(current):
	var start = Time.get_unix_time_from_system()
	var text = "Places:"
	var places = await PraxisOfflineData.GetPlacesPresent(current)
	if places != null:
		for place in places:
			if place.category != "adminBoundsFilled" and !text.contains(place.name):
				text += place.name + ', '
		BuddyBonusSystem.UpdateBonus(GameGlobals.playerData.buddy, places, current)
	BuddyBonusSystem.AddDistance(GameGlobals.playerData.buddy, 1) #add 1 cell to our distance walked.
	var elapsed = Time.get_unix_time_from_system() - start
	#print("CheckPlaces ran in " + str(elapsed))
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
	if GameGlobals.playerData.raidsLastCleared <= today - 86400: #is last cleared from midnight the day before
		var tomorrow = today + 86400
		GameGlobals.playerData.dailyClearedRaids.clear()
		GameGlobals.playerData.raidsLastCleared = today
		#GameGlobals.Save()
		MapSave("Resetting raid data")

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
	#print("total of " + str(raidSpawns.size()) + " options, picked " + str(picked))
	var boss = PokemonGenerator.MakeMobilePokemon(SpawnLogic.PickRaidBoss(PraxisCore.currentPlusCode.substr(0,8)))
	
	#Raid upgrades. However it is we picked the boss, we need to upgrade them some.
	#No matter what, their IVs are good
	boss.IVs[0] = randi_range(12,15)
	boss.IVs[1] = randi_range(12,15)
	boss.IVs[2] = randi_range(12,15)
	
	#Their level gets set to a high value. This might vary based on which thing we're fighting.
	#Remember, my level 50 is level 25 by existing player's expectations. Not actually that hard to beat.
	
	boss.level = max(50, rngLocal.randi_range(1, GameGlobals.playerData.currentLevel * 3 + 5)) #Player Level 15 is where this starts increasing
	#Update this so the fight goes correctly
	boss.combatPower = PokemonHelpers.GetCombatPower(boss)
	raidScene.boss = boss
	
	#this will get replaced with the 6 entries in the displays, auto-picked initially.
	raidScene.party = [{}, {}, {}, {}, {}, {}]
	$popup.add_child(raidScene)

func HideAlreadyWon():
	$boxAlreadyWon.position.x = 600

func DebugSpawnPokemon(key):
	var p = PokemonGenerator.MakeMobilePokemon(key)
	GameGlobals.pokemon[p.id] = p
	GameGlobals.playerData.candyByFamily[p.family] = 300

func ShowHelp():
	Dialogic.start('HelpTimeline')

func ShowOptions():
	var optionScene = preload("res://Scenes/Options.tscn").instantiate()
	clearPopup()
	$popup.add_child(optionScene)

func ShowPokedex():
	var dexScene = preload("res://Scenes/Pokedex.tscn").instantiate()
	clearPopup()
	$popup.add_child(dexScene)
	
func ForceRefresh():
	print("Forcing refresh")
	$ScrollingCenteredMap.RefreshTiles(PraxisCore.currentPlusCode)

func MapSave(where = "unknown"):
	var success = GameGlobals.Save()
	if success == false:
		#Alert me! I want to know why this failed to save.
		$debugpanel.position = Vector2(40, 500)
		$debugpanel/lblD.text = "Saving failed, your game data may be in a corrupted state. Failed at: " + where
		

func DebugUpdate():
	if !debug:
		return
	#var pokemon = GameGlobals.pokemon[GameGlobals.playerData.buddy]
	#var candies = GameGlobals.playerData.candyByFamily[pokemon.family]
	#$debugpanel/lblD.text = "Buddy Candies: " + str(candies) 
	#var distT = pokemon.distanceTravelled
	#$debugpanel/lblD.text += "\nTravel Dist: " + str(distT) 
