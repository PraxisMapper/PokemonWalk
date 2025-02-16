extends Node2D

var theseentries = null
var thisscale = 1

#This is set from outside.
var style #admin bounds styles


func DrawOfflineBoundsTile(entries, scale):
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
	
	#entries has a big list of coord sets as strings
	for entry in theseentries:
		#If this entry isn't in our current style, skip it.
		if !style.has(str(entry.tid)):
			continue
		
		if (entry.has("nid")):
			#THESE are the integer values, but Godot only makes colors with 0-1 range when passing them in.
			var r = (int(entry.nid) % 256) / 256.0
			var g = (int(entry.nid / 256) % 256) / 256.0
			var b = (int(entry.nid / 65536) % 256) / 256.0
			var nameColor = Color(r, g, b)
			var lineSize = 1.0 * scale
		
			#These are admin bounds, 99% of these should be polygons.
			#for s in thisStyle.drawOps:
			if (entry.gt == 1):
				#this is just a circle for single points, size is roughly a Cell10
				await draw_circle(entry.p[0], 20 * 10.0 * scale, nameColor)
			elif (entry.gt == 2):
				#This is significantly faster than calling draw_line for each of these.
				await draw_polyline(entry.p, nameColor, 5 * scale * 5) #no antialiasing, colors matter.
			elif entry.gt == 3:
				#A single color, which is all I need for names
				await draw_colored_polygon(entry.p, nameColor) 
