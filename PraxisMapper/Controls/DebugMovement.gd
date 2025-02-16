extends Node2D

#this control should show up when no GPS is available. Can use PC Keyboard to navigate faster.
@onready var label : Label = $CanvasLayer/ColorRect/Label

func GoNorth():
	PraxisCore.ForceChange(PlusCodes.ShiftCode(PraxisCore.currentPlusCode, 0, 1))
	
func GoSouth():
	PraxisCore.ForceChange(PlusCodes.ShiftCode(PraxisCore.currentPlusCode, 0, -1))
	
func GoEast():
	PraxisCore.ForceChange(PlusCodes.ShiftCode(PraxisCore.currentPlusCode, 1, 0))
	
func GoWest():
	PraxisCore.ForceChange(PlusCodes.ShiftCode(PraxisCore.currentPlusCode, -1, 0))

func _process(delta):
	label.text = PraxisCore.currentPlusCode	
	if (Input.is_key_pressed(KEY_UP)):
		GoNorth()
	if (Input.is_key_pressed(KEY_DOWN)):
		GoSouth()
	if (Input.is_key_pressed(KEY_LEFT)):
		GoWest()
	if (Input.is_key_pressed(KEY_RIGHT)):
		GoEast()
