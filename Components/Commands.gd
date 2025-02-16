extends Node2D


@onready var combatScene = preload("res://Scenes/CombatTest.tscn")
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func WildBattle():
	#this is all test stuff right now..
	var combat = combatScene.instantiate()
	get_parent().add_child(combat)
	
	var battle = {}
	
	battle.team1 = GameGlobals.playerData.team.duplicate()

	var baseXp = 0
	for i in 6:
		baseXp += GameGlobals.playerData.allCaught[battle.team1[i]].xp
	baseXp = baseXp / 6
	
	var team2 = []
	team2.push_back(PokemonHelpers.NewPokemonData(randi() % GameGlobals.baseData.pokemon.size()))
	team2.push_back(PokemonHelpers.NewPokemonData(randi() % GameGlobals.baseData.pokemon.size()))
	team2.push_back(PokemonHelpers.NewPokemonData(randi() % GameGlobals.baseData.pokemon.size()))
	team2.push_back(PokemonHelpers.NewPokemonData(randi() % GameGlobals.baseData.pokemon.size()))
	team2.push_back(PokemonHelpers.NewPokemonData(randi() % GameGlobals.baseData.pokemon.size()))
	team2.push_back(PokemonHelpers.NewPokemonData(randi() % GameGlobals.baseData.pokemon.size()))

	for i in 6:
		team2[i].xp = baseXp * randf_range(.85, 1.25) #OR should this be a wider bell curve to rarely have strong/weak opponents?

	battle.team2 = team2
	combat.SetBattle(battle)
