extends Node
class_name PoGoLevelCurves

#This tracks how much stuff costs as stuff levels up.
#Name may change.

func StardustToBoost(currentBoostCount):
	pass
	
func XpToLevel(currentXp):
	pass
	
static func GetCombatPowerMultiplier(currentBoostCount):
	return 0.094 + (currentBoostCount * 0.006)
