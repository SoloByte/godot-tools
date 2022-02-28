extends Node2D


const SIZE : Vector2 = Vector2(1500,900)
const POS : Vector2 = Vector2(210, 100)
const RES : int = 25

var generator : MarchingSquaresGenerator

var map : Dictionary = {}
var zoff : float = 0.0

func _ready() -> void:
	randomize()
	generator = MarchingSquaresGenerator.new(POS, SIZE, RES, Vector2(1, 1), -1, 9.0, 10.0, 5.0)
	
#	map = generator.generateStaticLines(0.0, 0.4, true, 0.1)
	map = generator.generateStaticPolygons(0.0, 0.4, true, 0.1)
	update()

#func _process(delta: float) -> void:
#	map = generator.generateStaticLines(zoff, 0.4, true)
#	update()
#	zoff += delta * 0.1



func _draw() -> void:
#	draw_rect(Rect2(POS - Vector2(RES,RES), SIZE + Vector2(RES,RES) * 2), Color.white, false, RES/ 4.0, true)
	if not map: return
	
#	if map.field.size() > 0:
#		for point in map.field:
#			var pos := Vector2(point.x, point.y)
#	#		var value : float = (point.z + 1) * 0.5
#			draw_circle(pos, RES / 8, Color(0,0,1,point.z))
	
	if map.has("polygons") and map.polygons.size() > 0:
		for poly in map.polygons:
			draw_colored_polygon(poly, Color(1.0, 1.0, 1.0, 0.25))
	
	if map.has("lines") and map.lines.size() > 0:
		for i in range(0, map.lines.size(), 2):
			draw_line(map.lines[i], map.lines[i + 1], Color.white, RES / 8.0, true)
	
	
	
#	if map.cases.size() > 0:
#		for i in range(map.cases.size()):
#			var case = map.cases[i]
#			var pos : Vector2 = Vector2(map.field[i].x, map.field[i].y) + Vector2(RES, RES) * 0.5
#			var default_font = Control.new().get_font("font")
#			draw_string(default_font, pos, str(case))

