extends Node2D

var pokemonData
var candyGrind = 0
var evoCost = 0

signal updateList #This should connect to the parent

func _ready() -> void:
	if pokemonData == null:
		return
	FillPage()

func FillPage():
	var baseData = GameGlobals.baseData.pokemon[pokemonData.key]
	$sc/c/lblName.text = pokemonData.name
	$sc/c/lblPower.text = str(pokemonData.combatPower) + " CP"
	
	$sc/c/txrPoke.texture = load(PokemonHelpers.GetPokemonFrontSprite(pokemonData.key, false, "M"))
	$sc/c/lblIVs.text = "IVs:\nATK " + str(pokemonData.IVs[0]) + " / DEF " + str(pokemonData.IVs[1]) + " / STA " + str(pokemonData.IVs[2])
	var candies = 0
	if (GameGlobals.playerData.candyByFamily.has(pokemonData.family)):
		candies = GameGlobals.playerData.candyByFamily[pokemonData.family]
	$sc/c/lblCandy.text = str(candies) + " Candies"
	$sc/c/lblLevel.text = "Level " + str(pokemonData.level)
	
	$sc/c/lblTypes.text = "Types: "
	for t in baseData.types:
		$sc/c/lblTypes.text += t + ", "
		
	$sc/c/lblBonuses.text = ""
	if pokemonData.caughtSpeed > GameGlobals.speedLimit:
		$sc/c/lblBonuses.text += str(int(-GameGlobals.speedBuff * 100)) + "% Drive-Catch,"
	elif pokemonData.caughtSpeed > 0:
		$sc/c/lblBonuses.text += str(int(GameGlobals.speedBuff * 100)) + "% Walk-Catch,"
	if pokemonData.buddyPlaces.size() > 0:
		$sc/c/lblBonuses.text += str(pokemonData.buddyPlaces.size()) + "% Places,"
	if pokemonData.distanceWalked > 1000:
		$sc/c/lblBonuses.text += str(int(pokemonData.distanceWalked * 0.001)) + "% Walking,"
	
	#Event pokemon might get a power tweak, but might not?
	#if (pokemonData.isEvent):
		#$sc/c/lblBonuses.text += 
	
	var places = "Places Visited: \n"
	for p in pokemonData.buddyPlaces:
		places += p.n + " (" + p.at +")\n"
	$sc/c/placesList/sc/lblPlaces.text = places
	
	var boostCost = PokemonHelpers.GetStardustUpgradeCost(pokemonData)
	$sc/c/btnBoost.text = "Level Up for " + str(boostCost) + " stardust"
	if GameGlobals.playerData.stardust < boostCost or pokemonData.level > (GameGlobals.playerData.currentLevel + 5) * 2:
		$sc/c/btnBoost.disabled = true
	
	$sc/c/moves/lblFastMove.text = "Fast Move: " + GameGlobals.baseData.pogoMoves[pokemonData.moveNames[0]].name
	$sc/c/moves/btnChangeFast.disabled = GameGlobals.playerData.currentCoins < 100
	
	$sc/c/moves/lblCharge1.text = "Charge Move: " + GameGlobals.baseData.pogoMoves[pokemonData.moveNames[1]].name
	$sc/c/moves/btnChangeCharge1.disabled = GameGlobals.playerData.currentCoins < 500
	
	$sc/c/moves/btnChangeCharge2.disabled = GameGlobals.playerData.currentCoins < 1000
	if (pokemonData.moveNames.size() == 3):
		$sc/c/moves/lblCharge2.text = "Charge Move: " + GameGlobals.baseData.pogoMoves[pokemonData.moveNames[2]].name
		$sc/c/moves/btnChangeCharge1.text = "Change (500 coins)"
	else:
		$sc/c/moves/lblCharge2.text = "2nd Charge locked"
		$sc/c/moves/btnChangeCharge2.text = "Unlock (1000 coins)"

	var family = GameGlobals.baseData.allFamilies[pokemonData.family]
	candyGrind = max(1, 1 + (family.find(pokemonData.key) * 2)) # 1/3/5
	
	#Handle form changes:
	#1: ALTERNATE means it's always in a specific form, and doesnt change per instance.
	#2: TRANSFORM means we should have a way to swap forms repeatedly, with coins.
	#3: MEGASTONE means it has a one-time or temporary transform, which we'll buy with candy.
	#No pokemon should have more than 1, so we can just check the first (for now, may change
	#if I add giant/dynamax ones)
	
	$sc/c/megastone.position.x = -599
	if baseData.otherForms != null and baseData.otherForms.size() > 0:
		#var formType = baseData.formType
		var keyCheck = baseData.key.split("_")[0] + "_" + baseData.otherForms[0]
		match GameGlobals.baseData.pokemon[keyCheck].formType:
			"ALTERNATE":
				pass #nothing to do for these.
			"TRANSFORM":
				#show transform toggle. This cycles, rather than presenting all options.
				$sc/c/btnTransform.visible = true
				$sc/c/btnTransform.disabled = (GameGlobals.playerData.currentCoins < 100)
			"MEGASTONE":
				#Show megastone options. There should only ever be 2 at max.
				if !baseData.key.contains("_"):# don't mega-evolve pokemon that already mega-evolved
					$sc/c/megastone.position.x = 45
					if baseData.otherForms.size() > 1:
						$sc/c/megastone/btnMega2.visible = true
					else:
						$sc/c/megastone/btnMega2.visible = false
					$sc/c/megastone/btnMega1.disabled = (!GameGlobals.playerData.candyByFamily.has(baseData.family) or GameGlobals.playerData.candyByFamily[baseData.family] < 100)
					$sc/c/megastone/btnMega2.disabled = (!GameGlobals.playerData.candyByFamily.has(baseData.family) or GameGlobals.playerData.candyByFamily[baseData.family] < 100)

	if (baseData.evolutions != null and baseData.evolutions.length() > 0):
		var evos = baseData.evolutions.split(",")
		#Now, evos are 3 pieces. its KEY,process,requirement. 
		#EX: IVYSAUR,Level,16 or FLAREON,Item,FireStone. I MOSTLY only care that they exist here.
		
		$sc/c/btnEvolve.visible = true
		evoCost = 0
		
		if family.size() == 2:
			if family[0] == pokemonData.key.split("_")[0]:
				evoCost = 50
			else:
				$sc/c/btnEvolve.visible = false #we are the max evolution
				candyGrind = 3
		elif family.size() == 3: #TODO: this may need to adjust for forms.
			if family[0] == pokemonData.key.split("_")[0]:
				evoCost = 25
			elif family[1] == pokemonData.key.split("_")[0]:
				evoCost = 100
			elif family[2] == pokemonData.key.split("_")[0]:
				$sc/c/btnEvolve.visible = false #we are the max evolution
		else:
			pass
			#TODO: Special cases where there's more options in the family line.
			if pokemonData.key == "EEVEE" || family[0] == "APPLIN":
				evoCost = 50
			
		$sc/c/btnEvolve.text = "Evolve for " + str(evoCost) + " Candies"
	else: #if baseData.formType != "TRANSFORM":
		$sc/c/btnEvolve.visible = false
	
	if (!GameGlobals.playerData.candyByFamily.has(pokemonData.family) or 
		GameGlobals.playerData.candyByFamily[pokemonData.family] < evoCost
	):
		$sc/c/btnEvolve.disabled = true
	
	$sc/c/btnTransfer.text = "Transfer to get " + str(candyGrind) + " Candies"
	if GameGlobals.playerData.buddy == pokemonData.id:
		$sc/c/btnTransfer.disabled = true
	
	#debugging stuff
	#$sc/c/placesList/sc/lblPlaces.text += "CaughtSpeed:" + str(pokemonData.caughtSpeed) + "\ndistanceWalked:" + str(pokemonData.distanceWalked) + "\ndistanceTravelled:" + str(pokemonData.distanceTravelled)

	#this part is here to handle when we push a button to update that display.
	GameGlobals.updateHeader.emit()

func Boost():
	if pokemonData.level > (GameGlobals.playerData.currentLevel + 5) * 2:
		return
	
	GameGlobals.playerData.stardust -= PokemonHelpers.GetStardustUpgradeCost(pokemonData)
	pokemonData.level += 1
	pokemonData.combatPower = PokemonHelpers.GetCombatPower(pokemonData)
	
	GameGlobals.Save()
	updateList.emit()
	FillPage()

func ChangeFastMove():
	GameGlobals.playerData.currentCoins -= 100
	var baseData = GameGlobals.baseData.pokemon[pokemonData.key]
	var fastMoves = baseData.PoGoFastMoves.duplicate()
	fastMoves.erase(pokemonData.moveNames[0])
	
	var newMove = fastMoves.pick_random()
	pokemonData.moveNames[0] = newMove
	GameGlobals.Save()
	FillPage()
	
func ChangeCharge1():
	GameGlobals.playerData.currentCoins -= 500
	var baseData = GameGlobals.baseData.pokemon[pokemonData.key]
	var chargeMoves = baseData.PoGoChargeMoves.duplicate()
	chargeMoves.erase(pokemonData.moveNames[1])
	if (pokemonData.moveNames.size() == 3):
		chargeMoves.erase(pokemonData.moveNames[2])
	
	var newMove = chargeMoves.pick_random()
	pokemonData.moveNames[1] = newMove
	GameGlobals.Save()
	FillPage()
	
func UnlockOrChangeCharge2():
	GameGlobals.playerData.currentCoins -= 1000
	var baseData = GameGlobals.baseData.pokemon[pokemonData.key]
	var chargeMoves = baseData.PoGoChargeMoves.duplicate()
	chargeMoves.erase(pokemonData.moveNames[1])
	if (pokemonData.moveNames.size() == 3):
		chargeMoves.erase(pokemonData.moveNames[2])
	else:
		pokemonData.moveNames.append("")
	
	var newMove = chargeMoves.pick_random()
	pokemonData.moveNames[2] = newMove
	GameGlobals.Save()
	FillPage()
	
func Evolve():
	#MOST POKEMON: pick the next entry in the evolution chain, update key and id
	#SOME POKEMON: if forms exist, pick the entry with the same form as the current one.
	#A FEW POKEMON: specific conditions apply on which evolution is picked
	#EEVEE: a bunch of possible things. For now, just pick 1 at random and fix/change/allow-force 
	#options later.
	
	#sanity check
	if (GameGlobals.baseData.pokemon[pokemonData.key].evolutions == null || 
		GameGlobals.baseData.pokemon[pokemonData.key].evolutions.length() == 0 ||
		GameGlobals.baseData.pokemon[pokemonData.key].evolutions.contains("None")):
		return
	
	var baseData = GameGlobals.baseData.pokemon[pokemonData.key]
	var oldId = pokemonData.id
	var evos = baseData.evolutions.split(",")
	var options = evos.size() / 3
	var nextstage = evos[randi_range(0, options - 1) * 3]
	#Now, evos are 3 pieces. its KEY,process,requirement. 
	#EX: IVYSAUR,Level,16 or FLAREON,Item,FireStone. I MOSTLY only care that they exist here.
	
	if (pokemonData.key.contains("_") and baseData.formType == "ALTERNATE"):
		#Check if the target creature has a matching form, if not evolve to it.
		var targetData = GameGlobals.baseData.pokemon[nextstage]
		if targetData.otherForms.size() > 0:
			var nextstageForm = nextstage + "_" + pokemonData.key.split("_")[1]
			if GameGlobals.baseData.pokemon.has(nextstageForm):
				nextstage = nextstageForm
			#else: #BASCULIN_2 only, evolves to its listed (shared) form
				#print("WHOOPS! Pokemon " + pokemonData.key + " doesn't have a form to evole to!")
		#else:
			#print("no equal form for evolution, taking listed one for " + pokemonData.key)

	pokemonData.key = nextstage
	#This should be unnecessary, the IDs just a unique ID and doesnt need to update with it.
	#GameGlobals.pokemon.erase(oldId)
	#GameGlobals.pokemon[pokemonData.id] = pokemonData
	#TODO: dont change name if it has a nickname.
	pokemonData.name = GameGlobals.baseData.pokemon[pokemonData.key].name
	
	if pokemonData.key == "VIVILLON":
		var randform = randi_range(0, GameGlobals.baseData.pokemon[pokemonData.key].otherForms.size() -1)
		pokemonData.key = "VIVILLON_" + GameGlobals.baseData.pokemon[pokemonData.key].otherForms[randform]
	
	pokemonData.combatPower = PokemonHelpers.GetCombatPower(pokemonData)
	GameGlobals.playerData.candyByFamily[pokemonData.family] -= evoCost
	GameGlobals.Save()
	updateList.emit()
	FillPage()
	
func MegaEvolve1():
	MegaEvolve(0)

func MegaEvolve2():
	MegaEvolve(1)
	
func MegaEvolve(formIndex):
	var baseData = GameGlobals.baseData.pokemon[pokemonData.key]
	var newKey = pokemonData.key.split("_")[0] + "_" + baseData.otherForms[formIndex]
	pokemonData.key = newKey
	pokemonData.combatPower = PokemonHelpers.GetCombatPower(pokemonData)
	GameGlobals.playerData.candyByFamily[pokemonData.family] -= 100
	GameGlobals.Save()
	updateList.emit()
	FillPage()

func Transform():
	#Figure out which form we are, and pick the next one.
	var thisForm = pokemonData.key
	if thisForm.contains("_"):
		thisForm = pokemonData.key.split("_")[1]
	
	if thisForm == GameGlobals.baseData.pokemon[pokemonData.key].otherForms[GameGlobals.baseData.pokemon[pokemonData.key].otherForms.size() - 1]:
		pokemonData.key = pokemonData.key.split("_")[0]
	else:
		print(str(GameGlobals.baseData.pokemon[pokemonData.key].otherForms))
		var idx = GameGlobals.baseData.pokemon[pokemonData.key].otherForms.find(str(thisForm))
		if idx == GameGlobals.baseData.pokemon[pokemonData.key].otherForms.size() - 1:
			idx = 0
		else:
			idx += 1
	
		var newKey = pokemonData.key.split("_")[0] + "_" + GameGlobals.baseData.pokemon[pokemonData.key].otherForms[idx]
		pokemonData.key = newKey
		
	GameGlobals.playerData.currentCoins -= 100
	GameGlobals.Save()
	updateList.emit()
	FillPage()
	
func Transfer():
	if (GameGlobals.playerData.candyByFamily.has(pokemonData.family)):
		GameGlobals.playerData.candyByFamily[pokemonData.family] += candyGrind
	else:
		GameGlobals.playerData.candyByFamily[pokemonData.family] = candyGrind
	GameGlobals.pokemon.erase(pokemonData.id)
	GameGlobals.playerData.pokemonTransferred += 1
	GameGlobals.Save()
	updateList.emit()
	Close()

func Close():
	queue_free()
	
func DebugEvolveAll():
	for p in GameGlobals.baseData.pokemon:
		#print("Evolving " + p)
		pokemonData = PokemonGenerator.MakeMobilePokemon(p)
		Evolve()
	print("all pokemon evolve done")
