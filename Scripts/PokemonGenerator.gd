extends Node
class_name PokemonGenerator

#For PoGo-style use
static func MakeMobilePokemon(key):
	var basePokeData = GameGlobals.baseData.pokemon[key]
	
	var results = {}
	results.key = key
	results.name = basePokeData.name
	results.family = basePokeData.family
	#CaughtBy can be determines from the first entry on id split by _
	results.id = OS.get_unique_id() + "_" + key + "_" + str(Time.get_unix_time_from_system())
	#Does species form matter, or is that part of the key?
	results.IVs = [randi_range(0, 15), randi_range(0, 15), randi_range(0, 15)]
	results.moveNames = [basePokeData.PoGoFastMoves.pick_random(), basePokeData.PoGoChargeMoves.pick_random()]
	results.level = min(60, randi_range(1, (GameGlobals.playerData.currentLevel + 5) * 2)) #1-12 boosts for new players.
	results.buddyPlaces = [] # {name, at} for each, to avoid duplicates
	results.buddyBoost = 0.0 #Increases the combat multiplier by visiting places.
	results.combatPower = PokemonHelpers.GetCombatPower(results) #saved as a quick reference
	results.distanceWalked = 0 #buddys grant candy every km.
	
	#This should now be enough to save to a file, or to hydrate for combat.
	return results
