extends Node2D

var thisBattle

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func SetBattle(data):
	thisBattle = data
	var p1 = PokemonHelpers.hydratePokemon(PokemonHelpers.GetTeamSlotInfo(0))
	var p2 = PokemonHelpers.hydratePokemon(PokemonHelpers.GetTeamSlotInfo(1))
	var p3 = PokemonHelpers.hydratePokemon(PokemonHelpers.GetTeamSlotInfo(2))
	var p4 = PokemonHelpers.hydratePokemon(PokemonHelpers.GetTeamSlotInfo(3))
	var p5 = PokemonHelpers.hydratePokemon(PokemonHelpers.GetTeamSlotInfo(4))
	var p6 = PokemonHelpers.hydratePokemon(PokemonHelpers.GetTeamSlotInfo(5))
	
	thisBattle.team1[0] = p1
	thisBattle.team1[1] = p2
	thisBattle.team1[2] = p3
	thisBattle.team1[3] = p4
	thisBattle.team1[4] = p5
	thisBattle.team1[5] = p6
	
	$pdmL1.SetInfo(p1, true)
	$pdmL2.SetInfo(p2, true)
	$pdmL3.SetInfo(p3, true)
	$pdmL4.SetInfo(p4, true)
	$pdmL5.SetInfo(p5, true)
	$pdmL6.SetInfo(p6, true)
	
	$pdmR1.SetInfo(data.team2[0])
	$pdmR2.SetInfo(data.team2[1])
	$pdmR3.SetInfo(data.team2[2])
	$pdmR4.SetInfo(data.team2[3])
	$pdmR5.SetInfo(data.team2[4])
	$pdmR6.SetInfo(data.team2[5])
	
	RunAutoBattle()
	
func RunAutoBattle():
	#This is for fast-fights, instead of asking the player for all 6 moves/targets.
	var battleEngine = BattleSystemV1.new()
	var results = battleEngine.AutoBattle(thisBattle)
	#SetBattle(results.battle)
	FinalizeBattle(results)

func FinalizeBattle(results):
	#This is where I want to show updates on each battle entry.
	#Does team 2 not have names?
	if results.battle.team1[0].hp == 0:
		$lblWinner1.text = "Winner: " + results.battle.team1[0].name
	else:
		$lblWinner1.text = "Winner: " + results.battle.team2[0].name
	if results.battle.team1[1].hp == 0:
		$lblWinner2.text = "Winner: " + results.battle.team1[1].name
	else:
		$lblWinner2.text = "Winner: " + results.battle.team2[1].name
	if results.battle.team1[2].hp == 0:
		$lblWinner3.text = "Winner: " + results.battle.team1[2].name
	else:
		$lblWinner3.text = "Winner: " + results.battle.team2[2].name
	if results.battle.team1[3].hp == 0:
		$lblWinner4.text = "Winner: " + results.battle.team1[3].name
	else:
		$lblWinner4.text = "Winner: " + results.battle.team2[3].name
	if results.battle.team1[4].hp == 0:
		$lblWinner5.text = "Winner: " + results.battle.team1[4].name
	else:
		$lblWinner5.text = "Winner: " + results.battle.team2[4].name
	if results.battle.team1[5].hp == 0:
		$lblWinner6.text = "Winner: " + results.battle.team1[5].name
	else:
		$lblWinner6.text = "Winner: " + results.battle.team2[5].name

func Close():
	queue_free()
