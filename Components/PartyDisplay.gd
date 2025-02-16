extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func UpdateScreen():
	$pkmn1.UpdateDisplay(0)
	$pkmn2.UpdateDisplay(1)
	$pkmn3.UpdateDisplay(2)
	$pkmn4.UpdateDisplay(3)
	$pkmn5.UpdateDisplay(4)
	$pkmn6.UpdateDisplay(5)
