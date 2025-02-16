extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func SetInfo(pokemonData, flipImg = false): #NOT party slot
	#var data = GameGlobals.baseData.pokemon[pokemonData.baseDataKey.key]
	var name = PokemonHelpers.GetPokemonFrontSprite(pokemonData.key, pokemonData.isShiny, pokemonData.gender)
	
	var texture = load(name)
	#NOTE: these textures are 192x192
	$pokemonImg.texture = load(name)
	$pokemonImg.position.x = 0
	$pokemonImg.position.y = 0
	$pokemonImg.scale = Vector2(0.5, 0.5)
	if flipImg:
		$pokemonImg.flip_h = true
	$lblName.text = GameGlobals.baseData.pokemon[pokemonData.key].name
