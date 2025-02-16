extends Node2D
#This is for drawing map tiles directly in the client from OfflineV2 data
#NOTE: drawOps are drawn in order, so the earlier one has the higher LayerId in PraxisMapper style language.
#the value/id/order is the MatchOrder for the style in PraxisMapper server

var theseentries = null
var thisscale = 1
var showCurrentLocation = false
var style

func DrawOfflineTile(entries, scale):
	theseentries = entries
	thisscale = scale
	queue_redraw()

func _draw():
	if theseentries == null:
		return

	var scale = thisscale
	var width = 20 * 20 #= 400
	var height = 20 * 20 #= 400
	#REMEMBER: PlusCode origin is at the BOTTOM-left, these draw calls use the TOP left.
	#This should do the same invert drawing that PraxisMapper does server-side.
	draw_set_transform(Vector2(0,0), 0, Vector2(1,-1))
	
	var bgCoords = PackedVector2Array()
	bgCoords.append(Vector2(0,0))
	bgCoords.append(Vector2(width * scale,0))
	bgCoords.append(Vector2(width * scale,height * scale))
	bgCoords.append(Vector2(0,height * scale))
	bgCoords.append(Vector2(0,0))
	draw_colored_polygon(bgCoords, "#f2eef9") 
	
	for entry in theseentries:
		var thisStyle = style[str(entry.tid)]		
		var point = entry.c.split(",")
		var center = Vector2(int(point[0]) * scale, int(point[1]) * scale)
		for s in thisStyle.drawOps:
			draw_circle(center, entry.r, "#" + s.color)
			#Alternative: rectangles can be drawn with the same data. Might make this a toggle option later
			#draw_rect(Rect2(center.x - entry.r, center.y - entry.r, entry.r * 2, entry.r * 2), "#" + s.color, true)
			
	#TODO: this might be better served as a new node inside this one, only drawing
	#and updating this instead of redrawing the whole map each movement.
	if showCurrentLocation:
		#draw lines that intersect at our current position
		var ourPoint = PraxisCore.currentPlusCode.replace("+", "")
		var xLinePlace = (PlusCodes.GetLetterIndex(ourPoint[7]) * 20) + PlusCodes.GetLetterIndex(ourPoint[9])
		var yLinePlace = (PlusCodes.GetLetterIndex(ourPoint[6]) * 20) + PlusCodes.GetLetterIndex(ourPoint[8])
		draw_line(Vector2(xLinePlace, 0), Vector2(xLinePlace, 400), Color.RED, 2, false)
		draw_line(Vector2(0, yLinePlace), Vector2(400, yLinePlace), Color.RED, 2, false)
		draw_arc(Vector2(xLinePlace, yLinePlace), 5, 0, TAU, 33, Color.RED, 2, false)
