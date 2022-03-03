extends Node2D

const DEBUG_LINE_TEMPLATE : PackedScene = preload("res://marching-squares/DebugLine.tscn")
const SIZE : Vector2 = Vector2(1500,900)
const POS : Vector2 = Vector2(210, 100)
const RES : int = 25
const THRESHOLD : float = 0.45

onready var canvas = get_tree().root.world_2d.canvas
var canvas_item 


var generator : MarchingSquaresGenerator

var map : Dictionary = {}
var iso_circles : Array = []
var meta_balls : Array = []
var zoff : float = 0.0
var vis_radius : float = 150.0
onready var vis_radius_sq : float = vis_radius * vis_radius

#var maps : Array = []

var draw_debug : bool = true



#INFO
#try to use zoff for calculating edge in the noise variant
#is the zoff necessary? maybe just use vector2 for offset in the x,y direction -> can also be used in the non static variants
#z is height so it could be used for the edges

func _exit_tree():
	VisualServer.canvas_item_clear(canvas_item)

#func _process(delta):
##	update()
#	VisualServer.canvas_item_clear(canvas_item)
#	canvas_item = VisualServer.canvas_item_create()
#	VisualServer.canvas_item_set_parent(canvas_item, canvas)
#	var mouse_pos : Vector2 = get_global_mouse_position()
#	var max_dis : float = 150.0
#	if map:
#		if map.field.size() > 0:
#			for point in map.field:
#				var pos := Vector2(point.x, point.y)
#				if (mouse_pos.distance_squared_to(pos) < vis_radius_sq):
#					var color := Color.red
#					if point.state >= 1.0:
#						color = Color.green
#					VisualServer.canvas_item_add_circle(canvas_item, pos, RES / 8, color)
#
#		if map.has("lines") and map.lines.size() > 0:
#			for i in range(0, map.lines.size(), 2):
#				if mouse_pos.distance_squared_to((map.lines[i] + map.lines[i + 1]) * 0.5) >= vis_radius_sq: continue
#				VisualServer.canvas_item_add_line(canvas_item, map.lines[i], map.lines[i + 1], Color.white, RES / 8.0, true)


func _ready() -> void:
	randomize()
	
#	debug_test_polyline_performance()
	canvas_item = VisualServer.canvas_item_create()
	VisualServer.canvas_item_set_parent(canvas_item, canvas)
	generator = MarchingSquaresGenerator.new(Vector2.ZERO, RES, -1, true, 3.0, 15.0, 0.8)
	
	iso_circles = generator.generateIsoCircles(Rect2(POS, SIZE), Vector2(1, 1), Vector2(50, 300), Vector2(0.5, 0.75))
#	iso_circles = []
#	meta_balls = generator.generateMetaballs(Rect2(POS, SIZE), Vector2(32, 36), Vector2(50, 100), Vector2(0.5, 0.6))
#	meta_balls = []
	
	map = generator.generateStaticNoise(
		POS,
		SIZE,
		THRESHOLD, 
		Vector3.ZERO, 
		MarchingSquaresGenerator.GENERATION_TYPE.LINES, 
		{"width" : 5, "factor" : 0.25, "threshold" : 0.3, "depth" : 0.1},
		iso_circles
	)
	
#	map = generator.generateStaticRNG(
#		POS,
#		SIZE,
#		THRESHOLD,
#		MarchingSquaresGenerator.GENERATION_TYPE.LINES, 
#		{"width" : 5, "factor" : 0.25, "threshold" : 0.3, "depth" : 0.1},
#		iso_circles,
#		meta_balls
#	)
	
	if map:
		if draw_debug:
			if map.field.size() > 0:
				for point in map.field:
					var pos := Vector2(point.x, point.y)
					var color := Color.red
					if point.state >= 1.0:
						color = Color.green
					VisualServer.canvas_item_add_circle(canvas_item, pos, RES / 8, color)

			if map.iso_circles.size() > 0:
				for circle in map.iso_circles:
					VisualServer.canvas_item_add_circle(canvas_item, Vector2(circle.x, circle.y), circle.radius, Color(0,0,1,0.5))
			
			if map.has("meta_balls") and map.meta_balls.size() > 0:
				for circle in map.meta_balls:
					VisualServer.canvas_item_add_circle(canvas_item, Vector2(circle.x, circle.y), circle.radius, Color(0,0,1,0.5))


		if map.has("polygons") and map.polygons.size() > 0:
			for poly in map.polygons:
				VisualServer.canvas_item_add_polygon(canvas_item, poly, [Color(1.0, 1.0, 1.0, 0.25)])

		if map.has("lines") and map.lines.size() > 0:
			for i in range(0, map.lines.size(), 2):
				VisualServer.canvas_item_add_line(canvas_item, map.lines[i], map.lines[i + 1], Color.white, RES / 8.0, true)
				

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.scancode == KEY_TAB:
			if event.is_pressed():
				draw_debug = not draw_debug
#				update()
	elif event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_UP:
			vis_radius = wrapf(vis_radius + 15, 15.0, 600)
			vis_radius_sq = vis_radius * vis_radius
		elif event.button_index == BUTTON_WHEEL_DOWN:
			vis_radius = wrapf(vis_radius - 15, 15.0, 600)
			vis_radius_sq = vis_radius * vis_radius


#func spawnDebugLines(lines : Array, w : float = 1.0, color := Color.white) -> void:
#	for i in range(0, map.lines.size(), 2):
#		var line = DEBUG_LINE_TEMPLATE.instance()
#		add_child(line)
#		line.spawn(map.lines[i], map.lines[i + 1], w, color) 

#func _draw():
#	if map:
#		var mouse_pos : Vector2 = get_global_mouse_position()
#		if draw_debug:
#			if map.field.size() > 0:
#				for point in map.field:
#					var pos := Vector2(point.x, point.y)
#					if (mouse_pos.distance_squared_to(pos) < VISIBILITY_RADIUS * VISIBILITY_RADIUS):
#						var color := Color.red
#						if point.state >= 1.0:
#							color = Color.green
#						draw_circle(pos, RES / 8, color)
#
##			if map.iso_circles.size() > 0:
##				for circle in map.iso_circles:
##					draw_circle(Vector2(circle.x, circle.y), circle.radius, Color(0,0,1,0.5))
#	#		if map.cases.size() > 0:
#	#			for i in range(map.cases.size()):
#	#				var case = map.cases[i]
#	#				var pos : Vector2 = Vector2(map.field[i].x, map.field[i].y) + Vector2(RES, RES) * 0.5
#	#				var default_font = Control.new().get_font("font")
#	#				draw_string(default_font, pos, str(case))
#
#
#		if map.has("polygons") and map.polygons.size() > 0:
#			for poly in map.polygons:
#				draw_colored_polygon(poly, Color(1.0, 1.0, 1.0, 0.25))
#
#		if map.has("lines") and map.lines.size() > 0:
#			for i in range(0, map.lines.size(), 2):
#				if mouse_pos.distance_squared_to((map.lines[i] + map.lines[i + 1]) * 0.5) >= VISIBILITY_RADIUS * VISIBILITY_RADIUS: continue
#				draw_line(map.lines[i], map.lines[i + 1], Color.white, RES / 8.0, true)
	
	
	


#	for y in range(2):
#		for x in range(2):
#			var m : Dictionary = generator.generateTiled(
#				x, y, 0.0,
#				THRESHOLD, 
#				true, 
#				MarchingSquaresGenerator.GENERATION_TYPE.LINES
#			)
#			maps.append(m)





func debug_test_polyline_performance() -> void:
	var start : Vector2 = Vector2(1920, 1080) * 0.5
	var end : Vector2 = start + Vector2(1, 1)
	var polyline : PoolVector2Array = []
	polyline.append(start)
	polyline.append(end)
	for i in range(4000):
		var angle : float = randf() * PI * 2.0
		var length : float = randf() * 5.0
		start = end
		end += Vector2.RIGHT.rotated(angle) * length
		polyline.append(start)
		polyline.append(end)
	
#		var line := DEBUG_LINE_TEMPLATE.instance()
#		add_child(line)
#		line.spawn(start, end, 10, Color.white)
	VisualServer.canvas_item_add_polyline(canvas_item, polyline, [Color.white], 5, false)
