extends Node2D

#This is for drawing map tiles directly in the client from Offline/V2 data

var theseentries = null
var thisscale = 1
var drawnCode = ""
#NOTE: drawOps are drawn in order, so the earlier one has the higher LayerId in PraxisMapper style language.
#the value/id/order is the MatchOrder for the style in PraxisMapper server


#This is set from outside.
var style #same logic as for NameTiles


func DrawSingleTile(entries, scale, plusCode):
	theseentries = entries
	thisscale = scale
	drawnCode = plusCode
	queue_redraw()

func _draw():  #DrawCell8(plusCode):
	#determine the coordinates for this Cell8
	#Only process items that are in that cell8
	#Draw and save only that Cell8 image.
	
	var plusCode = drawnCode
	
	if theseentries == null:
		return
	
	var scale = thisscale
	var width = 320 * 20 # 6400 # should be scaled1
	var height = 500 * 20 #= 10000
	#REMEMBER: PlusCode origin is at the BOTTOM-left, these draw calls use the TOP left.
	#This should do the same invert drawing that PraxisMapper does server-side.
	draw_set_transform(Vector2(0,0), 0, Vector2(1,-1))
	
	var testPointY = PlusCodes.GetLetterIndex(plusCode[6]) * 500
	var testPointX = PlusCodes.GetLetterIndex(plusCode[7]) * 320
	#Add 1 Cell10s worth of buffer to this check, so point on the image borders show up correctly.1
	var minPoint = Vector2i(testPointX - 16, testPointY - 25)
	var maxPoint =  Vector2i(testPointX + 319 + 16, testPointY + 499 + 25)
	var thisArea = Rect2(minPoint, maxPoint)

	var bgCoords = PackedVector2Array()
	bgCoords.append(Vector2(0,0))
	bgCoords.append(Vector2(width * scale,0))
	bgCoords.append(Vector2(width * scale,height * scale))
	bgCoords.append(Vector2(0,height * scale))
	bgCoords.append(Vector2(0,0))
	draw_colored_polygon(bgCoords, style["9999"].drawOps[0].color) 
	var orderedDrawCommands = {}
	
	#FUTURE TODO: This is almost, but not quite, the correct draw order.
	#For now, forcing points to be visible over the rest.
	orderedDrawCommands[10] = [] #forced-point layer
	for possibleDraw in style:
		var pd = style[possibleDraw].drawOps
		for do in pd:
			if !orderedDrawCommands.has(do.drawOrder):
				orderedDrawCommands[do.drawOrder] = []

	#entries has a dictionary, each entry is a big list of coord pairs
	for entry in theseentries:
		#If this entry isn't in our current style, skip it.
		if !style.has(str(int(entry.tid))):
			continue
		
		#if this entry doesn't possibly touch this tile, skip it.
		if !entry.envelope.intersects(thisArea):
			continue

		var thisStyle = style[str(int(entry.tid))]
		var lineSize = 1.0 * scale
	
		for s in thisStyle.drawOps:
			if entry.gt == 1: #points are getting forced to the top
				orderedDrawCommands[10].push_back({gt = entry.gt, p = entry.p, size = s.sizePx, color = s.color})
			else:
				orderedDrawCommands[s.drawOrder].push_back({gt = entry.gt, p = entry.p, size = s.sizePx, color = s.color})
		
	var drawLevels = orderedDrawCommands.keys()
	drawLevels.sort()
	drawLevels.reverse() 
	for entries in drawLevels:
		#These items are sorted server-side when the JSON is created, don't re-order them again.
		#orderedDrawCommands[entries].sort_custom(func(a,b) : return a.size > b.size)
		#orderedDrawCommands[entries].reverse()

		for odc in orderedDrawCommands[entries]:
			var points = odc.p
			if (scale != 1):
				points = odc.p.duplicate()
				for i in points.size():
					points[i] = points[i] * Vector2(scale, scale)
			
			if (odc.gt == 1):
				#this is just a circle for single points, size is roughly a Cell10
				#4.5 looks good for POIs, but bad for Trees, which there are quite a few of.
				#trees are size 0.2, so I should probably make other elements larger?
				#MOST of them shouldn't be points, but lines shouldn't be a Cell10 wide either.
				draw_circle(points[0], odc.size * 5.0 * scale, odc.color)
				draw_arc(points[0],1 + odc.size * 5.0 * scale, 0, TAU, 17, Color.BLACK)
			elif (odc.gt == 2):
				#This is significantly faster than calling draw_line for each of these.
				draw_polyline(points, odc.color, odc.size * scale, true) #antialias display image only.
			elif odc.gt == 3:
				#A single color, which is what I generally use.
				draw_colored_polygon(points, odc.color) 
