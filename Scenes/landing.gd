extends Node2D

var isBusy = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameGlobals.Load()
	if HasPerms():
		print("leaving Landing for MapView.")
		get_tree().change_scene_to_file("res://Scenes/MapView.tscn")
	
	$Timer.timeout.connect(HasPerms)

func HasPerms():
	var perms = OS.get_granted_permissions()
	if perms.has("android.permission.ACCESS_FINE_LOCATION"):
		$sc/c/btnStart.disabled = isBusy
		$sc/c/btnDownloadNow.disabled = isBusy
		return true
	if OS.get_name() != "Android":
		$sc/c/btnStart.disabled = isBusy
		$sc/c/btnDownloadNow.disabled = isBusy
		return true
	return false
	
func GrantPermission():
	OS.request_permissions()

func GetDataNow():
	print("Getting data")
	$sc/c/btnStart.disabled = true
	isBusy = true
	var statusCode = $GetFile.getCell4File(PraxisCore.currentPlusCode.substr(0,4))
	if statusCode == 0: # downloading.
		await $GetFile.file_downloaded
	$sc/c/btnStart.disabled = false
	isBusy = false
	print("Data got")

func StartGame():
	get_tree().change_scene_to_file("res://Scenes/MapView.tscn")

func _process(delta):
	if PraxisCore.currentPlusCode != PraxisCore.debugStartingPlusCode:
		$sc/c/lblArea.text = "Current Area: " + PraxisCore.currentPlusCode.substr(0,4)
