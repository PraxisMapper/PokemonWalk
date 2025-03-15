extends Node2D  #i think this should be control ideally, but it only ever seems to work as Node2D
class_name PoGoMiniDisplay

var data = {}
var cancelLeftClick = true
var skipOnStart = false
signal leftClicked(data)
signal rightClicked(data)

func _get_minimum_size() -> Vector2:
	return Vector2(64, 64)

func _ready() -> void:
	if !skipOnStart:
		SetInfo(data)
	$ClickListener.gui_input.connect(popInput)

func SetColor(color):
	$ColorRect.color = color

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

func SetPokedexInfo(key, isCaught):
	#use this function to set up this display for pokedex mode.
	data = {key = key, isCaught = isCaught}
	if $txrPokemon != null:
		$txrPokemon.texture = load(PokemonHelpers.GetPokemonFrontSprite(key, false, "M")) #ImageTexture.create_from_image(img)
		$lblPower.text = ""
		if isCaught:
			$lblName.text = GameGlobals.baseData.pokemon[key].name
		else:
			#make the sprite solid black silhouette
			$txrPokemon.modulate = "000000"
			$lblName.text = "????"

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
				data.nodeName = self.get_path()
				leftClicked.emit(data)
				cancelLeftClick  = true
	elif inputEvent.button_index == MOUSE_BUTTON_RIGHT:
		if inputEvent.pressed == true:
			cancelLeftClick = true
		else:
			data.nodeName = self.id
			rightClicked.emit(data)
