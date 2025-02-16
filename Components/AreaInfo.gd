extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func UpdateScreen(current, _old):
	$lblPlusCode.text = current
	var spawnData = PossiblePokemon.CalcPossiblePokemon(current, _old)
	var present = ""
	for pokemon in spawnData:
		present +=  pokemon + ", "
	$lblAvailable.text = present
	$lblPlace.text = GameGlobals.currentPlace[0]
