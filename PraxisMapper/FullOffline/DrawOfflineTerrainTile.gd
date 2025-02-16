extends Node2D

#This is for drawing map tiles directly in the client from Offline/V2 data
#This file handles terrain IDs, so that terrain types and unnamed places can be identified by the game.
#NOTE: drawOps are drawn in order, so the earlier one has the higher LayerId in PraxisMapper style language.
#the value/id/order is the MatchOrder for the style in PraxisMapper server

var theseentries = null
var thisscale = 1
var style

func DrawOfflineTerrainTile(entries, scale):
	theseentries = entries
	thisscale = scale
	queue_redraw()

func _draw():
	if theseentries == null:
		return
	
	var scale = thisscale
	var width = 320 * 20 # 6400
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
	draw_colored_polygon(bgCoords, Color.BLACK) 
	
	for entry in theseentries:
		var r = (int(entry.tid) % 256) / 256.0
		var g = (int(entry.tid / 256) % 256) / 256.0
		var b = (int(entry.tid / 65536) % 256) / 256.0
		var terrainColor = Color(r, g, b)
		var lineSize = 1.0 * scale
		var thisStyle = style[str(entry.tid)]
		
		for s in thisStyle.drawOps:
			if (entry.gt == 1):
				await draw_circle(entry.p[0], s.sizePx * 10.0 * scale, terrainColor)
			elif (entry.gt == 2):
				await draw_polyline(entry.p, terrainColor, s.sizePx * scale)
			elif entry.gt == 3:
				await draw_colored_polygon(entry.p, terrainColor) 
