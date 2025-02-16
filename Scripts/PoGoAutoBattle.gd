extends RefCounted
class_name PoGoAutoBattle

#The script that fires off to handle a battle when we walked into a space

static func Battle1v1(player, computer):
	pass
	var battle = PoGoCombat.new()
	#Get and hydrate the player's buddy
	var combatPlayer = battle.HydrateGoPokemon(player)
	#get and hydrate a wild pokemon for this area and time
	var combatOpponnent = battle.HydrateGoPokemon(computer)
	
	#fight, handle results.
	battle.poke1 = combatPlayer
	battle.poke2 = combatOpponnent
	var results = battle.RunBattle()
	print("autofight results: " + str(results))
	
	
	return results
