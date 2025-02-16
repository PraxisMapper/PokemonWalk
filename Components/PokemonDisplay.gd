extends Node2D

var pokemonToShow

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	#pokemonToShow = 

func UpdateDisplay(partySlot):
	#var pokemonToShow = GameGlobals.playerData.team[partySlot]
	var pokemonToShow = GameGlobals.playerData.allCaught[GameGlobals.playerData.team[partySlot]]
	var name = PokemonHelpers.GetPokemonFrontSprite(pokemonToShow.key, pokemonToShow.isShiny, pokemonToShow.gender)
	#var image = Image.load_from_file(name)
	#var texture = ImageTexture.create_from_image(image)
	#NOTE: these textures are 192x192, and this control is 270x200 right now
	$pokemonImg.texture = load(name) #texture
	$pokemonImg.position.x = 0
	$pokemonImg.position.y = 0
	$pokemonImg.scale = Vector2(0.5, 0.5)
	$pkName.text = GameGlobals.baseData.pokemon[pokemonToShow.key].name # pokemonToShow.baseDataKey #name needs a lookup
	
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
