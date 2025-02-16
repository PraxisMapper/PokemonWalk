extends Node2D

var serverPath = "https://global.praxismapper.org/"
var cell4Path = "Content/OfflineData/"
var cell6Path = "Offline/FromZip/"
var isActive = false
var skipTween = false
var filesToGet = []
var currentFile = ""

signal file_downloaded()

func AddToQueue(code):
	if !filesToGet.has(code):
		filesToGet.push_back(code)
		print("queued " + code)
		if (!isActive):
			RunQueue()
		else:
			print("queue is busy, not running again")
		
#TODO: if this doesnt work, look at using Mutex or Semaphore instead
#Semaphore might not work since we're a Node and not necessarily different threads.
func RunQueue():
	isActive = true
	while filesToGet.size() > 0:
		var file = filesToGet.pop_front()
		currentFile = file
		await getCell6FileSync(file)
	isActive = false
	fadeout()

#OK, immediately upon trying to do this, I realize I'm gonna hit issues with files overlapping
#so I can't do both of these nicely. I'll need to pick a folder or something.
func getCell4File(plusCode4):
	#if isActive:
		#return 2
	
	var cell2 = plusCode4.substr(0,2)
	if FileAccess.file_exists("user://Data/Full/" + plusCode4 + ".zip"):
		var reader = ZIPReader.new()
		var isGoodFile = reader.open("user://Data/Full/" + plusCode4 + ".zip")
		if isGoodFile == OK:
			file_downloaded.emit()
			return 1 #already downloaded this! May have a future setup to force this.
	
	var tempFile = "user://Data/Full/" + plusCode4 + ".zip" #-temp
	$client.request_completed.connect(request_complete)
	$client.download_file = tempFile
	var status = $client.request(serverPath + cell4Path + cell2 + "/" + plusCode4 + ".zip")
	if status != Error.OK:
		print("error calling download:" + str(status))
		return 2
	#DirAccess.rename_absolute(tempFile, tempFile.substr(0, tempFile.length() - 5)) #only if -temp
	#isActive = true
	$Banner.visible = true
	return 0
	
func getCell6File(plusCode6):
	print("getting cell 6 file")
	#if isActive:
		#print("already active, not downloading " + plusCode6)
		#return false
	#Uses a different path to pull single files
	var cell2 = plusCode6.substr(0,2)
	if PraxisOfflineData.OfflineDataExists(plusCode6):
	#if FileAccess.file_exists("user://Data/Full/" + plusCode6 + ".json"):
		print("file already exists for " + plusCode6)
		file_downloaded.emit()
		return true #already downloaded this! May have a future setup to force this.
	
	$client.request_completed.connect(request_complete)
	$client.download_file = "user://Data/Full/" + plusCode6 + ".json"
	print(serverPath + cell6Path + plusCode6)
	var status = $client.request(serverPath + cell6Path + plusCode6)
	if status != Error.OK:
		print("error calling download:" + str(status))
		return false
		#DirAccess.remove_absolute("user://Data/Full/" + plusCode6 + ".json-temp")
	#DirAccess.rename_absolute("user://Data/Full/" + plusCode6 + ".json-temp", "user://Data/Full/" + plusCode6 + ".json")
	#isActive = true
	$Banner.visible = true
	return true
	
func getCell6FileSync(plusCode6):
	print("getting sync version of cell6")
	#if isActive:
		#return false
	#Uses a different path to pull single files
	var cell2 = plusCode6.substr(0,2)
	if FileAccess.file_exists("user://Data/Full/" + plusCode6 + ".json"):
		file_downloaded.emit()
		return true #already downloaded this! May have a future setup to force this.

	$client.cancel_request()	
	#$client.request_completed.connect(request_complete)
	$client.download_file = "user://Data/Full/" + plusCode6 + ".json"
	var status = $client.request(serverPath + cell6Path + plusCode6)
	if status != Error.OK:
		print("error calling download:" + str(status))
		return
	
	#isActive = true
	$Banner.visible = true
	
	var results = await $client.request_completed
	print(results)
	
	print("downloaded file OK: " + plusCode6)
	#return
	file_downloaded.emit()
	$Banner/Label.text = "Download Complete"
	return true

func request_complete(result, response_code, headers, body):
	#isActive = false
	for h in headers:
		print(h)
	$client.request_completed.disconnect(request_complete)
	print("complete:" + str(result))
	if result != HTTPRequest.RESULT_SUCCESS:
		print("request complete error:" + str(result))
		$Banner/Label.text = "Download Error"
		return
	
	file_downloaded.emit()
	$Banner/Label.text = "Download Complete"

func _process(delta):
	if isActive:
		var body_size = $client.get_body_size() * 1.0
		if body_size > -1:
			$Banner/Label.text = "Downloaded " + currentFile + ": " + str(snapped(($client.get_downloaded_bytes() / body_size) * 100, 0.01))  + " percent"
		else:
			$Banner/Label.text = "Downloaded " + currentFile + ": " + str($client.get_downloaded_bytes()) + " bytes"
		pass
		
func fadeout():
	await get_tree().create_timer(2).timeout
	var fade_tween = create_tween()
	fade_tween.tween_property($Banner, 'modulate:a', 0.0, 1.0)
	fade_tween.tween_callback($Banner.hide)
