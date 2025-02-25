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
	results.distanceWalked = 0 # Every 1 in this adds 1% combat power.
	#NEW: ensure these fields are checked for and added when processing data from V1 to V2.
	results.distanceTravelled = 0 #buddys grant candy every so many.
	results.caughtSpeed = 0 #This is set to the current speed value if the player wins
	results.isEvent = false #if this pokemon was from a weekly event, versus a wild spawn
	results.location = PraxisCore.currentPlusCode.substr(0,8)
	results.signed = ""
	results.publicKey = ""
	#This must be last, since speed affects it
	results.combatPower = PokemonHelpers.GetCombatPower(results) #saved as a quick reference
	
	#This should now be enough to save to a file, or to hydrate for combat.
	return results
	
static func SignPokemon(pokemonData):
	#Creates the signature data for an entry.
	var certs = UserCerts.new()
	var tempCert = certs.MakeCert(256)
	var publicKey = tempCert.save_to_string(true)
	var signingData = pokemonData.id + ",".join(pokemonData.moveNames) + str(pokemonData.caughtSpeed) + pokemonData.location
	pokemonData.signed = certs.Sign(tempCert, signingData)
	
static func ValidatePokemon(pokemonData):
	var passedChecked = 0
	#Take the pokemon data, put in all the values to sign, and validate that they line up
	#Is this signature legit?
	var signData = ""
	var signatureValid = UserCerts.new().Verify(pokemonData.publicKey, signData, pokemonData.signed)
	#does the spawn time time in the ID exist after the game was published?
	#Does this pokemon actually spawn where it says? (Raid bosses and event pokemon need a separate check)
	#Does this pokemon have moves it is allowed to learn?
	#Do all the places exist that it claims do? (This may not be doable on all servers)
	# -- but it can just check the nametables per cell6, since thats all the more it tracks.
