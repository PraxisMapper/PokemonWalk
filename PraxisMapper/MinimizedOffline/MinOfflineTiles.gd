extends Node2D

#This is already offline data, we need to load it from the current program's
#res://OfflineData folder.

signal tiles_saved()

var plusCode = ""
var style = "suggestedmini"
var scaleVal = 1
var mapData

func GetAndProcessData(pluscode6):
	plusCode = pluscode6
	scaleVal = 1
	await GetStyle()
	mapData = await MinimizedOffline.GetDataFromZip(pluscode6)
	if (mapData == null):
		print("MapData is null, check for earlier errors.")
	await CreateAllTiles()
	
func GetStyle():
	var styleData = PraxisCore.GetStyle(style)
	$svc/SubViewport/fullMap.style = styleData
	$svc2/SubViewport/nameMap.style = styleData
	$svc3/SubViewport/terrainMap.style = styleData

func CreateAllTiles():
	#This is Cell6 data drawn with Cell10 pixels, so each image is 400x400
	#I don't need to subdivide these images any further.
	#Note for future self: SubViewports are their own separate instanced world,
	#so I can overlap them and the camera in each sees stuff correctly. But it will
	#draw in the scene, so this node should be offscreen by a fair margin.
	
	$svc/SubViewport/fullMap.position.y = 400
	$svc2/SubViewport/nameMap.position.y = 400
	$svc3/SubViewport/terrainMap.position.y = 400
	
	$svc/SubViewport/fullMap.DrawOfflineTile(mapData.entries["suggestedmini"], scaleVal)
	$svc2/SubViewport/nameMap.DrawOfflineNameTile(mapData.entries["suggestedmini"], scaleVal)
	$svc3/SubViewport/terrainMap.DrawOfflineTerrainTile(mapData.entries["suggestedmini"], scaleVal)
	
	var viewport1 = $svc/SubViewport
	var viewport2 = $svc2/SubViewport
	var viewport3 = $svc3/SubViewport
	var camera1 = $svc/SubViewport/subcam
	var camera2 = $svc2/SubViewport/subcam
	var camera3 = $svc3/SubViewport/subcam
	var scale = scaleVal
	
	camera1.position = Vector2(0,0)
	camera2.position = Vector2(0,0)
	camera3.position = Vector2(0,0)
	viewport1.size = Vector2i(400 * scale, 400 * scale)
	viewport2.size = Vector2i(400 * scale, 400 * scale)
	viewport3.size = Vector2i(400 * scale, 400 * scale)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw #In some cases, this IS necessary
	#Exact details on when/why require more research.
	
	var img1 = viewport1.get_texture().get_image() # Get rendered image
	img1.save_png("user://MapTiles/" + plusCode + ".png") # Save to disk
	var img2 = viewport2.get_texture().get_image() # Get rendered image
	img2.save_png("user://NameTiles/" + plusCode + ".png") # Save to disk
	var img3 = viewport3.get_texture().get_image() # Get rendered image
	img3.save_png("user://TerrainTiles/" + plusCode + ".png") # Save to disk
	
	tiles_saved.emit()
