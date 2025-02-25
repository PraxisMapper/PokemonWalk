extends Node
class_name PoGoLevelCurves

#This tracks how much stuff costs as stuff levels up.
#Name may change.

func StardustToBoost(currentBoostCount):
	pass
	
func XpToLevel(currentXp):
	pass
	
static func GetCombatPowerMultiplier(instanceData):
	#Each pokemon starts at 9.4% of the stats listed for it, and adds 0.6% per level
	#(Level 151 is where a baseline pokmeon will get its listed stats from the data file)
	#If it was caught walking, multiply that by 15%. If caught while driving, remove 15%
	#As a buddy, each place visited increases a 1% multiplier, and each ~km walked increases a 1% mulitiplier
	#A level 1 pokemon caught while walking with 10 places gets a total of 11.89% of its stats. 
	#A level 151 pokemon caught while walking with 100 places for 30km gets a total of 299% of its stats.
	var baseMul =  0.094 + (instanceData.level * 0.006)
	if instanceData.caughtSpeed > GameGlobals.speedLimit:
		baseMul *= (1 + GameGlobals.speedBuff)
	elif instanceData.caughtSpeed > 0: # Encountered pokemon do not get stronger, nor do ones from earlier releases.
		baseMul *= (1 - GameGlobals.speedBuff)
	baseMul *= (1 + instanceData.buddyBoost)
	baseMul *= (1 + (instanceData.distanceWalked * 0.000001)) # convert m to km, then take 1% of that.
	return baseMul
