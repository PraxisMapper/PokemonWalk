extends Node2D

func _ready():
	PraxisCore.plusCode_changed.connect(UpdateScreen)
	UpdateScreen(PraxisCore.currentPlusCode, "")

func _process(delta):
	pass
	
func UpdateScreen(current, _old):
	$CellTracker.Add(current)
	var place = $PlaceTracker.CheckForPlace(current)
	print(place)
	GameGlobals.currentPlace = place
	
	$PartyDisplay.UpdateScreen()
	$AreaInfo.UpdateScreen(current, _old)
