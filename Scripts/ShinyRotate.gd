extends TextureRect

func _process(delta: float) -> void:
	if (material != null):
		var angles = Input.get_gyroscope()
		material.set_shader_parameter("mouse_position", Vector2(angles.x, angles.y))
		material.set_shader_parameter("spirte_position", global_position)
