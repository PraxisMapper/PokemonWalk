extends Node
class_name RecentActivityTracker
#NOTE: Similar to CellTracker, but also stores a date with each entry and ignores
# or updates ones more than a certain age old.

var fileName = "user://Data/RecentTracker.json"
var visited = {}
var timeDiffSeconds = 60 * 60 * 22 #22 hours. Allows for a daily loop on a schedule.
var semaphore = Semaphore.new()
var lock = Mutex.new()

signal newRecent(plusCode)

func _ready():
	Load()
	if visited == null:
		visited = {}
	RemoveOld()
	PraxisCore.plusCode_changed.connect(AutoUpdate)
	var t = Thread.new()
	t.start(WriteFile)

func Load():
	visited = PraxisCore.LoadData(fileName)

func Save():
	semaphore.post()

func WriteFile():
	while true:
		semaphore.wait()
		lock.lock()
		PraxisCore.SaveData(fileName, visited)
		lock.unlock()

func AutoUpdate(current, old):
	RemoveOld()
	Check(current)

func Check(plusCode10):
	plusCode10 = plusCode10.replace("+", "").substr(0,10)
	if !visited.has(plusCode10):
		newRecent.emit(plusCode10)
		visited[plusCode10] = { time = Time.get_unix_time_from_system() }
		Save()
	
func RemoveOld():
	var expired = Time.get_unix_time_from_system() - timeDiffSeconds
	for v in visited.keys():
		if visited[v].time <= expired:
			visited.erase(v)

func Total():
	RemoveOld()
	return visited.size()
