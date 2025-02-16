extends Node2D

#This is for drawing item NAMES onto a maptile from OfflineV2 data
#Its nearly identical in logic, except this will use the name index and make up a color for it.
#NOTE: drawOps are drawn in order, so the earlier one has the higher LayerId in PraxisMapper style language.
#the value/id/order is the MatchOrder for the style in PraxisMapper server

var theseentries = null
var thisscale = 1
var style

func DrawOfflineNameTile(entries, scale):
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
		if (entry.has("nid")):
			var thisStyle = style[str(entry.tid)]
			#THESE are the integer values, but Godot only makes colors with 0-1 range when passing them in.
			var r = (int(entry.nid) % 256) / 256.0
			var g = (int(entry.nid / 256) % 256) / 256.0
			var b = (int(entry.nid / 65536) % 256) / 256.0
			var nameColor = Color(r, g, b)
			var lineSize = 1.0 * scale
		
			for s in thisStyle.drawOps:
				if (entry.gt == 1):
					#this is just a circle for single points, size is in Cell10s
					#(The * 5 means we're drawing pixels as Cell-11s on the image)
					#4.5 looks good for POIs, but bad for Trees, which there are quite a few of.
					#trees are size 0.2, so I should probably make other elements larger?
					await draw_circle(entry.p[0], s.sizePx * 10.0 * scale, nameColor)
				elif (entry.gt == 2):
					await draw_polyline(entry.p, nameColor, s.sizePx * scale) #no antialiasing, colors matter.
				elif entry.gt == 3:
					await draw_colored_polygon(entry.p, nameColor) 
