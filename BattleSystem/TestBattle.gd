extends Node2D
#A thing to fire up directly to test the battle stuff.

# Called when the node enters the scene tree for the first time.
func _ready():
	#Test pogo logic too
	var pogo = PoGoCombat.new()
	pogo.TestPoGoCode()
	
	SetupTestBattle()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func SetupTestBattle():
	print("Creating test battle")
	var bi = Battle.new() #Battle Instance, called battleState by sub-components
	bi.Initalize()
	var team1 = []
	var team2 = []
	var reserves1 = []
	var reserves2 = []
	bi.teams = [team1, team2]
	bi.reserves = [reserves1, reserves2]
	
	#combatants
	var t1p1i = PokemonHelpers.NewPokemonData(5)
	var t2p1i = PokemonHelpers.NewPokemonData(8)
	var t1p2i = PokemonHelpers.NewPokemonData(14)
	var t2p2i = PokemonHelpers.NewPokemonData(50)
	print("Combatants created")
	print(t1p1i)
	
	#hydrate combatants. Quick setup to test here now.
	t1p1i.xp = 7500
	t2p1i.xp = 7500
	t1p2i.xp = 7500
	t2p2i.xp = 7500
	var t1p1H = PokemonHelpers.hydratePokemon(t1p1i)
	var t2p1H = PokemonHelpers.hydratePokemon(t2p1i)
	var t1p2H = PokemonHelpers.hydratePokemon(t1p2i)
	var t2p2H = PokemonHelpers.hydratePokemon(t2p2i)
	print(t1p1H)
	
	bi.combatants.push_back(t1p1H)
	team1.push_back(bi.combatants.size() - 1)
	reserves1.push_back(bi.combatants.size() - 1)
	bi.combatants.push_back(t2p1H)
	team2.push_back(bi.combatants.size() - 1)
	reserves2.push_back(bi.combatants.size() - 1)
	bi.combatants.push_back(t1p2H)
	reserves1.push_back(bi.combatants.size() - 1)
	bi.combatants.push_back(t2p2H)
	reserves2.push_back(bi.combatants.size() - 1)
	
	print("Teams filled in")
	
	#each round: both participants pick moves.
	while bi.battleOver == false:
		#bi.PreRound() # not yet ready to drop in.
		bi.AutoPickAll(bi)
		bi.OrderMoves()
		print("moves picked")
	
		#TODO: next expansion of this logic is setting up the next active team member
		#when one gets knocked out. Is that here, or in bi? Probably here. Might ask user
		#which one comes out next, so that gets done outside of battleinfo.
		bi.RunRound()
	
	#A real battle would now save XP back to the game's entries.
	#TODO: check/print bi.roundLog for stuff?
	print("its over!")
	#This should be the save-back logic, though it could be simplified a bit to track which is which.
	t1p1i.xp = bi.combatants[reserves1[0]].xp
	t1p2i.xp = bi.combatants[reserves1[1]].xp
