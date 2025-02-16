extends RefCounted
class_name CellTracker
#NOTE: use Components/CellTrackerDrawer to get a visualization on this

var fileName = "user://Data/CellTracker.json"
var visited = {}

func _ready():
	Load()
	PraxisCore.plusCode_changed.connect(AutoUpdate)

func Load():
	visited = PraxisCore.LoadData(fileName)
	if (visited == null):
		visited = {}

func Save():
	PraxisCore.SaveData(fileName, visited)
	
func AutoUpdate(current, old):
	Add(current)
	Save()

func Add(plusCode10):
	if (visited == null):
		visited = {}
	plusCode10 = plusCode10.replace("+", "").substr(0,10)
	visited[plusCode10] = true
	
func Remove(plusCode10):
	if (visited == null):
		visited = {}
	plusCode10 = plusCode10.replace("+", "").substr(0,10)
	visited.erase(plusCode10)
	
func Total():
	if visited == null:
		return 0
	return visited.size()
