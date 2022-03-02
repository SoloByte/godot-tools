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

enum RANDOM_TYPE {
	NOISE = 0,
	RNG = 1
}


var noise : OpenSimplexNoise
var rng : RandomNumberGenerator
var noise_start_offset := Vector2.ZERO
var noise_increment := Vector2(0.1,0.1)
var bounds : Rect2
var resolution : int = 0
var cols : int = 0
var rows : int = 0



func _init(pos : Vector2, size : Vector2, res : int, n_increment := Vector2(1, 1), n_seed : int = -1, n_octaves : float = 4.0, n_period : float = 20.0, n_persistence : float = 0.8) -> void:
	rng = RandomNumberGenerator.new()
	noise = OpenSimplexNoise.new()
	if n_seed > -1:
		noise.seed = n_seed
		rng.seed = n_seed
	else:
		noise.seed = randi()
		rng.randomize()
	noise.octaves = min(n_octaves, 9.0)
	noise.period = n_period
	noise.persistence = n_persistence
	noise_increment = n_increment
	bounds = Rect2(pos, size)
	resolution = res
	cols = size.x / res 
	rows = size.y / res
	cols += 1
	rows += 1



func generateStatic(zoff : float = 0.0, threshold : float = 0.5, interpolate : bool = true, use_noise : bool = true, edge := Vector2.ZERO, type : int = GENERATION_TYPE.LINES) -> Dictionary:
	var map : Dictionary = {"res" : resolution, "bounds" : bounds, "rows" : rows, "cols" : cols}
	
	if use_noise:
		map["field"] = generateFieldNoise(rows, cols, zoff, edge)
	else:
		map["field"] = generateFieldRNG(rows, cols, edge)
	
	match type:
		GENERATION_TYPE.CASES:
			map["cases"] = march(map.field, rows, cols, MARCH_TYPE.CASES, threshold, interpolate)
		GENERATION_TYPE.LINES:
			map["lines"] = march(map.field, rows, cols, MARCH_TYPE.LINES, threshold, interpolate)
		GENERATION_TYPE.FILLED:
			map["polygons"] = march(map.field, rows, cols, MARCH_TYPE.POLYGONS, threshold, interpolate)
		GENERATION_TYPE.OUTLINE_FILLED:
			map["lines"] = march(map.field, rows, cols, MARCH_TYPE.LINES, threshold, interpolate)
			map["polygons"] = march(map.field, rows, cols, MARCH_TYPE.POLYGONS, threshold, interpolate)
	
	return map



func generateFieldRNG(rows : int, cols : int, edge := Vector2.ZERO) -> Array:
	var field : Array = []
	var start : Vector2 = bounds.position
	
	for j in range(0, rows):
		for i in range(0, cols):
			var value : float = rng.randf() * getEdgeFactor(i, j, cols - 1, rows - 1, edge)
#			value *= getDistanceFactor(i, j, cols - 1, rows - 1, edge)
			
			field.append(Vector3(start.x, start.y, 0.0) + Vector3(i * resolution, j * resolution, value))
	return field

func generateFieldNoise(rows : int, cols : int, zoff : float = 0.0, edge := Vector2.ZERO) -> Array:
	var noise_offset : Vector2 = noise_start_offset
	var start : Vector2 = bounds.position
	var field : Array = []
	
	for j in range(0, rows):
		noise_offset.y += noise_increment.y
		for i in range(0, cols):
			var value : float = noise.get_noise_3d(noise_offset.x, noise_offset.y, zoff)
			value = (value + 1.0) * 0.5
			value *= getEdgeFactor(i, j, cols - 1, rows - 1, edge)
#			value *= getDistanceFactor(i, j, cols - 1, rows - 1, edge)
			
			field.append(Vector3(start.x, start.y, 0.0) + Vector3(i * resolution, j * resolution, value))
			noise_offset.x += noise_increment.x
	return field

func march(field : Array, rows : int, cols : int, march_type : int = MARCH_TYPE.LINES, threshold : float = 0.5, interpolate : bool = true) -> Array:
	var generated : Array = []
	for j in range(0, rows - 1):
		for i in range(0, cols - 1):
			var index : int = i + j * cols
			
			var top_left : Vector3 = field[index]
			var top_right : Vector3 = field[index + 1]
			var bottom_right : Vector3 = field[index + 1 + cols]
			var bottom_left : Vector3 = field[index + cols]
			
			var case : int = getCase(getState(top_left.z, threshold),getState(top_right.z, threshold),getState(bottom_right.z, threshold),getState(bottom_left.z, threshold))
			if MARCH_TYPE == MARCH_TYPE.CASES:
				generated.append(case)
			elif MARCH_TYPE == MARCH_TYPE.LINES:
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


#edge.x is considered the edge depth
#edge.y is considered the factor for multiplying
func getEdgeFactor(i, j, cols, rows, edge := Vector2.ZERO) -> float:
	if edge.x <= 0.0: return 1.0
	var depth : int = min( min(i, cols - i), min(j, rows - j))
	
	if depth <= 0:
		return 0.0
	elif rng.randf() > depth as float / edge.x as float:
		return edge.y
	
	return 1.0

func getDistanceFactor(i, j, cols, rows, f : float = 1.0) -> float:
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

func getMidpoint(p1 : Vector3, p2 : Vector3, threshold : float, interpolate : bool = true) -> Vector2:
	var t : float = 0.5
	if interpolate:
		t = getT(p1.z, p2.z, threshold)
	
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

