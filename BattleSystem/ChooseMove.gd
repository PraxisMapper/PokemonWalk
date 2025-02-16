extends RefCounted
class_name ChooseMove

#Handles AI picking attacks in various ways. These may be determined by values
#on the attacker, or as a value from the player.

#Requires being set from outside.
var battleState = {}
var moveEffects = {}

#TODO: may need to move targets out of functions so it can be set multiple places in either order.
func ChooseMove(pokemon):
	#TODO: select which AI criteria to use based on setting/personality, filter moves by PP/implementation.
	#TODO: if user wants to pick moves, provide screen to do that (or is that check elsewhere?)
	#Also requires targets
	#var moveData = ChooseMove_Random(pokemon) # Temp commented out while testing damage ai
	var moveData = ChooseMove_Damage(pokemon)
	#FOR NOW. TODO: enable huge silly fights
	#TODO: ensure this uses teams to determine targets, or at least checks HP > 0
	var targets = ChooseTargets(pokemon, moveData)
	#var targets = ChooseTarget1V1(pokemon, moveData)
	return {moveData = moveData, dealer = pokemon, targets = targets}

#pokemon is an index.
func ChooseTargets(pokemon, moveData):
	#The only thing I have for now. TODO: fix for double battles by checking for size of each team.
	if battleState.teams.size() == 2 and battleState.teams[0].size() == 1 and battleState.teams[1].size() == 1:
		return ChooseTarget1V1(pokemon, moveData)
	
	#A more thorough, multi-team target selection option.
	var targets = []
	var combatantId = battleState.combatants.find(pokemon)
	var userTeamId = battleState.teams.find(combatantId)
	var userTeam = battleState.teams.filter(func(team): return team.has(userTeamId))
	match(moveData.target):
		#No target?
		"None":
			pass
		#Single targets:
		"User":
			targets.push_back(pokemon)
		"NearOther":
			pass
		"Other":
			pass
		"RandomNearFoe":
			pass
		"NearAlly":
			pass
		"UserOrNearAlly":
			pass
		"NearFoe":
			pass
		#Multi-target
		"AllNearFoes":
			pass
		"FoeSide":
			pass
		"AllNearOthers":
			pass
		"BothSides":
			pass
		"UserAndAllies":
			pass
		"UserSide":
			pass
		"AllBattlers":
			pass
		"AllAllies":
			pass
	return targets
	
#The default, 1v1 battle format simplifies down target options.
func ChooseTarget1V1(pokemon, moveData):
	var targets = []
	var combatantId = pokemon #battleState.combatants.find(pokemon) #Same as team Id in 1v1
	var otherId = 0
	if combatantId == 0:
		otherId = 1
	match moveData.target:
		"User", "NearAlly", "UserOrNearAlly", "AllAllies", "UserSide", "UserAndAllies":
			targets.push_back(pokemon)
		"NearOther", "Other", "RandomNearFoe", "NearFoe", "FoeSide":
			targets.push_back(otherId)
		"AllBattlers", "BothSides":
			targets.push_back(0)
			targets.push_back(1)
	return targets
	

func Filter_Unimplemented(moveList):
	var movesGood = []
	for m in moveList:
		var move = GameGlobals.baseData.moves[m]
		if move.name != "Unimplemented":
			movesGood.push_back(move)
	return movesGood

func ChooseMove_Random(pokemonId):
	var pokemon = battleState.GetPokemonData(pokemonId)
	var moves = Filter_Unimplemented(pokemon.knownMoves)
	if moves.size() > 0:
		return moves.pick_random()
	return GameGlobals.baseData.moves["TACKLE"] # Opting to make this the default over STRUGGLE now.
	
func ChooseMove_Damage(pokemonId):
	#TODO: Does this need reworked for larger battles? Right now I am assuming 1v1.
	var pokemon = battleState.GetPokemonData(pokemonId)
	var myteam = battleState.GetPokemonTeam(pokemonId)
	var opposingTeam = 1 if myteam == 0 else 0
	var target = battleState.teams[opposingTeam]
	var moves = Filter_Unimplemented(pokemon.knownMoves)
	if moves.size() > 0:
		var move_weights = Array()
		var best_move_index = -1
		var best_move_value = -1
		for move in moves.size():
			move_weights.push_back(0)
			var value = 0
			var thismove = moves[move]
			#Now, to evaluate the worth of this move based on damage only.
			if thismove.power == null or int(thismove.power) == 0: #No damage, no worth here.
				move_weights[move] = 0
				continue
			var typeCheck = moveEffects.CalcTypeEffectiveness(thismove.type, target)
			value = typeCheck * int(thismove.power)
			#print("Move " + thismove.key + " has value " + str(value))
			if value > best_move_value:
				best_move_value = value
				best_move_index = move
		return moves[best_move_index]
			
	return GameGlobals.baseData.moves["TACKLE"]

#SetTarget functions should return an index on the combatants list.
func SetTarget_Self(pokemon, battle):
	
	pass
