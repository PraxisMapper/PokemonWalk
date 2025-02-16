extends Node2D
class_name OfflineDataV3

#This is the refined version of drawing offline data. This will display status to
#the user on-screen (with toggle to display or not), use toggles to determine which 
#tiles are drawn, and indicate via on-screen banner what the current status is on image
#drawing progress (drawing tile, saving tiles by code, etc)
#This will also assume the data is already present for now, and skip downloading it from
#a server.

signal style_saved()
signal style_ready()
signal data_saved()
signal data_ready()
signal tiles_saved()

signal tile_created(texture)

var plusCode6 = ""
var scaleVal = 1
var mapData

@export var drawnStyle = "mapTiles"
@export var makeMapTile = true
@export var makeTerrainTile = false
@export var makeNameTile = false
@export var makeBoundsTile = false
@export var makeThumbnail = false
@export var thumbnailScale = 0.08

func GetAndProcessData(plusCode, scale = 1):
	var oneTile = null
	$Banner.visible = true
	$Banner/lblStatus.text = "Preparing to draw...."
	print("processing full offline data")
	plusCode6 = plusCode.substr(0,6)
	if (plusCode.length() == 8):
		oneTile = plusCode.substr(6,2)
	scaleVal = scale
	await RenderingServer.frame_post_draw
	
	$Banner/lblStatus.text = "Getting Style"
	var styleData = await PraxisCore.GetStyle(drawnStyle)
	$Banner/lblStatus.text = "Style loaded."
	$svc/SubViewport/fullMap.style = styleData
	$svc2/SubViewport/nameMap.style = styleData
	$svc4/SubViewport/terrainMap.style = styleData
	if makeBoundsTile: #Always uses its own style
		$svc3/SubViewport/boundsMap.style = await PraxisCore.GetStyle("adminBoundsFilled")
	
	mapData = await PraxisOfflineData.GetDataFromZip(plusCode6) 
	if (mapData == null):
		$Banner/lblStatus.text = "Error getting map data. Try again." 
		return
		
	$Banner/lblStatus.text = "Data Loaded. Processing " + str(mapData.entries["mapTiles"].size()) + " items, please wait...." 
	await RenderingServer.frame_post_draw
	#Game is probably going to freeze for a couple seconds here while Godot draws stuff to the node

	await CreateAllTiles(oneTile) #Godot runs slow while this does work and waits for frames.
	
	if makeThumbnail:
		$svc/SubViewport/fullMap.scale = Vector2((1 / scale) * thumbnailScale, (1 / scale) * thumbnailScale)
		$svc/SubViewport/subcam.position = Vector2(0,-500 * 20 * (1 / scale) * thumbnailScale)
		$svc/SubViewport.size = Vector2i(320 * 20 * (1 / scale) * thumbnailScale, 500 * 20 * (1 / scale) * thumbnailScale)
		await RenderingServer.frame_post_draw
		var img = await $svc/SubViewport.get_texture().get_image() # Get rendered image
		await img.save_png("user://MapTiles/" + plusCode6 + "-thumb.png") # Save to disk
		
	
	$Banner/lblStatus.text = "Tiles Drawn for " + plusCode
	await get_tree().create_timer(2).timeout
	var fade_tween = create_tween()
	fade_tween.tween_property($Banner, 'modulate:a', 0.0, 1.0)
	fade_tween.tween_callback($Banner.hide)
	
func CreateAllTiles(oneTile = null):
	#Fullmap at 0, name map at 40k, bounds map at 80k, terrain at 120k
	$svc/SubViewport/fullMap.position.y = 0
	$svc2/SubViewport/nameMap.position.y = 40000 * scaleVal
	$svc3/SubViewport/boundsMap.position.y = 80000 * scaleVal
	$svc4/SubViewport/terrainMap.position.y = 120000 * scaleVal
	
	var viewport1 = $svc/SubViewport
	var viewport2 = $svc2/SubViewport
	var viewport3 = $svc3/SubViewport
	var viewport4 = $svc4/SubViewport
	var camera1 = $svc/SubViewport/subcam
	var camera2 = $svc2/SubViewport/subcam
	var camera3 = $svc3/SubViewport/subcam
	var camera4 = $svc4/SubViewport/subcam
	var scale = scaleVal
	
	camera1.position = Vector2(0,0)
	camera2.position = Vector2(0,40000 * scaleVal)
	camera3.position = Vector2(0,80000 * scaleVal)
	camera4.position = Vector2(0,120000 * scaleVal)
	viewport1.size = Vector2i(320 * scale, 500 * scale)
	viewport2.size = Vector2i(320, 500) #non-visible images don't need scaled up.
	viewport3.size = Vector2i(320, 500)
	viewport4.size = Vector2i(320, 500)
	await RenderingServer.frame_post_draw #set this before loading entities, skips a wasted draw call.
	
	$Banner/lblStatus.text = "Drawing " + plusCode6 + "..."
	if makeMapTile == true:
		print("drawing map (full)")
		await $svc/SubViewport/fullMap.DrawOfflineTile(mapData.entries["mapTiles"], scaleVal)
	if makeNameTile == true:
		print("drawing name")
		await $svc2/SubViewport/nameMap.DrawOfflineNameTile(mapData.entries["mapTiles"], scaleVal)
	if makeBoundsTile == true and mapData.entries.has("adminBoundsFilled"): #dont draw if theres no data.
		print("drawing bounds")
		await $svc3/SubViewport/boundsMap.DrawOfflineBoundsTile(mapData.entries["adminBoundsFilled"], scaleVal)
	if makeTerrainTile == true:
		print("drawing terrain")
		await $svc4/SubViewport/terrainMap.DrawOfflineTerrainTile(mapData.entries["mapTiles"], scaleVal)
	
	var xList = PlusCodes.CODE_ALPHABET_
	var yList = PlusCodes.CODE_ALPHABET_
	
	if (oneTile != null):
		xList = oneTile[1]
		yList = oneTile[0]

	var tex1
	for yChar in yList:
		#This kept complaining about can't - a Vector2 and an Int so I had to do this.
		#yPos -= (PlusCodes.CODE_ALPHABET_.find(yChar) * 20 * scale)
		camera1.position.y -= (500 * scale)
		camera2.position.y -= (500)
		camera3.position.y -= (500)
		camera4.position.y -= (500)
			
		for xChar in xList:
			camera1.position.x = (PlusCodes.CODE_ALPHABET_.find(xChar) * 320 * scale)
			camera2.position.x = (PlusCodes.CODE_ALPHABET_.find(xChar) * 320)
			camera3.position.x = (PlusCodes.CODE_ALPHABET_.find(xChar) * 320)
			camera4.position.x = (PlusCodes.CODE_ALPHABET_.find(xChar) * 320)
			await RenderingServer.frame_post_draw
			if makeMapTile == true:
				tex1 = await viewport1.get_texture()
				var img1 = tex1.get_image() # Get rendered image
				await img1.save_png("user://MapTiles/" + plusCode6 + yChar + xChar + ".png") # Save to disk
			if makeNameTile == true:
				var img2 = await viewport2.get_texture().get_image() # Get rendered image
				await img2.save_png("user://NameTiles/" + plusCode6 + yChar + xChar + ".png") # Save to disk
			if makeBoundsTile == true:
				var img3 = await viewport3.get_texture().get_image() # Get rendered image
				await img3.save_png("user://BoundsTiles/" + plusCode6 + yChar + xChar + ".png") # Save to disk
			if makeTerrainTile == true:
				var img4 = await viewport4.get_texture().get_image() # Get rendered image
				await img4.save_png("user://TerrainTiles/" + plusCode6 + yChar + xChar + ".png") # Save to disk
			$Banner/lblStatus.text = "Saved Tiles for " + plusCode6 + yChar + xChar
			tile_created.emit(tex1) #Exclusive logic to this prototype.
	
	tiles_saved.emit()

func xDownloadFullData(plusCode6):
	#TODO: figure out the URL for these files. Possibly a PraxisMapper URL, possibly just a filehost.
	pass
