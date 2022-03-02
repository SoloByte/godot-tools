extends Node2D

const DEBUG_LINE_TEMPLATE : PackedScene = preload("res://marching-squares/DebugLine.tscn")
const SIZE : Vector2 = Vector2(600,400)
const POS : Vector2 = Vector2(210, 100)
const RES : int = 100
const THRESHOLD : float = 0.6


var generator : MarchingSquaresGenerator

var map : Dictionary = {}
var zoff : float = 0.0


var maps : Array = []

var draw_debug : bool = false



#INFO
#try to use zoff for calculating edge in the noise variant
#is the zoff necessary? maybe just use vector2 for offset in the x,y direction -> can also be used in the non static variants
#z is height so it could be used for the edges



func _ready() -> void:
	randomize()
	generator = MarchingSquaresGenerator.new(POS, SIZE, RES, Vector2(4, 4), -1, 3.0, 15.0, 0.8)
	
#	map = generator.generateStatic(
#		THRESHOLD, 
#		true, 
#		true, 
#		Vector3.ZERO, 
#		MarchingSquaresGenerator.GENERATION_TYPE.LINES, 
#		{"width" : 5, "factor" : 0.25, "threshold" : 0.3, "depth" : 0.1}
#	)
	
	for y in range(2):
		for x in range(2):
			var m : Dictionary = generator.generateTiled(
				x, y, 0.0,
				THRESHOLD, 
				true, 
				MarchingSquaresGenerator.GENERATION_TYPE.LINES
			)
			maps.append(m)
	
	update() 
	
#	if map.has("lines") and map.lines.size() > 0:
#		spawnDebugLines(map.lines, RES / 8)

#func _process(delta: float) -> void:
#	map = generator.generateStatic(
#		THRESHOLD, 
#		true, 
#		true, 
#		Vector3(0,0,zoff), 
#		MarchingSquaresGenerator.GENERATION_TYPE.LINES, 
#		{"width" : 5, "factor" : 0.5, "threshold" : 0.4, "depth" : 0.1}
#	)
#
#	update() 
#	zoff += delta

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.scancode == KEY_TAB:
			if event.is_pressed():
				draw_debug = not draw_debug
				update()


func spawnDebugLines(lines : Array, w : float = 1.0, color := Color.white) -> void:
	for i in range(0, map.lines.size(), 2):
		var line = DEBUG_LINE_TEMPLATE.instance()
		add_child(line)
		line.spawn(map.lines[i], map.lines[i + 1], w, color) 

func _draw() -> void:
#	draw_rect(Rect2(POS - Vector2(RES,RES), SIZE + Vector2(RES,RES) * 2), Color.white, false, RES/ 4.0, true)
	
	if maps and maps.size() > 0:
		for m in maps:
			if draw_debug:
				draw_rect(m.bounds, Color(1, 1, 1, 0.5), false, RES/ 8.0, true)
				if m.field.size() > 0:
					for point in m.field:
						var pos := Vector2(point.x, point.y)
						var color := Color(1,0,0,0.2)
						if point.z >= THRESHOLD:
							color = Color(0,1,0,0.2)
						draw_circle(pos, RES / 8, color)
			if m.has("polygons") and m.polygons.size() > 0:
				for poly in m.polygons:
					draw_colored_polygon(poly, Color(1.0, 1.0, 1.0, 0.25))

			if m.has("lines") and m.lines.size() > 0:
				for i in range(0, m.lines.size(), 2):
					draw_line(m.lines[i], m.lines[i + 1], Color.white, RES / 8.0, true)
		
	if map:
		if draw_debug:
			if map.field.size() > 0:
				for point in map.field:
					var pos := Vector2(point.x, point.y)
					var color := Color.red
					if point.z >= THRESHOLD:
						color = Color.green
					draw_circle(pos, RES / 8, color)
	#		if map.cases.size() > 0:
	#			for i in range(map.cases.size()):
	#				var case = map.cases[i]
	#				var pos : Vector2 = Vector2(map.field[i].x, map.field[i].y) + Vector2(RES, RES) * 0.5
	#				var default_font = Control.new().get_font("font")
	#				draw_string(default_font, pos, str(case))


		if map.has("polygons") and map.polygons.size() > 0:
			for poly in map.polygons:
				draw_colored_polygon(poly, Color(1.0, 1.0, 1.0, 0.25))

		if map.has("lines") and map.lines.size() > 0:
			for i in range(0, map.lines.size(), 2):
				draw_line(map.lines[i], map.lines[i + 1], Color.white, RES / 8.0, true)
	
	
	


