extends Node2D  #i think this should be control ideally, but it only ever seems to work as Node2D
class_name PoGoMiniDisplay

var data = {}
var cancelLeftClick = true
signal leftClicked(data)
signal rightClicked(data)

func _get_minimum_size() -> Vector2:
	return Vector2(64, 64)

func _ready() -> void:
	SetInfo(data)
	$ClickListener.gui_input.connect(popInput)

func SetInfo(pokemonData):
	if pokemonData == null or pokemonData.is_empty():
		return
	data = pokemonData
	if $txrPokemon != null:
		$txrPokemon.texture = load(PokemonHelpers.GetPokemonFrontSprite(pokemonData.key, false, "M")) #ImageTexture.create_from_image(img)
	if $lblName != null:
		$lblName.text = pokemonData.name
	if $lblPower != null:
		$lblPower.text = str(PokemonHelpers.GetCombatPower(pokemonData)) + " CP"

#This was quite a mess to figure out but I did it. I have to add a plain Control, then use THAT
#to catch guiEvent signals and see if those are what I want.
func popInput(inputEvent):
	if inputEvent is InputEventMouseMotion:
		cancelLeftClick = true
		return

	if inputEvent is not InputEventMouseButton:
		return 

	if inputEvent.button_index == MOUSE_BUTTON_LEFT:
		if inputEvent.pressed == true:
			cancelLeftClick = false
		else:
			if cancelLeftClick == false:
				leftClicked.emit(data)
				cancelLeftClick  = true
	elif inputEvent.button_index == MOUSE_BUTTON_RIGHT:
		if inputEvent.pressed == true:
			cancelLeftClick = true
		else:
			rightClicked.emit(data)
