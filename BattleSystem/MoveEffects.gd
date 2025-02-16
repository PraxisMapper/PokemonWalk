extends RefCounted
class_name MoveEffects

#BattleSystem is the folder that's going to hold all the actual combat stuff
#that matches the original games. This file is for damage and move info.

#TODO: when executing moves, loop it on all targets, but call all calculations per target
#so most calls should take an explicit target value in addition to the movedata.

var battleState = {}

#This handles all the functions a move can do when its run.

#All Move Flags (and counts of them):
#Contact:266
#CanProtect:653
#CanMirrorMove:648
#HighCriticalHitRate:26
#Sound:32
#Bomb:26
#Slicing:26
#TramplesMinimize:7
#Wind:19
#Powder:8
#Dance:12
#CannotMetronome:94
#Biting:8
#Pulse:7
#Punching:24
#ElectrocuteUser:3
#ThawsUser:10

#Special functions by count, for things that are reused
#FlinchTarget : 22
#HitTwoToFiveTimes : 13
#AttackAndSkipNextTurn : 10
#BindTarget : 9
#HealUserByHalfOfDamageDone : 8
#HitTwoTimes : 8
#HealUserHalfOfTotalHP : 5
#TrapTargetInBattle : 5
#LowerTargetSpDef2 : 5
#LowerUserSpAtk2 : 5
#RaiseUserAttack1 : 5
#RaiseUserDefense2 : 5
#AlwaysCriticalHit : 4
#MultiTurnAttackConfuseUserAtEnd : 4
#RecoilQuarterOfDamageDealt : 4
#RaiseUserSpAtk1 : 4
#LowerUserDefSpDef1 : 4
#RaiseUserSpeed1 : 4
#RecoilThirdOfDamageDealt : 4
#RaiseUserDefense1 : 4
#SwitchOutUserDamagingMove : 3
#RaiseUserMainStats1 : 3
#LowerTargetSpeed2 : 3
#IgnoreTargetDefSpDefEvaStatStages : 3
#PowerHigherWithUserHP : 3
#FixedDamageHalfTargetHP : 3
#HealUserDependingOnWeather : 3
#UseTargetDefenseInsteadOfTargetSpDef : 3
#UserConsumeTargetBerry : 2
#RaiseUserDefSpDef1 : 2
#RedirectAllMovesToUser : 2
#FailsIfTargetActed : 2
#UserTakesTargetItem : 2
#PowerHigherWithUserPositiveStatStages : 2
#UserTargetSwapItems : 2
#SwitchOutTargetDamagingMove : 2
#NormalMovesBecomeElectric : 2
#DoublePowerIfTargetNotActed : 2
#RecoilHalfOfDamageDealt : 2
#HealUserByThreeQuartersOfDamageDone : 2
#LowerTargetAttack2 : 2
#CrashDamageIfFailsUnusableInGravity : 2
#LowerUserSpeed1 : 2
#RemoveScreens : 2
#DoublePowerIfUserLostHPThisTurn : 2
#HitThreeTimesPowersUpWithEachHit : 2
#PowerHigherWithTargetWeight : 2
#PowerLowerWithUserHP : 2
#FixedDamageUserLevel : 2
#ProtectUser : 2
#PowerHigherWithUserHeavierThanTarget : 2
#TwoTurnAttackInvulnerableRemoveProtections : 2
#IgnoreTargetAbility : 2
#TwoTurnAttackOneTurnInSun : 2
#CureUserPartyStatus : 2
#HealUserAndAlliesQuarterOfTotalHPCureStatus : 2
#HitsTargetInSkyGroundsTarget : 2
#DoublePowerIfUserLastMoveFailed : 2
#MultiTurnAttackPowersUpEachTurn : 2
#StartHailWeather : 2
#UserFaintsExplosive : 2
#CannotMakeTargetFaint : 2
#PowerHigherWithTargetHP : 2
#OHKO : 2
#StartNegateTargetEvasionStatStageAndGhostImmunity : 2
#EnsureNextMoveAlwaysHits : 2
#LowerTargetAtkSpAtk1 : 2
#SwitchOutTargetStatusMove : 2
#AttackTwoTurnsLater : 2
#RaiseUserSpeed2 : 2
#UserSwapBaseAtkDef : 2
#CounterDamagePlusHalf : 2
#IncreasePowerSuperEffective : 2
#CantSelectConsecutiveTurns : 2


#Reference for move data types
#"MEGAHORN": {
#"key": "MEGAHORN",
#"name": "Megahorn",
#"type": "BUG",
#"priority": null,
#"category": "Physical",
#"power": "120",
#"accuracy": "85",
#"totalPP": "10",
#"target": "NearOther",
#"functioncode": "None",
#"flags": ["Contact", "CanProtect", "CanMirrorMove"],
#"description": "Using its tough and impressive horn, the user rams into the target with no letup."

var sampleMoveData = {
	dealer = {}, #the user, possibly an index.
	targets = [], #the pokemon to hit, possibly an array of indexes instead of objects
	moveData = {}, #the actual game move data
	#battleState = {}, #the rest of the game's flags.
}

#This gets called by Battle.DoMove.
func DoMove(moveData, dealer, targets):
	print("Executing " + moveData.key)
	for target in targets:
		var t = battleState.GetPokemonData(target)
		if t.hp <= 0 and targets.size() == 1:
		 #dont hit dead pokemon. Retarget if this was the only target.
			var newTarget = battleState.chooseMove.ChooseTargets(dealer, moveData)
			
			return
		var accuracy = CheckAccuracy(moveData, dealer, target)
		if accuracy < randf():
			#Miss
			print("Attack missed")
			return
		var damage = CalcDamage(moveData, dealer, target)
		print("Damage is " + str(damage))
		ApplyDamage(moveData, target, damage)
	
	#TODO: function code for each thing, ability checks and modifiers, etc,etc.
	
func ApplyDamage(moveData, target, damage):
	#TODO: Sturdy ability check, false swipe, etc.
	var pokemon = battleState.combatants[target]
	pokemon.hp -= damage
	print(pokemon.name + " takes " + str(damage) + " dmg from " + moveData.name + ", has " + str(pokemon.hp) + "left")
	if (pokemon.hp <= 0):
		battleState.PokemonKO(pokemon)
		#pokemon is out, remove from team so it can't be targeted
		var team = battleState.GetPokemonTeam(target)
		battleState.teams[team].erase(target)
	
func CalcTypeEffectiveness(atkType, target):
	#TODO: abilities that grant immunity, abilities that change types, moves that change types
	#TODO: ensure this gets called per target if targets is an array
	if target is Array:
		target = target[0]
	var mod = 1
	var pokemon = battleState.combatants[target]
	for defType in pokemon.types:
		if GameGlobals.baseData.damageMultiplier[atkType].has(defType):
			mod *= GameGlobals.baseData.damageMultiplier[atkType][defType]
	
	return mod

func CritChance(moveData):
	var stages = 0
	
	if (moveData.flags.has("HighCriticalHitRate")):
		stages += 1
	
	if stages == 0:
		return 1/24 # Base chance.
	elif stages == 1:
		return .125
	elif stages == 2:
		return .5
	else:
		return 1
		
func GetStabBonus(moveData, dealer):
	#TODO: Abilities, moves with special typing cases, tera stuff.
	var attacker = battleState.combatants[dealer]
	if attacker.types.has(moveData.type):
	#if dealer.type1 == moveData.type or dealer.type2 == moveData.type:
		return 1.5
	return 1
	
	
var multipleTargetValues = ["AllNearFoes", "FoeSide", "BothSides", "AllNearOthers", "AllBattlers"]

#Using the Arceus damage formula
func CalcDamage(moveData, dealer, target):
	
	if moveData.category == "Status":
		return 0 # Special cases should be done by the function code.
		
	#The index in the stat array to use.
	var atkStat = 1
	var defStat = 2
	
	if (moveData.category == "Special"):
		atkStat = 3
		defStat = 4
	#TODO: other weird conditions.
	
	var attacker = battleState.combatants[dealer]
	var defender = battleState.combatants[target]
	
	var atk = PokemonHelpers.GetCurrentStat(attacker, atkStat)
	var def = PokemonHelpers.GetCurrentStat(defender, defStat)
	var attackerLevel = attacker.level
	
	#GenV+ damage formula.
	var currentDamage = (((2 * attackerLevel) / 5) + 2) * int(moveData.power)
	currentDamage *= (float(atk) / float(def))
	currentDamage /= 50
	currentDamage += 2
	
	if multipleTargetValues.has(moveData.target):
		currentDamage *= 0.5 # 0.75 for double or triples. In battle royales, its 0.5. May use that instead.
	
	#TODO: a few other checks between Targets and Critical to do.
	
	currentDamage *= randf_range(0.85, 1.0)
	
	if randf() < CritChance(moveData):
		currentDamage *= 1.5
		
	currentDamage *= GetStabBonus(moveData, dealer)
	
	currentDamage *= CalcTypeEffectiveness(moveData.type, target)
	
	#TODO a bunch of other checks for fairly narrow conditions.
	
	return int(currentDamage) # Should probably do this on most steps for maximum accuracy

func CheckAccuracy(moveData, dealer, target):
	#TODO: alwaysHits flag, if targeting self always hits.
	
	var toHitChance = int(moveData.accuracy) * .01
	
	#TODO: confirm this math is right.
	var attacker = battleState.combatants[dealer]
	var defender = battleState.combatants[target]
	
	var stageShift = clamp(attacker.statStages[6] - defender.statStages[7], -6, 6)
	var stageMod = PokemonHelpers.GetAccuracyEvasionStageModifier(attacker, stageShift)
	
	toHitChance *= stageMod
	
	#TODO: all the other effects that can apply here
	return toHitChance

func ChangeStatStage(pokemon, statIndex, stageChange):
	pokemon.statStages[statIndex] = clamp(pokemon.statStages[statIndex] + stageChange, -6, 6)
	
func baseMoveSort(a, b):
	#true is a is before b
	if (a.priority > b.priority):
		return true
	
	if (PokemonHelpers.GetCurrentStat(a.dealer, 5) > PokemonHelpers.GetCurrentStat(b.dealer, 5)):
		return true
	
	#if its still a tie, results are random.
	if randf() < 0.5:
		return a
	return b

func OrderMoves(moveList):
	#TODO: priority change procs and abilites are done here or earlier,
	#since sorting is not supposed to be randomized
	
	#Base: sort by priority, then user's speed
	moveList.sort_custom(baseMoveSort)
	#TODO: special cases, Trick Room, random procs for speed.

#Now all the special functions
func None(moveData): # Just in case this gets called somehow.
	pass
func LowerTargetAttack1(moveData):
	ChangeStatStage(moveData.target, 1, -1)
func LowerTargetDefense1(moveData):
	ChangeStatStage(moveData.target, 2, -1)
func LowerTargetSpAtk1(moveData):
	ChangeStatStage(moveData.target, 3, -1)
func LowerTargetSpDef1(moveData):
	ChangeStatStage(moveData.target, 4, -1)
func LowerTargetSpeed1(moveData):
	ChangeStatStage(moveData.target, 5, -1)
func LowerTargetAccuracy1(moveData):
	ChangeStatStage(moveData.target, 6, -1)
func BurnTarget(moveData):
	moveData.target.permStatusEffect = "BURN"
func SleepTarget(moveData):
	moveData.target.permStatusEffect = "SLEEP"
func PoisonTarget(moveData):
	moveData.target.permStatusEffect = "POISON"
func BadPoisonTarget(moveData):
	moveData.target.permStatusEffect = "TOXIC"
func ParalyzeTarget(moveData):
	moveData.target.permStatusEffect = "PARALYZE"
func FreezeTarget(moveData):
	moveData.target.permStatusEffect = "FREEZE"
func ConfuseTarget(moveData):
	moveData.target.tempStatusEffect = "CONFUSE"
func Struggle(moveData):
	pass # TODO: implement recoil and other special checks for this fallback.
