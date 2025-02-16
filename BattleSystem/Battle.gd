extends RefCounted
class_name Battle

#TODO list next:
# Implement reserves, so multiple pokemon can come in after defeat and get XP
# Implement round log, so i can see stuff.

#V2 of the battle system. V1 is old, original attempt.

#Handles all the data about the battle going on. Each pokemon on both teams,
#environmental and weather effects, party effects, etc.

#Remember, this handles all the stuff that can occur in battle, but we will 
#be executing the loop in a step above this. Multiple scenes might use this in different ways
#so stuff like 'pick moves' and 'execute' moves gets called by those, not auto-chained here.

#So other scenes should create this, and call functions in it to set up the state, then they
#can check for conditions.


#TODO: split stuff out into sub-scripts to reference.
var chooseMove = ChooseMove.new()
var moveEffects = MoveEffects.new()
#TODO: enable infinite-sized battles (uncap active team size, allow multiple teams)
#TODO: support fusion pokemon (all types, both abilities, averaged stats + 10%) - hydrated only

#The battle logic. Needs to do a lot of things here.
#This step assumes we have the moves provided by all creatures and are ready to process them.
#First is move order and priority
#second is moves occurring and doing their effects.
#this is conditions and triggers at all their steps.
#Then going back to waiting for moves.

enum STATS {HP, ATK, DEF, SPATK, SPDEF, SPD, ACC, EVA}

enum AbilityGroups {NONE, POST_BATTLE_INIT, PRE_ATTACK, PRE_DEFEND, POST_ATTACK, POST_DEFEND, POST_KNOCKOUT, POST_VICTORY, 
					POST_SUMMON, PRE_SWITCH_OUT, PRE_STAT_CANGE, PRE_SET_STATUS, PRE_APPLY_BATTLER_TAG,
					PRE_WEATHER, POST_WEATHER_CHANGE, POST_WEATHER_LAPSE, POST_TERRAIN_CHANGE, POST_TURN,
					POST_BIOME_CHANGE, POST_BATTLE, POST_FAINT}

#var battle = {
#var team1 = [] #player. old.
#var team2  = [] #enemy, usually NPCs. old
#var team1Flags = {} #whole-side effects like Light Screen. ARena? old.
#var team2Flags = {} #old

var battleOver = false
var combatants = [] #all pokemon involved, raw indexes. new
# teams is the active combatants, all valid targets. For the whole player/trainer/whatever collection
# that can be swapped in, thats reserves.
var teams = [] # Array of arrays, possibly a dict with side-specific statuses, new
var teamFlags = {} #array of array. new.
var reserves = [] # array of arrays, each corresponds by index to the team to swap in when needed
var battleFlags = {} # weather and such, Arena now?
var arena = Arena.new()
	
#TODO: this gets used for stuff that's probably conditional for Ai that should be used occasionally.
#EX: Trick Room, Light Screen, weather, etc.
var activeTriggers = {} #Ability/Move/etc. special effects by grou.
var roundLog = [] # A list of stuff that happened this round that might be worth reporting.
#TODO: implement this log, possibly for special effects or animations or such.

#This is the data we use to track which move is being or will be executed.
var move_entry = {
	move = {}, #actual move data
	user = {}, #which pokemon is doing this
	target = [], #which pokemon are getting hit with this. Re-calc on execute if invalid.
	speed = 0 # user speed for reference
}

var round_moves = [] #used to hold what they want to do
#var move_queue = [] #the actual order moves occur in. round_moves just gets sorted now.

func Initalize():
	chooseMove.battleState = self
	moveEffects.battleState = self
	chooseMove.moveEffects = moveEffects

func GetPokemonData(index):
	return combatants[index]

func GetPokemonIndex(pokemon):
	return combatants.find(pokemon)

func GetPokemonTeam(index):
	for t in teams:
		var idx = t.find(index)
		if idx > -1:
			return teams.find(t)
	return -1

func Ready():
	pass
	
func PreRound():
	#If a combat team is missing a member, fill it in with the next reserve with HP.
	for t in teams.size():
		if teams[t].size() == 0:
			for r in reserves[t]:
				var p = combatants[r]
				if (p.hp > 0):
					teams[t].push_back(r)
					continue
	
	
func RunRound():
	for m in round_moves:
		DoMove(m)
	round_moves.clear()
	
func AutoPickAll(battle):
	for t in teams:
		for p in t:
			round_moves.push_back(chooseMove.ChooseMove(p))

func DoMove(move):
	#movedata, dealer, targets
	var p = GetPokemonData(move.dealer)
	print(p.name + " has " + str(p.hp) + "HP")
	if p.hp > 0:
		moveEffects.DoMove(move.moveData, move.dealer, move.targets)
		#now check for KO
	else:
		print(p.name + " can't attack, is dead (" + str(p.hp) + "hp)")
	
	battleOver = IsBattleOver()

func AI_v1():
	for t in teams:
		for p in t:
			var move = p.moves[randi() % 4]
			round_moves.push_back({move = move, userSpeed = p.baseStats.speed})

func moveSort(moveA, moveB):
	if moveA.moveData.priority > moveB.moveData.priority:
		return true
	elif moveA.moveData.priority < moveB.moveData.priority:
		return false
	
	var pokemonA = GetPokemonData(moveA.dealer)
	var pokemonB = GetPokemonData(moveB.dealer)
	if pokemonA.baseStats[5] > pokemonB.baseStats[5]:
		return true
	elif pokemonA.baseStats[5] < pokemonB.baseStats[5]:
		return false
	return randi() % 2 == 0

func OrderMoves():
	#order pokemon from fastest to slowest. TODO: If Trick_room, reverse the odrer
	#for each user in order, set their move into the array above the next-lowest priority
	round_moves.sort_custom(moveSort)
	
func PokemonKO(defeated):
	var lostPokemon = defeated #GetPokemonData(defeated) #This is already hydrated
	var baseXpGrant = (int(lostPokemon.baseexp) * lostPokemon.level / 5)
	var baseXpNumerator = (lostPokemon.level * 2) + 10
	var index = GetPokemonIndex(defeated)
	var teamNoXp = GetPokemonTeam(index)
	for t in teams.size():
		if t != teamNoXp:
			for p in reserves[t]:
				var pokemon = GetPokemonData(p)
				if pokemon.hp <= 0:
					continue
				var xpGrant = PokemonHelpers.ExpGainedFromDefeat(pokemon, lostPokemon)
				pokemon.xp += xpGrant
				print(pokemon.name + " gained " + str(xpGrant) + " XP!")
				
				var levelAfterXp = PokemonHelpers.CalculateCurrentLevel(pokemon)
				if pokemon.level != levelAfterXp:
					pokemon.level = levelAfterXp
					pokemon.baseStats = PokemonHelpers.CaculateStats(pokemon)
					print(pokemon.name + " is now level " + str(levelAfterXp))
				
func IsBattleOver():
	#TODO: update this to check reserves for battle over. Teams is now just pulling in more.
	var over = false
	if battleOver:
		return true
	var teamsWithCombatants = teams.size()
	for t in teams:
		if t.size() == 0:
			teamsWithCombatants -= 1
		else:
			var members = t.size()
			for p in t:
				var data = GetPokemonData(p)
				var h = data.hp
				if (data.hp <= 0):
					members -= 1
			if members <= 0:
				teamsWithCombatants -= 1
	if teamsWithCombatants <= 1:
		over = true	
	if over == true:
		print("battle is over now!")
		battleOver = true
	return over
	
#This is being done by MoveEffects now, i suppose.
func ApplyAttack(source, move):
	#OK, this should probably just call each move instead of having 1 single resolution.
	#pokemon.apply() in Pokerogue, LINE 1239
	var hitResult = []
	var damage = 0
	
	#TODO: get defending side of the field
	#TODO: apply VariableMoveCategoryAttr ?
	
	#TODO: get move multiplier
	
	#TODO: get category phy/special/status
	if move.category == "STATUS":
		pass
		#mostly skipping damage math?
		#Check type immunity
		#check move immunity
		#check pre-Defend abilities for the defender's side
		#set result info?
	else: #damage moves do the same logic with different attributes.
		pass
		
