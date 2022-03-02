extends Node2D

const DEBUG_LINE_TEMPLATE : PackedScene = preload("res://marching-squares/DebugLine.tscn")
const SIZE : Vector2 = Vector2(1500,900)
const POS : Vector2 = Vector2(210, 100)
const RES : int = 50
const THRESHOLD : float = 0.3


var generator : MarchingSquaresGenerator

var map : Dictionary = {}
var zoff : float = 0.0


var draw_debug : bool = false



#INFO
#try to use zoff for calculating edge in the noise variant
#is the zoff necessary? maybe just use vector2 for offset in the x,y direction -> can also be used in the non static variants
#z is height so it could be used for the edges



func _ready() -> void:
	randomize()
	generator = MarchingSquaresGenerator.new(POS, SIZE, RES, Vector2(1, 1), -1, 9.0, 10.0, 5.0)
	
#	map = generator.generateStaticLines(0.0, 0.4, true, 0.1)
	map = generator.generateStatic(Vector3.ZERO, THRESHOLD, true, true, MarchingSquaresGenerator.GENERATION_TYPE.LINES, {"width" : 5, "factor" : 0.25, "threshold" : 0.65, "depth" : 0.01})
	update() 
	
#	if map.has("lines") and map.lines.size() > 0:
#		spawnDebugLines(map.lines, RES / 8)

#func _process(delta: float) -> void:
#	map = generator.generateStaticLines(zoff, THRESHOLD, true, true, Vector2.ZERO)
#	update()
#	zoff += delta * 0.01

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
	if not map: return
	
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
	
	
	


