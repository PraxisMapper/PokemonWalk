extends Node2D
class_name DrawOfflineTile

#This is for drawing map tiles directly in the client from Offline/V2 data

var theseentries = null
var thisscale = 1

#NOTE: drawOps are drawn in order, so the earlier one has the higher LayerId in PraxisMapper style language.
#the value/id/order is the MatchOrder for the style in PraxisMapper server


#This is set from outside.
var style #same logic as for NameTiles


func DrawOfflineTile(entries, scale):
	theseentries = entries
	thisscale = scale
	queue_redraw()

func _draw():
	if theseentries == null:
		return
	
	var scale = thisscale
	var width = 320 * 20 # 6400 # should be scaled?
	var height = 500 * 20 #= 10000
	#REMEMBER: PlusCode origin is at the BOTTOM-left, these draw calls use the TOP left.
	#This should do the same invert drawing that PraxisMapper does server-side.
	draw_set_transform(Vector2(0,0), 0, Vector2(1,-1))

	var bgCoords = PackedVector2Array()
	bgCoords.append(Vector2(0,0))
	bgCoords.append(Vector2(width * scale,0))
	bgCoords.append(Vector2(width * scale,height * scale))
	bgCoords.append(Vector2(0,height * scale))
	bgCoords.append(Vector2(0,0))
	draw_colored_polygon(bgCoords, style["9999"].drawOps[0].color) 
	var orderedDrawCommands = {}
	
	#entries has a dictionary, each entry is a big list of coord pairs
	for entry in theseentries:
		#If this entry isn't in our current style, skip it.
		if !style.has(str(entry.tid)):
			continue
		
		var thisStyle = style[str(entry.tid)]
		var lineSize = 1.0 * scale

		for possibleDraw in style:
			var pd = style[possibleDraw].drawOps
			for do in pd:
				if !orderedDrawCommands.has(do.drawOrder):
					orderedDrawCommands[do.drawOrder] = []
		
		for s in thisStyle.drawOps:
			orderedDrawCommands[s.drawOrder].push_back({gt = entry.gt, p = entry.p, size = s.sizePx, color = s.color})
		
	var drawLevels = orderedDrawCommands.keys()
	drawLevels.sort()
	drawLevels.reverse()
	for entries in drawLevels:
		#These items are sorted server-side when the JSON is created, don't re-order them again.
		#orderedDrawCommands[entries].sort_custom(func(a,b) : return a.size > b.size)

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
				await draw_circle(points[0], odc.size * 5.0 * scale, odc.color)
			elif (odc.gt == 2):
				#This is significantly faster than calling draw_line for each of these.
				await draw_polyline(points, odc.color, odc.size * scale, true) #antialias display image only.
			elif odc.gt == 3:
				#A single color, which is what I generally use.
				await draw_colored_polygon(points, odc.color) 
