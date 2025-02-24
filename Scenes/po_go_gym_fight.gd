extends Node2D
class_name PoGoGymFight

#This scene handles gym/raid fights. There will be 1 big attacker on the left,
#and your team on the right. This is still an autofight scene, but instead of being
#automatic you will watch this combat play out. 
#Gyms would cycle through up to 6 combatants on both sides in 1v1 battles,
#raids would be the whole team fighting 1 pokemon that attacks all opponents.
#so not quite the same thing.

#TODO: expose runtime speed somewhere on the UI. Buttons to increase or decrease it.
#TODO: big boss battle where ALL your pokemon enter the fight until one side wins.

var boss = {} #pokemon key, generated up for the npc
var party = [] #pokemon keys

var fightOn = false
var currentAnimationFrame = 0
var currentTime = 0

var battle = PoGoCombat.new()
var battleParty = []
var battleResults = []
var animationSpeed = 2 #We wont make you watch the fight in realtime.

var searchKey = ""
var setMiniDisplay = 1

func _ready() -> void:
	$pickParty/lblPartyHeader.text += GameGlobals.baseData.pokemon[boss.key].name + "\n(Level " + str(boss.level) + ")"
	$pickParty/txrBoss2.texture = load(PokemonHelpers.GetPokemonFrontSprite(boss.key, false, "M"))
	
	$pickParty.position.x = 0
	$pickParty/PoGoMiniDisplay.leftClicked.connect(miniTapped1)
	$pickParty/PoGoMiniDisplay2.leftClicked.connect(miniTapped2)
	$pickParty/PoGoMiniDisplay3.leftClicked.connect(miniTapped3)
	$pickParty/PoGoMiniDisplay4.leftClicked.connect(miniTapped4)
	$pickParty/PoGoMiniDisplay5.leftClicked.connect(miniTapped5)
	$pickParty/PoGoMiniDisplay6.leftClicked.connect(miniTapped6)
	
	$PoGoInventory.DisconnectDefault()
	AutoSelectParty()

func miniTapped1(data):
	$PoGoInventory.position.x = 0
	$PoGoInventory.leftClicked.connect(update1)
	setMiniDisplay = 1

func miniTapped2(data):
	$PoGoInventory.position.x = 0
	$PoGoInventory.leftClicked.connect(update2)
	setMiniDisplay = 2
	
func miniTapped3(data):
	$PoGoInventory.position.x = 0
	$PoGoInventory.leftClicked.connect(update3)
	setMiniDisplay = 3
	
func miniTapped4(data):
	$PoGoInventory.position.x = 0
	$PoGoInventory.leftClicked.connect(update4)
	setMiniDisplay = 4
	
func miniTapped5(data):
	$PoGoInventory.position.x = 0
	$PoGoInventory.leftClicked.connect(update5)
	setMiniDisplay = 5
	
func miniTapped6(data):
	$PoGoInventory.position.x = 0
	$PoGoInventory.leftClicked.connect(update6)
	setMiniDisplay = 6

func update1(data):
	#TODO: detect duplicates and disallow those.
	$pickParty/PoGoMiniDisplay.SetInfo(data)
	$PoGoInventory.position.x = 1500
	$PoGoInventory.leftClicked.disconnect(miniTapped1)

func update2(data):
	$pickParty/PoGoMiniDisplay2.SetInfo(data)
	$PoGoInventory.position.x = 1600
	$PoGoInventory.leftClicked.disconnect(miniTapped2)
	
func update3(data):
	$pickParty/PoGoMiniDisplay3.SetInfo(data)
	$PoGoInventory.position.x = 1600
	$PoGoInventory.leftClicked.disconnect(miniTapped3)
	
func update4(data):
	$pickParty/PoGoMiniDisplay4.SetInfo(data)
	$PoGoInventory.position.x = 1600
	$PoGoInventory.leftClicked.disconnect(miniTapped4)
	
func update5(data):
	$pickParty/PoGoMiniDisplay5.SetInfo(data)
	$PoGoInventory.position.x = 1600
	$PoGoInventory.leftClicked.disconnect(miniTapped5)
	
func update6(data):
	$pickParty/PoGoMiniDisplay6.SetInfo(data)
	$PoGoInventory.position.x = 1600
	$PoGoInventory.leftClicked.disconnect(miniTapped6)
	
func Start():
	$pickParty.position.x = -1600
	$txrBoss.texture = load(PokemonHelpers.GetPokemonFrontSprite(boss.key, false, "M"))
	
	print(party[0])
	$txrParty1.texture = load(PokemonHelpers.GetPokemonFrontSprite($pickParty/PoGoMiniDisplay.data.key, false, "M"))
	$txrParty2.texture = load(PokemonHelpers.GetPokemonFrontSprite($pickParty/PoGoMiniDisplay2.data.key, false, "M"))
	$txrParty3.texture = load(PokemonHelpers.GetPokemonFrontSprite($pickParty/PoGoMiniDisplay3.data.key, false, "M"))
	$txrParty4.texture = load(PokemonHelpers.GetPokemonFrontSprite($pickParty/PoGoMiniDisplay4.data.key, false, "M"))
	$txrParty5.texture = load(PokemonHelpers.GetPokemonFrontSprite($pickParty/PoGoMiniDisplay5.data.key, false, "M"))
	$txrParty6.texture = load(PokemonHelpers.GetPokemonFrontSprite($pickParty/PoGoMiniDisplay6.data.key, false, "M"))
	
	battle.boss = battle.HydrateGoPokemon(boss)
	battle.boss.Stamina *= 2.5 # Increase boss durability so they're not automatic wins.
	battle.team.append(PoGoCombat.HydrateGoPokemon($pickParty/PoGoMiniDisplay.data))
	battle.team.append(PoGoCombat.HydrateGoPokemon($pickParty/PoGoMiniDisplay2.data))
	battle.team.append(PoGoCombat.HydrateGoPokemon($pickParty/PoGoMiniDisplay3.data))
	battle.team.append(PoGoCombat.HydrateGoPokemon($pickParty/PoGoMiniDisplay4.data))
	battle.team.append(PoGoCombat.HydrateGoPokemon($pickParty/PoGoMiniDisplay5.data))
	battle.team.append(PoGoCombat.HydrateGoPokemon($pickParty/PoGoMiniDisplay6.data))

	party = [
		$pickParty/PoGoMiniDisplay.data,
		$pickParty/PoGoMiniDisplay2.data,
		$pickParty/PoGoMiniDisplay3.data,
		$pickParty/PoGoMiniDisplay4.data,
		$pickParty/PoGoMiniDisplay5.data,
		$pickParty/PoGoMiniDisplay6.data,
	]
	
	battleResults = battle.RunRaid()
	print("jobs done")
	
	#now we can check the results of the battle.
	if battle.boss.Stamina <= 0:
		#player wins, catch boss, grant other rewards too.
		GameGlobals.pokemon[boss.id] = boss
		GameGlobals.playerData.currentCoins += 150
		GameGlobals.playerData.stardust += 1000
		GameGlobals.playerData.dailyClearedRaids.append(PraxisCore.currentPlusCode.substr(0,8))
		GameGlobals.Save()
	else:
		#player did not win. I guess the reasons why dont matter.
		pass
	
	#now we can animate it
	fightOn = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if fightOn:
		#Continue running the fight.
		currentAnimationFrame += delta * 100 * animationSpeed #delta is seconds, we track ms.
		$lblTimer.text = str(snapped(currentAnimationFrame / 100.0, 0.01))
		while battleResults.size() > 0 and currentAnimationFrame >= battleResults.front().time:
			var action = battleResults.pop_front()
			#Draw this result on-screen now.
			if action.user != "system":
				var bits = action.action.split(",")
				var actor = {}
				if action.user == boss.id:
					actor = boss
				else:
					searchKey = action.user
					actor = party.filter(FindPartyMemberByKey)[0]
				$sc/lblLog.text += actor.name + " uses " + bits[1] + " for " + bits[3] + "\n"
				$sc.ensure_control_visible($sc/lblLog)
				PopDmgText(action)
			else:
				if action.action == "victory":
					$sc/lblLog.text += "You defeated the raid boss!\n"
				elif action.action == "loss":
					$sc/lblLog.text += "You were defeated!\n"
				elif action.action == "timeout":
					$sc/lblLog.text += "You ran out of time!\n"
					
		pass
	if battleResults.size() == 0:
		fightOn = false

func PopDmgText(action):
	var dmgtxt = Label.new()
	var bits = action.action.split(",")
	dmgtxt.text = bits[3]
	var randpos = randf()
	
	if action.target == boss.id:
		$txrBoss.add_child(dmgtxt)
		dmgtxt.modulate = Color.GREEN
		dmgtxt.position = Vector2(192,192)
	else:
		dmgtxt.scale = Vector2(3,3)
		dmgtxt.modulate = Color.RED
		for i in 6:
			if party[i].id == action.target:
				var n = get_node("txrParty" + str(i+1))
				n.add_child(dmgtxt)
				dmgtxt.position = Vector2(64,64)
	
	var tween = get_tree().create_tween()
	tween.tween_property(dmgtxt, "modulate.a", 0, 1)
	tween.tween_property(dmgtxt, "position", Vector2(sin(randpos) * 5, cos(randpos) * 5), 1)
	tween.tween_callback(dmgtxt.queue_free)

#may or may not use this to find member
func FindPartyMemberByKey(key):
	return key.id == searchKey
	
func AutoSelectParty():
	var sortedList = GameGlobals.pokemon.values()
	sortedList.sort_custom(SortList)
	
	for i in min(6, sortedList.size() - 1):
		get_node("pickParty/PoGoMiniDisplay" + str(i+1).replace("1", "")).SetInfo(sortedList[i])

func SortList(a, b):
	return a.combatPower > b.combatPower

func Close():
	get_parent().get_parent().UpdateRaidButton(PraxisCore.currentPlusCode.substr(0,8))
	queue_free()
