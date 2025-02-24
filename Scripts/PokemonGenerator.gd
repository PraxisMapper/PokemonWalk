extends Node
class_name PokemonGenerator

#Or do i save the actual speed, and let the game/server decide on the results?
enum speedCaught{
	UNKNOWN = 0, #From Version 1, or data is not clear.
	WALK = 1, # Under 5.5 m/s (12 mph / 20kph). Chosen because this is the best marathon speed on record.
	DRIVE = 2
}
	

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
	#NEW: ensure these fields are checked for and added when processing data from V1 to V2.
	results.caughtSpeed = 0 #This is set to the current speed value if the player wins
	results.signed = ""
	results.publicKey = ""
	
	#This should now be enough to save to a file, or to hydrate for combat.
	return results
