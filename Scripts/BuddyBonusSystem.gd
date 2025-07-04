extends RefCounted
class_name BuddyBonusSystem

static func RecalcBonus():
	pass
	#Intended to be run on a version upgrade to prove a value is legit, 
	#or to validate a remote pokemon
	
const candyDistanceMeters = 340.0 #~200 cells, ~2 minute of highway driving.
static func AddDistance(buddyKey, cell10s):
	var pokemon = GameGlobals.pokemon[buddyKey]
	print("Pokemon walked " + str(pokemon.distanceWalked) + " meters so far")
	var curCount = int(pokemon.distanceWalked / candyDistanceMeters)
	pokemon.distanceTravelled += PraxisCore.DistanceDegreesToMetersLat(PraxisCore.resolutionCell10)
	if (PraxisCore.last_location.speed < GameGlobals.speedLimit):
		pokemon.distanceWalked += PraxisCore.DistanceDegreesToMetersLat(PraxisCore.resolutionCell10)
	if int(pokemon.distanceTravelled / candyDistanceMeters) != curCount: #just crossed over the threshold
		print("Granting 1 candy")
		print("pre:" + str(GameGlobals.playerData.candyByFamily[pokemon.family]))
		if GameGlobals.playerData.candyByFamilycandyByFamily.has(pokemon.family):
			GameGlobals.playerData.candyByFamily[pokemon.family] += 1
		else:
			GameGlobals.playerData.candyByFamily[pokemon.family] = 1
		print("post:" + str(GameGlobals.playerData.candyByFamily[pokemon.family]))

static func UpdateBonus(buddyKey, placedata, currentPosition):
	#I want this function to do the least looping possible.
	if placedata == null:
		return
	var pokemon = GameGlobals.pokemon[buddyKey]
	var startingBoost = pokemon.buddyBoost
	for p in placedata:
		if p.category == "mapTiles":
			if Adapter.gameplayFullIds.has(str(int(p.typeId))):
				var add = true
				for bp in pokemon.buddyPlaces:
					if (bp.n == p.name):
						add = false
						break
				if add:
					pokemon.buddyBoost += 0.01
					pokemon.buddyPlaces.append({n = p.name, tid=p.typeId, at = currentPosition.substr(0,6)}) #at is for validation later.
		#Incomplete: We don't have cities in the minimized data, so we can't do this offline at all.
		#if p.category == "adminBoundsFilled":
	if startingBoost != pokemon.buddyBoost:
		pokemon.combatPower = PokemonHelpers.GetCombatPower(pokemon)
		GameGlobals.Save()
		GameGlobals.updateHeader.emit()
