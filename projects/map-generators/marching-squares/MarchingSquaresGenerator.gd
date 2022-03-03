class_name MarchingSquaresGenerator


enum GENERATION_TYPE {
	CASES = 0,
	LINES = 1,
	FILLED = 2,
	OUTLINE_FILLED = 3
}

enum MARCH_TYPE {
	CASES = 0,
	LINES = 1,
	POLYGONS = 2
}


var rng : RandomNumberGenerator
var noise : OpenSimplexNoise = null
var noise_origin := Vector3.ZERO
var origin := Vector2.ZERO
var resolution : int = 0
var use_interpolation : bool = true
#var cols : int = 0
#var rows : int = 0
#var noise_increment := Vector2(0.1,0.1)
#var size := Vector2.ZERO


func hasNoise() -> bool:
	return noise != null




#add metaballs generate function (just uses rng and circles for field generation) -> has 1 global threshold

#remove size and pos -> is used in generate functions instead
#test if removing the increment and using the res as increment works better
#add origin
func _init(origin : Vector2, res : int, n_seed : int = -1, interpolate : bool = true, use_noise : bool = true, n_octaves : float = 3.0, n_period : float = 15.0, n_persistence : float = 0.8) -> void:
	rng = RandomNumberGenerator.new()
	if n_seed > -1:
		rng.seed = n_seed
	else:
		rng.randomize()
	
	
	if use_noise:
		noise = OpenSimplexNoise.new()
	
		if n_seed > -1:
			noise.seed = n_seed
		else:
			noise.seed = randi()
		
		noise.octaves = min(n_octaves, 9.0)
		noise.period = n_period
		noise.persistence = n_persistence
	
	resolution = res
	self.origin = origin
	self.use_interpolation = interpolate
	self.noise_origin = Vector3(origin.x, origin.y, 0)
#	noise_offset_factor.x = n_increment.x / resolution as float
#	noise_offset_factor.y = n_increment.y / resolution as float
	
#	cols = size.x / res 
#	rows = size.y / res
#	cols += 1
#	rows += 1



func generateStatic(pos : Vector2, size : Vector2, threshold : float = 0.5, n_offset := Vector3(0,0,0), type : int = GENERATION_TYPE.LINES, edge : Dictionary = {}, iso_circles : Array = []) -> Dictionary:
	var bounds := Rect2(origin + pos, size)
	var map : Dictionary = {"res" : resolution, "bounds" : bounds, "rows" : getRows(size.y), "cols" : getCols(size.x), "iso_circles" : iso_circles}
	
	map["field"] = generateField(bounds, n_offset, threshold, hasNoise(), edge, iso_circles)
	
	match type:
		GENERATION_TYPE.CASES:
			map["cases"] = march(map.field, bounds, MARCH_TYPE.CASES, threshold, use_interpolation)
		GENERATION_TYPE.LINES:
			map["lines"] = march(map.field, bounds, MARCH_TYPE.LINES, threshold, use_interpolation)
		GENERATION_TYPE.FILLED:
			map["polygons"] = march(map.field, bounds, MARCH_TYPE.POLYGONS, threshold, use_interpolation)
		GENERATION_TYPE.OUTLINE_FILLED:
			map["lines"] = march(map.field, bounds, MARCH_TYPE.LINES, threshold, use_interpolation)
			map["polygons"] = march(map.field, bounds, MARCH_TYPE.POLYGONS, threshold, use_interpolation)
	
	return map

#edge : Dictionary = {"width" : 0.0, "factor" : 0.0, "threshold" : 0.0, "depth" : 0.0}
func generateField(bounds : Rect2, n_offset : Vector3, threshold : float = 0.5, use_noise : bool = true, edge : Dictionary = {}, iso_circles : Array = []) -> Array:
	var rows : int = getRows(bounds.size.y)
	var cols : int = getCols(bounds.size.x)
	var noise_offset : Vector3 = noise_origin + n_offset
	var start : Vector2 = bounds.position
	var field : Array = []
	
	for j in range(0, rows):
		if use_noise:
			noise_offset.y += resolution
		
		for i in range(0, cols):
#			var width : int = getMinDis(i, j, cols - 1, rows - 1)
			var value : float = 0.0
			if use_noise:
				value = noise.get_noise_3d(noise_offset.x, noise_offset.y, noise_offset.z)
				value = (value + 1.0) * 0.5
				if edge.size() >= 4 and edge.has("depth"):
					edge["value"] = (noise.get_noise_3d(noise_offset.x, noise_offset.y, noise_offset.z + edge.depth) + 1.0) * 0.5
					value *= getEdgeFactor(i, j, cols - 1, rows - 1, edge)
			else:
				value = rng.randf()
				if edge.size() >= 2:
					value *= getEdgeFactor(i, j, cols - 1, rows - 1, edge)
			
			var pos := Vector2(start.x + i * resolution, start.y + j * resolution)
			var state : int = 0
			if iso_circles.size() <= 0:
				state = getState(value, threshold)
			else:
				state = getStateIsocircles(pos, iso_circles, value, threshold)
			
#			field.append(Quat(pos.x, pos.y, value, state))
			field.append(FieldPoint.new(pos.x, pos.y, value, state))
			if use_noise:
				noise_offset.x += resolution
	
	return field

func march(field : Array, bounds : Rect2, march_type : int = MARCH_TYPE.LINES, threshold : float = 0.5, interpolate : bool = true) -> Array:
	var rows : int = getRows(bounds.size.y)
	var cols : int = getCols(bounds.size.x)
	var generated : Array = []
	for j in range(0, rows - 1):
		for i in range(0, cols - 1):
			var index : int = i + j * cols
			
			var top_left : FieldPoint = field[index]
			var top_right : FieldPoint = field[index + 1]
			var bottom_right : FieldPoint = field[index + 1 + cols]
			var bottom_left : FieldPoint = field[index + cols]
			
			var case : int = getCase(top_left.state, top_right.state, bottom_right.state, bottom_left.state)
			if march_type == MARCH_TYPE.CASES:
				generated.append(case)
			elif march_type == MARCH_TYPE.LINES:
				match case:
					1:
						generated.append(getMidpoint(top_left, bottom_left, threshold, interpolate))
						generated.append(getMidpoint(bottom_left, bottom_right, threshold, interpolate))
					14:
						generated.append(getMidpoint(top_left, bottom_left, threshold, interpolate))
						generated.append(getMidpoint(bottom_left, bottom_right, threshold, interpolate))
					
					2:
						generated.append(getMidpoint(top_right, bottom_right, threshold, interpolate))
						generated.append(getMidpoint(bottom_left, bottom_right, threshold, interpolate))
					13:
						generated.append(getMidpoint(top_right, bottom_right, threshold, interpolate))
						generated.append(getMidpoint(bottom_left, bottom_right, threshold, interpolate))
					
					3:
						generated.append(getMidpoint(top_left, bottom_left, threshold, interpolate))
						generated.append(getMidpoint(top_right, bottom_right, threshold, interpolate))
					12:
						generated.append(getMidpoint(top_left, bottom_left, threshold, interpolate))
						generated.append(getMidpoint(top_right, bottom_right, threshold, interpolate))
					
					4:
						generated.append(getMidpoint(top_left, top_right, threshold, interpolate))
						generated.append(getMidpoint(top_right, bottom_right, threshold, interpolate))
					11:
						generated.append(getMidpoint(top_left, top_right, threshold, interpolate))
						generated.append(getMidpoint(top_right, bottom_right, threshold, interpolate))
					
					5:
						generated.append(getMidpoint(top_left, top_right, threshold, interpolate))
						generated.append(getMidpoint(top_right, bottom_right, threshold, interpolate))
						generated.append(getMidpoint(top_left, bottom_left, threshold, interpolate))
						generated.append(getMidpoint(bottom_left, bottom_right, threshold, interpolate))
					10:
						generated.append(getMidpoint(top_left, top_right, threshold, interpolate))
						generated.append(getMidpoint(top_left, bottom_left, threshold, interpolate))
						generated.append(getMidpoint(bottom_left, bottom_right, threshold, interpolate))
						generated.append(getMidpoint(top_right, bottom_right, threshold, interpolate))
					
					6:
						generated.append(getMidpoint(top_left, top_right, threshold, interpolate))
						generated.append(getMidpoint(bottom_left, bottom_right, threshold, interpolate))
					9:
						generated.append(getMidpoint(top_left, top_right, threshold, interpolate))
						generated.append(getMidpoint(bottom_left, bottom_right, threshold, interpolate))
					
					7:
						generated.append(getMidpoint(top_left, top_right, threshold, interpolate))
						generated.append(getMidpoint(top_left, bottom_left, threshold, interpolate))
					8:
						generated.append(getMidpoint(top_left, top_right, threshold, interpolate))
						generated.append(getMidpoint(top_left, bottom_left, threshold, interpolate))
			else:
				match case:
					15:
						var polygon : PoolVector2Array = [
							top_left,
							top_right,
							bottom_right,
							bottom_left
						]
						generated.append(polygon)
					1:
						var polygon : PoolVector2Array = [
							getMidpoint(top_left, bottom_left, threshold, interpolate),
							getMidpoint(bottom_left, bottom_right, threshold, interpolate),
							bottom_left
						]
						generated.append(polygon)
					14:
						var polygon : PoolVector2Array = [
							top_left, top_right, bottom_right,
							getMidpoint(bottom_left, bottom_right, threshold, interpolate),
							getMidpoint(top_left, bottom_left, threshold, interpolate)]
						generated.append(polygon)
					2:
						var polygon : PoolVector2Array = [
							getMidpoint(top_right, bottom_right, threshold, interpolate),
							bottom_right,
							getMidpoint(bottom_left, bottom_right, threshold, interpolate)
						]
						generated.append(polygon)
					13:
						var polygon : PoolVector2Array = [
							top_left,
							top_right,
							getMidpoint(top_right, bottom_right, threshold, interpolate),
							getMidpoint(bottom_left, bottom_right, threshold, interpolate),
							bottom_left
						]
						generated.append(polygon)
					
					3:
						var polygon : PoolVector2Array = [
							getMidpoint(top_left, bottom_left, threshold, interpolate),
							getMidpoint(top_right, bottom_right, threshold, interpolate),
							bottom_right,
							bottom_left
						]
						generated.append(polygon)
					12:
						var polygon : PoolVector2Array = [
							top_left,
							top_right,
							getMidpoint(top_right, bottom_right, threshold, interpolate),
							getMidpoint(top_left, bottom_left, threshold, interpolate)
						]
						generated.append(polygon)
					
					4:
						var polygon : PoolVector2Array = [
							getMidpoint(top_left, top_right, threshold, interpolate),
							top_right,
							getMidpoint(top_right, bottom_right, threshold, interpolate)
						]
						generated.append(polygon)
					11:
						var polygon : PoolVector2Array = [
							top_left,
							getMidpoint(top_left, top_right, threshold, interpolate),
							getMidpoint(top_right, bottom_right, threshold, interpolate),
							bottom_right,
							bottom_left
						]
						generated.append(polygon)
					
					5:
						var polygon : PoolVector2Array = [
							getMidpoint(top_left, top_right, threshold, interpolate),
							top_right,
							getMidpoint(top_right, bottom_right, threshold, interpolate),
							getMidpoint(bottom_left, bottom_right, threshold, interpolate),
							bottom_left,
							getMidpoint(top_left, bottom_left, threshold, interpolate)
						]
						generated.append(polygon)
					10:
						var polygon : PoolVector2Array = [
							top_left,
							getMidpoint(top_left, top_right, threshold, interpolate),
							getMidpoint(top_right, bottom_right, threshold, interpolate),
							bottom_right,
							getMidpoint(bottom_left, bottom_right, threshold, interpolate),
							getMidpoint(top_left, bottom_left, threshold, interpolate)
						]
						generated.append(polygon)
					
					6:
						var polygon : PoolVector2Array = [
							getMidpoint(top_left, top_right, threshold, interpolate),
							top_right,
							bottom_right,
							getMidpoint(bottom_left, bottom_right, threshold, interpolate)
						]
						generated.append(polygon)
					9:
						var polygon : PoolVector2Array = [
							top_left,
							getMidpoint(top_left, top_right, threshold, interpolate),
							getMidpoint(bottom_left, bottom_right, threshold, interpolate),
							bottom_left
						]
						generated.append(polygon)
					
					7:
						var polygon : PoolVector2Array = [
							getMidpoint(top_left, top_right, threshold, interpolate),
							top_right,
							bottom_right,
							bottom_left,
							getMidpoint(top_left, bottom_left, threshold, interpolate)
						]
						generated.append(polygon)
					8:
						var polygon : PoolVector2Array = [
							top_left,
							getMidpoint(top_left, top_right, threshold, interpolate),
							getMidpoint(top_left, bottom_left, threshold, interpolate)
						]
						generated.append(polygon)
			
	return generated



func generateMetaballs(amount_range : Vector2, radius_range : Vector2, value_range : Vector2) -> Array:
	return []

func generateIsoCircles(bounds : Rect2, amount_range : Vector2, radius_range : Vector2, threshold_range : Vector2) -> Array:
	var amount : int = rng.randi_range(amount_range.x, amount_range.y)
	var circles : Array = []
	for i in range(amount):
		var x : float = rng.randf_range(0, bounds.size.x) + bounds.position.x + origin.x
		var y : float = rng.randf_range(0, bounds.size.y) + bounds.position.y + origin.y
		var r : float = rng.randf_range(radius_range.x, radius_range.y)
		var v : float = rng.randf_range(threshold_range.x, threshold_range.y)
#		var angle : float = rng.randf() * PI * 2.0
#		var length : float = rng.randf_range(5, 25)
		circles.append({"x" : x, "y" : y, "radius" : r, "value" : v})#, "vel" : Vector2.RIGHT.rotated(angle) * length})
	return circles

func getStateIsocircles(pos : Vector2, circls : Array, value : float, threshold : float) -> int:
	var sum : float = 0
	var inside : float = 0
	for c in circls:
		var dis_sq : float = (pos - Vector2(c.x, c.y)).length_squared()
		if dis_sq <= c.radius * c.radius:
			inside += 1
			sum += c.value
	
	if inside <= 0:
		return getState(value, threshold)
	else:
		if value > sum / inside:
			return 1
	
	return 0

func getMinDis(i : int, j : int, cols : int, rows : int) -> float:
	return min( min(i, cols - i), min(j, rows - j))

func getEdgeFactor(i : int, j : int, cols : int, rows : int, edge : Dictionary) -> float:
	if not edge.has("width") or not edge.has("factor"): return 1.0
	if edge.width <= 0.0: return 1.0
	var width : int = getMinDis(i, j, cols, rows)
	
	
	if width <= 0:
		return 0.0
	
	if edge.has("value"):
		if width > edge.width:
			return 1.0
		
		if edge.value < edge.threshold:
			return edge.factor
		else:
			return 1.0
	else:
		if rng.randf() > width / edge.width:
			return edge.factor
	
	return 1.0

func getDistanceFactor(i : int, j : int, cols : int, rows : int, f : float = 1.0) -> float:
	var min_v : float = min(rows - j, j)
	var min_h : float = min(cols - i, i)
	if min_v < min_h:
		var max_dis : float = ceil( max(rows * 0.5 * f, min_v + 1) )
		return min_v / max_dis
	elif min_h < min_v:
		var max_dis : float = ceil( max(cols * 0.5 * f, min_h + 1) )
		return min_h / max_dis
	else:
#	var min_dis : float = min( min(rows - j, j), min(cols - i, i) )
		var max_dis : float = ceil(max( max(cols, rows) * f * 0.5, min_h + 1) )
		return min_h / max_dis

func getMidpoint(p1 : FieldPoint, p2 : FieldPoint, threshold : float, interpolate : bool = true) -> Vector2:
	var t : float = 0.5
	if interpolate:
		t = getT(p1.v, p2.v, threshold)
	
	return lerp(Vector2(p1.x,p1.y), Vector2(p2.x,p2.y), t)

func getT(f1, f2, threshold) -> float:
	var v2 : float = max(f2, f1);
	var v1 : float = min(f2, f1);
	return (threshold - v1) / (v2 - v1)

func getState(value, threshold) -> int:
	if value >= threshold:
		return 1
	else:
		return 0

func getCase(a : int, b : int, c : int, d : int) -> int:
	return a * 8 + b * 4 + c * 2 + d * 1

func getRows(size_y : float) -> int:
	return (floor(size_y / resolution) + 1) as int

func getCols(size_x : float) -> int:
	return (floor(size_x / resolution) + 1) as int




class FieldPoint:
	var x : float = 0.0
	var y : float = 0.0
	var v : float = 0.0
	var state : int = 0
	
	func _init(x : float, y : float, value : float, state : int) -> void:
		self.x = x
		self.y = y
		self.v = value
		self.state = state







#func generateTiled(x : int, y : int, zoff : float = 0.0, threshold : float = 0.5, interpolate : bool = true, type : int = GENERATION_TYPE.LINES) -> Dictionary:
#	var r : int = rows + 1
#	var c : int = cols + 1
#	var offset := Vector2(x * size.x, y * size.y)
#	var map : Dictionary = {"res" : resolution, "bounds" : Rect2(origin + offset, size), "rows" : r, "cols" : c, "x" : x, "y" : y, "offset" : offset}
#	map["field"] = generateFieldTiled(r, c, offset, zoff)
#
#	match type:
#		GENERATION_TYPE.CASES:
#			map["cases"] = march(map.field, r, c, MARCH_TYPE.CASES, threshold, interpolate)
#		GENERATION_TYPE.LINES:
#			map["lines"] = march(map.field, r, c, MARCH_TYPE.LINES, threshold, interpolate)
#		GENERATION_TYPE.FILLED:
#			map["polygons"] = march(map.field, r, c, MARCH_TYPE.POLYGONS, threshold, interpolate)
#		GENERATION_TYPE.OUTLINE_FILLED:
#			map["lines"] = march(map.field, r, c, MARCH_TYPE.LINES, threshold, interpolate)
#			map["polygons"] = march(map.field, r, c, MARCH_TYPE.POLYGONS, threshold, interpolate)
#
#	return map
#
#func generateFieldTiled(rows : int, cols : int, offset : Vector2, zoff : float = 0.0) -> Array:
#	var noise_offset : Vector3 = noise_origin + Vector3(offset.x * noise_offset_factor.x, offset.y * noise_offset_factor.y, zoff)
#	var field : Array = []
#	var start : Vector2 = origin + offset
#
#	for j in range(0, rows):
#		noise_offset.y += noise_increment.y
#
#		for i in range(0, cols):
#			var value : float = 0.0
#			value = noise.get_noise_3d(noise_offset.x, noise_offset.y, noise_offset.z)
#			value = (value + 1.0) * 0.5
#
#			field.append(Vector3(start.x, start.y, 0.0) + Vector3(i * resolution, j * resolution, value))
#
#			noise_offset.x += noise_increment.x
#
#	return field
