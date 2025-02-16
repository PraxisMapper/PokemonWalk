extends Node2D

var process = true

var lastPlusCode = '' #Might be replaceable with odl in the change call
var currentOffset = Vector2(0,0) #Pixels offset for scrolling purposes, referenced by other controls
var plusCodeBase = '22334455+2X' #The plusCode used for the upper-left corner of the area,
# and referenced by other

func _ready():
	#removing this fixed the "move outside of starting cell8 issue.
	#plusCode_changed(PraxisCore.currentPlusCode, PraxisCore.lastPlusCode) 
	#PraxisCore.plusCode_changed.connect(plusCode_changed) 
	#This caused mulitple draws to occur at once. We'll let navigation call these changes.
	
	#Experimenting for queue
	$TileDrawerQueued.tile_created.connect(UpdateTexture)

func plusCode_changed(current, old):
	if process == false:
		print("skipping a process run, busy.")
		return

	if !visible:
		return
	
	#var cur = PlusCodes.RemovePlus(current) # stack overflows? why?
	process = false #Block this from being called again while we run.
	if current.substr(0,8) != lastPlusCode.substr(0,8): # old.substr(0,8):
		#process = false
		await RefreshTiles(current)
		var children = $trackedChildren.get_children()
		for c in children:
			var offset = getDrawingOffset(c.get_meta("originalLocation", ""))
			if offset != null:
				c.position = offset
		#process = true
	#else:
		#only update the center cellTracker
		#var ct = get_node("celltrackers/CellTrackerDrawer00")
		#ct.DrawCellTracker(GameGlobals.cellTracker, current)
	#Now scroll mapBase to the right spot.
	var currentXPos = PlusCodes.RemovePlus(current).substr(9,1)
	var xIndex = PlusCodes.CODE_ALPHABET_.find(currentXPos)
	var xShift = (PraxisCore.mapTileWidth / 2) -  (PraxisCore.mapTileWidth / 20) * xIndex
	var currentYPos = PlusCodes.RemovePlus(current).substr(8,1)
	var yIndex = PlusCodes.CODE_ALPHABET_.find(currentYPos)
	var yShift = (PraxisCore.mapTileHeight / 2) - (PraxisCore.mapTileHeight / 20) * yIndex
	
	if PlusCodes.RemovePlus(current).length() == 11:
		var lastIndex = PlusCodes.CODE_ALPHABET_.find(PlusCodes.RemovePlus(current).substr(10,1))
		xShift += lastIndex % 4
		yShift += lastIndex / 4
	
	#print("current pos:" + currentXPos + "," + currentYPos)
	
	#print($trackedChildren.get_children().size())
	
	$mapBase.position.x = xShift
	$mapBase.position.y = -yShift
	$trackedChildren.position = $mapBase.position - position #works but doesnt feel right for some reason.
	currentOffset = $mapBase.position
	#$celltrackers.position = $mapBase.position
	
	lastPlusCode = current
	if process == false:
		process = true
		if current != PraxisCore.currentPlusCode:
			print("refreshing scrolling centered map after process run")
			plusCode_changed(PraxisCore.currentPlusCode, lastPlusCode)

func getDrawingOffset(plusCode):
	var offset = PlusCodes.GetDistanceCell10s(plusCodeBase, plusCode)
	#First vector converts to Cell12 pixels, 2nd accommodates non-origin position of map
	return offset * Vector2(-16,25) + position 
	
	#Dont move the map for Cell11s right now. This doesnt move the map, just children.
	#if PlusCodes.RemovePlus(plusCode).length == 11:
		#var charVal = PlusCodes.GetLetterIndex(plusCode.right(1))
		#offset += Vector2(charVal % 4, charVal / 4)
	#else:
		#centers item in cell10 instead of lower-left corner
		#offset += Vector2(8, 13)

func trackChildOnMap(node, plusCodePosition):
	if (plusCodePosition == null):
		return
	var offset = getDrawingOffset(plusCodePosition)
	node.position = offset
	node.set_meta("originalLocation", plusCodePosition)
	$trackedChildren.add_child(node)

func clearAllTrackedChildren():
	for tc in $trackedChildren.get_children():
		tc.queue_free()
		
func ToggleCellTracker():
	$celltrackers.visible = !$celltrackers.visible

func UpdateTexture(code, texture):
	var center = PraxisCore.currentPlusCode #lastPlusCode
	var coords = PlusCodes.GetDistanceCell8s(code, center) 
	var addendum = str(int(coords.x)) + str(int(coords.y)) #TODO: sometimes has 3 in the x coords, which fails.
	var tilenode = get_node("mapBase/MapTile" + addendum)
	if (tilenode != null):
		tilenode.texture = ImageTexture.create_from_image(texture) #update might be faster?
	else:
		print("couldnt get node for tile at " + addendum)
		

func RefreshTiles(current):
	if current == null:
		current = PraxisCore.currentPlusCode
	plusCodeBase = PlusCodes.ShiftCode(current.substr(0,8), -2, 2) + "X2"
	var base = current.substr(0,8)
	var node
	var code
	var tex
	var textures = {}
	#NEW: to try to minimize disruptions, we're gonna draw missing tiles first.
	#THen update the visible display.
	for x in [-2,-1,0,1,2]:
		textures[x] = {}
		for y in [-2,-1,0,1,2]:
			var checkCode = PlusCodes.ShiftCode(base, x, y)
			if !FileAccess.file_exists("user://MapTiles/" + checkCode + ".png"):
				tex = await $TileDrawerQueued.GetAndProcessData(checkCode, 1)
				node = get_node("mapBase/MapTile" + str(x) + str(y))
				node.texture = ImageTexture.create_from_image(tex) #update might be faster?
			#textures[x][y] = tex #await $TileDrawer.tile_created
			else:
				$TileDrawerQueued.AddToQueue(checkCode)

	#for x in [-2,-1,0,1,2]:
		#for y in [-2,-1,0,1,2]:
			#var t = textures[x][y]
			#if t != null:
				#node = get_node("mapBase/MapTile" + str(x) + str(y))
				#node.texture = ImageTexture.create_from_image(t) #update might be faster?
			
			code = PlusCodes.ShiftCode(base, x, y)
			#NEW: update CellTrackerDrawer for each tile.
			#var ct = get_node("celltrackers/CellTrackerDrawer" + str(x) + str(y))
			#ct.DrawCellTracker(GameGlobals.cellTracker, code)

#This is not intended to be a full API, but an example of how you'd check on tap
#to find which child should respond.
func GetNearestTrackedChild(event: InputEventMouseButton):
	if !event.pressed:
		return null
	
	var closestNode = null
	var closestDist = 9999999999
	
	for node in $trackedChildren.get_children():
		var dist = event.position.distance_to(node.global_position)
		if dist < closestDist:
			closestDist = dist
			closestNode = node
	
	return closestNode
