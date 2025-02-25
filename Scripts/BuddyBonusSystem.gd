extends RefCounted
class_name BuddyBonusSystem

static var grantBoostmapTiles = ["park", "nature_reserve", "cemetery", "trail", "library", "museum", "historical",
"theatre", "concertHall", "artsCenter", "planetarium", "artsCulture", "aquarium", "artwork", "attraction", 
"gallery", "themePark", "viewPoint", "zoo", "namedTrail"]
#Visiting these is a secondary boost. category == "adminBoundsFilled". Or will when I get to it.
#static var cityBoost = ["city"]

static func RecalcBonus():
	pass
	#Intended to be run on a version upgrade to prove a value is legit, 
	#or to validate a remote pokemon
	
const candyDistanceMeters = 340.0 #~200 cells, ~2 minute of highway driving.
static func AddDistance(buddyKey, cell10s):
	var pokemon = GameGlobals.pokemon[buddyKey]
	var curCount = int(pokemon.distanceWalked / candyDistanceMeters)
	pokemon.distanceTravelled += PraxisCore.DistanceDegreesToMetersLat(PraxisCore.resolutionCell10)
	if (PraxisCore.last_location.speed < GameGlobals.speedLimit):
		pokemon.distanceWalked += PraxisCore.DistanceDegreesToMetersLat(PraxisCore.resolutionCell10)
	if int(pokemon.distanceTravelled / candyDistanceMeters) != curCount: #just crossed over the threshold
		if GameGlobals.playerData.candyByFamily.has(pokemon.family):
			GameGlobals.playerData.candyByFamily[pokemon.family] += 1
		else:
			GameGlobals.playerData.candyByFamily[pokemon.family] = 1

static func UpdateBonus(buddyKey, placedata, currentPosition):
	#I want this function to do the least looping possible.
	if placedata == null:
		return
	var pokemon = GameGlobals.pokemon[buddyKey]
	var startingBoost = pokemon.buddyBoost
	for p in placedata:
		if p.category == "mapTiles":
			if Adapter.gameplayFullIds.has(str(p.typeId)):
				var add = true
				for bp in pokemon.buddyPlaces:
					if (bp.n == p.name):
						add = false
						break
				if add:
					pokemon.buddyBoost += 0.01
					pokemon.buddyPlaces.append({n = p.name, tid=p.typeId, at = currentPosition.substr(0,6)}) #at is for validation later.
				break
		#Incomplete: We don't have cities in the minimized data, so we can't do this offline at all.
		#if p.category == "adminBoundsFilled":
	if startingBoost != pokemon.buddyBoost:
		pokemon.combatPower = PokemonHelpers.GetCombatPower(pokemon)
		GameGlobals.Save()
		GameGlobals.updateHeader.emit()
