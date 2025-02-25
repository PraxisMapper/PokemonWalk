extends Node
class_name PoGoCombat

#Changes in PoGo style combat
#Simplifed stats, no abilities. Stats are pre-calculated, already in the JSON file
#STAB is 1.2, not 1.5. Super-effective damage is 1.4x, not 2x. Resistance is .71, not .5
#I can make this an auto-battle setup, since each move has a timer.
#Moves are simplified, they have a power value and either add or subtract energy when used
#PoGo ALSO has a Combat Power Multiplier, which increases each level or half-level
#minimum is 0.094 at level 1, max is .8653 at level 55. I could change or ignore the level cap.
#Combat Power displayed is derived by the other PoGO stats and the level's combat power multiplier.
#Additionaly, if the pokemon has over 4,000 power at or past level 40, multiply its stats by .91
#I can check for that at file-gen time and include a flag to nerf it.
#PoGO has IVs 0-15, base game has 0-32

var currentTime = 0

var poke1
var poke2

#alt vars, for raids.
var boss
var team = []
var actionLog = []

static func HydrateGoPokemon(instanceData):
	if instanceData.is_empty():
		return {}
	
	var basePokemon = GameGlobals.baseData.pokemon[instanceData.key]
	var combatPokemon = {}
	#Create the actual combat-stats for this entry.

	var combatPowerMod = PoGoLevelCurves.GetCombatPowerMultiplier(instanceData)
	
	combatPokemon.id = instanceData.id #to help find this specific one in the display later.
	combatPokemon.name = basePokemon.name
	combatPokemon.Types = basePokemon.types
	#Add IVs to base stats, multiply them by combat power mulitiplier
	#Most of the stats were already calculated, so use those
	combatPokemon.Attack = int(basePokemon.PoGoAtk * combatPowerMod)
	combatPokemon.Defense = int(basePokemon.PoGoDef * combatPowerMod)
	combatPokemon.Stamina = int(floor((basePokemon.PoGoSta * 1.75) + 50) * combatPowerMod)
	combatPokemon.MaxStamina = combatPokemon.Stamina
	combatPokemon.Moves = []
	#temp fix: force something here to avoid a crash.
	if (instanceData.moveNames.size() == 0):
		instanceData.moveNames = ["TACKLE_FAST", "HYPER_BEAM"]
	
	for m in instanceData.moveNames: 
		if m == null: #A secondary temp fix
			m = "TACKLE_FAST"
		combatPokemon.Moves.append(GameGlobals.baseData.pogoMoves[m])
	
	combatPokemon.nextAttack = 0
	combatPokemon.energy = 0
	return combatPokemon

func RunBattle(): #1v1 battle. Multiplayer just means the v1 side attacks all opponents.
	var battleTimer = 180000 #if the next attack's time is greater than this, the match's over.
	currentTime = 0
	
	#TODO: attack moves tend to do damage toward the END of their time, not the start as we run here.
	
	var keepGoing = true
	#We can very simply run combat by having each pokemon's move go off each time its available
	while keepGoing:
		var attacker = GetNextAttacker1V1()
		DoAttack1V1(attacker)
		
		if poke1.Stamina <= 0 or poke2.Stamina <= 0 or currentTime >= battleTimer:
			keepGoing = false
		
	if (currentTime > battleTimer):
		return 3 #timeout, nothing happened.
	if poke1.Stamina > 0:
		return 1 #player wins
	return 2 #CPU wins.
	
func RunRaid():
	#For 6v1 raids
	#Differences: the 1 attacks all 6. The 1 has buffed stats by some value
	#it does not end until all of the 6 are <= 0 HP, so i have to ensure dead ones dont attack.
	#I also may animate this, so I need to output a set of events and times
	var event = {time = 0, user = "key", action = "whathappen"} # like this, in an array?
	
	var battleTimer = 180000 #if the next attack's time is greater than this, the match's over.
	currentTime = 0
	
	var keepGoing = true
	while keepGoing:
		var attacker = GetNextAttackerRaid()
		DoAttackRaid(attacker)
		
		if boss.Stamina <= 0 or team.all(IsTeamMemberDone):
			keepGoing = false
			if boss.Stamina <= 0:
				actionLog.append({time = currentTime, user = "system", action = "victory"})
			else:
				actionLog.append({time = currentTime, user = "system", action = "loss"})
		
		if (currentTime > battleTimer):
			actionLog.append({time = battleTimer, user = "system", action = "timeout"})
			keepGoing = false
	return actionLog

func IsTeamMemberDone(entry):
	return entry.Stamina <= 0

func GetNextAttackerRaid():
	var nextPoke = {}
	nextPoke = boss
	
	for t in team:
		if (t.nextAttack <= nextPoke.nextAttack and t.Stamina > 0):
			nextPoke = t

	currentTime = nextPoke.nextAttack
	return nextPoke

func DoAttackRaid(attacker):
	var isBoss = (attacker == boss)
	
	var move = {}
	#Pick move. NOTE: bosses do not have a 2nd charge move unlocked.
	#If I have enough energy to do a charge move, pick a super-effective one.
	#if not, do the fast move.
	if attacker.energy > (attacker.Moves[1].energyDelta * -1): #TODO add second charge move
		move = attacker.Moves[1]
	else:
		move = attacker.Moves[0]
	
	#TODO make this a function
	var stab = 1
	for type in attacker.Types:
		if type == move.type:
			stab *= 1.2 #Fusion pokemon can have the same type twice, and boosts this.
			
	#if boss, attack all. otherwise, attack boss.
	if isBoss:
		for t in team:
			if t.Stamina <= 0:
				continue
			var effectiveness = CalcEffectiveness(move.type, t.Types)
			var damage = floor(0.5 * move.power * attacker.Attack / t.Defense * stab * effectiveness)
			damage += 1
			damage = int(damage)
			t.Stamina -= damage
			#print(attacker.name + " uses " + move.name + " on " + t.name + " for " + str(damage) + " at " + str(currentTime) + ", has " + str(attacker.energy) + " energy")
			actionLog.append({time = currentTime, user = attacker.id, target = t.id, action = "move," + move.name +",damage," + str(damage)})
	else:
		var effectiveness = CalcEffectiveness(move.type, boss.Types)
		var damage = floor(0.5 * move.power * attacker.Attack / boss.Defense * stab * effectiveness)
		damage += 1
		damage = int(damage)
		boss.Stamina -= damage
		#print(attacker.name + " uses " + move.name + " on " + boss.name + " for " + str(damage) + " at " + str(currentTime) + ", has " + str(attacker.energy) + " energy")
		actionLog.append({time = currentTime, user = attacker.id, target = boss.id, action = "move," + move.name +",damage," + str(damage)})
	
	
	attacker.energy += move.energyDelta
	#set this pokemon's next attack time.
	attacker.nextAttack += move.time

func GetNextAttacker1V1():
	var nextPoke = {}
	if (poke1.nextAttack <= poke2.nextAttack):
		nextPoke = poke1
	else: 
		nextPoke = poke2
	currentTime = nextPoke.nextAttack
	return nextPoke

func DoAttack1V1(poke):
	var defender = {}
	if poke == poke1:
		defender = poke2
	else:
		defender = poke1
	
	var move = {}
	#Pick move.
	#If I have enough energy to do a charge move, pick a super-effective one.
	#if not, do the fast move.
	if poke.energy > (poke.Moves[1].energyDelta * -1): #TODO add second charge move
		move = poke.Moves[1]
	else:
		move = poke.Moves[0]
		
	var stab = 1
	for type in poke.Types:
		if type == move.type:
			stab *= 1.2 #Fusion pokemon can have the same type twice, and boosts this.
	var effectiveness = CalcEffectiveness(move.type, defender.Types)
	var damage = floor(0.5 * move.power * poke.Attack / defender.Defense * stab * effectiveness)
	damage += 1
	damage = int(damage)
	
	poke.energy += move.energyDelta
	#set this pokemon's next attack time.
	poke.nextAttack += move.time
	
	#print(poke.name + " uses " + move.name + " for " + str(damage) + " at " + str(currentTime) + ", has " + str(poke.energy) + " energy")
	
	defender.Stamina -= damage
	if defender.Stamina <= 0:
		#print("ITS OVER")
		#TODO: they're dead, end fight.
		return

func CalcEffectiveness(moveType, defenderTypes):
	var effectiveness = 1
	var attackMods = GameGlobals.baseData.damageMultiplierChart[moveType]
	for m in attackMods:
		if defenderTypes.has(m):
			var change = attackMods[m]
			if change == "E":
				effectiveness *= GameGlobals.baseData.damageMultiplier.poGoEffective
			elif change == "R":
				effectiveness *= GameGlobals.baseData.damageMultiplier.poGoResist
			elif change == "X":
				effectiveness *= GameGlobals.baseData.damageMultiplier.poGoImmune
	return effectiveness
