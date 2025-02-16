extends Node2D

#A default input-blocking modal.

@onready var spinner: Sprite2D = $ColorRect/Spinner

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if (self.visible == true):
		spinner.rotation += (delta * 10 * sin(Time.get_unix_time_from_system()))

#TODO: this may need to extend Control and make this _gui_input instead?
func _unhandled_input(event):
	#this is what this is listening for to block touches cascading down farther.
	if (self.visible == true):
		get_viewport().set_input_as_handled()
