extends Node2D

#This is for drawing item NAMES onto a maptile from OfflineV2 data
#Its nearly identical in logic to drawing the visible map,
#except this will use the name index and make up a color for it.
#NOTE: drawOps are drawn in order, so the earlier one has the higher LayerId
#in PraxisMapper style language. the value/id/order is the MatchOrder 
#for the style in PraxisMapper server

var theseentries = null
var thisscale = 1
var style #admin bounds style, not maptiles.

func DrawOfflineBoundsTile(entries, scale):
	theseentries = entries
	thisscale = scale
	queue_redraw()

func _draw():
	if theseentries == null:
		return
	
	var scale = thisscale
	var width = 20 * 20
	var height = 20 * 20
	#REMEMBER: PlusCode origin is at the BOTTOM-left, these draw calls use the TOP left.
	#This should do the same invert drawing that PraxisMapper does server-side.
	draw_set_transform(Vector2(0,0), 0, Vector2(1,-1))
	
	var bgCoords = PackedVector2Array()
	bgCoords.append(Vector2(0,0))
	bgCoords.append(Vector2(width * scale,0))
	bgCoords.append(Vector2(width * scale,height * scale))
	bgCoords.append(Vector2(0,height * scale))
	bgCoords.append(Vector2(0,0))
	draw_colored_polygon(bgCoords, Color.BLACK) 
	
	#entries has a big list of coord sets as strings
	for entry in theseentries:	
		if (entry.has("nid")):
			#THESE are the integer values, but Godot only makes colors with 0-1 range when passing them in.
			var r = (int(entry.nid) % 256) / 256.0
			var g = (int(entry.nid / 256) % 256) / 256.0
			var b = (int(entry.nid / 65536) % 256) / 256.0
			var nameColor = Color(r, g, b)
			var lineSize = 1.0 * scale

			var point = entry.c.split(",")
			var center = Vector2(int(point[0]) * scale, int(point[1]) * scale)
			draw_circle(center, entry.r, nameColor)

func Close():
	queue_free()
