class_name MarchingSquaresGenerator


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


#func generateTiled(i : int = 0, j : int = 0, fluid : bool = false, zoff : float = 0.0) -> Dictionary:
#	var points : PoolVector3Array = []
#	var lines : Array = []
#	var states : Array = []
#	var noise_offset : Vector2 = noise_start_offset + Vector2(bounds.size.x * i, bounds.size.y * j)
#	var start := Vector2(bounds.position.x + bounds.size.x * i, bounds.position.y + bounds.size.y * j)
#
#	for j in range(0, rows):
#		noise_offset.y += noise_increment.y
#		for i in range(0, cols):
#			var value : float = noise.get_noise_3d(noise_offset.x, noise_offset.y, zoff)
#			if j == 0 or i == 0 or j >= rows - 1 or i >= cols - 1:
#				value = 0
#			points.append(Vector3(start.x, start.y, 0.0) + Vector3(i * resolution, j * resolution, value))
#			states.append(-1)
#			noise_offset.x += noise_increment.x
#
#
#	for j in range(0, rows - 1):
#		for i in range(0, cols - 1):
#			var index : int = i + j * cols
#
#			var values : Array = [
#				points[index],
#				points[index+1],
#				points[index+1+cols],
#				points[index+cols]
#			]
#
#			var state : int = getState(
#			ceil(values[0].z),
#			ceil(values[1].z),
#			ceil(values[2].z),
#			ceil(values[3].z)
#			)
#
#			states[index] = state
#
#			var a := Vector2(values[0].x + resolution * 0.5, values[0].y)
#			var b := Vector2(values[1].x, values[1].y + resolution * 0.5)
#			var c := Vector2(values[3].x + resolution * 0.5, values[2].y)
#			var d := Vector2(values[3].x, values[0].y + resolution * 0.5)
#
#			if fluid:
#				var a_val : float = (values[0].z + 1) * 0.5
#				var b_val : float = (values[1].z + 1) * 0.5
#				var c_val : float = (values[2].z + 1) * 0.5
#				var d_val : float = (values[3].z + 1) * 0.5
#
##				var a_amt : float = (1.0 - a_val) / (b_val - a_val)
#				a.x = lerp(values[1].x, values[0].x, (a_val + b_val) * 0.5);
#				a.y = values[0].y;
#
##				var b_amt : float = (1.0 - b_val) / (c_val - b_val)
#				b.x = values[1].x
#				b.y = lerp(values[2].y, values[1].y, (b_val + c_val) * 0.5);
#
##				var c_amt = (1.0 - d_val) / (c_val - d_val)
#				c.x = lerp(values[2].x, values[3].x, (c_val + d_val) * 0.5);
#				c.y = values[2].y;
#
##				var d_amt = (1.0 - a_val) / (d_val - a_val)
#				d.x = values[3].x;
#				d.y = lerp(values[3].y, values[0].y, (d_val + a_val) * 0.5);
#
#			match state:
#				1: lines.append([c, d])
#				2: lines.append([b, c])
#				3: lines.append([b, d])
#				4: lines.append([a, b])
#				5: 
#					lines.append([a, d])
#					lines.append([b, c])
#				6: lines.append([a, c])
#				7: lines.append([a, d])
#				8: lines.append([a, d])
#				9: lines.append([a, c])
#				10: 
#					lines.append([a, b])
#					lines.append([c, d])
#				11: lines.append([a, b])
#				12: lines.append([b, d])
#				13: lines.append([b, c])
#				14: lines.append([c, d])
#
#	return constructDictionary(points, lines, states)
#
#func generateEndless() -> Dictionary:
#	return {}

#figure out a better way to generate the cases

func generateStaticCases(zoff : float = 0.0, threshold : float = 0.5, interpolate : bool = true, use_noise : bool = true, edge := Vector2.ZERO) -> Dictionary:
	var field : Array = []
	var cases : Array = []
	
	if use_noise:
		generateFieldNoise(field, rows, cols, zoff, edge)
	else:
		generateFieldRNG(field, rows, cols, edge)
	generateCases(cases, field, rows, cols, threshold, interpolate)
	
	return {
		"field" : field,
		"cases" : cases,
		"res" : resolution,
		"bounds" : bounds
	}

func generateStaticLines(zoff : float = 0.0, threshold : float = 0.5, interpolate : bool = true, use_noise : bool = true, edge := Vector2.ZERO) -> Dictionary:
	var field : Array = []
	var lines : Array = []
	if use_noise:
		generateFieldNoise(field, rows, cols, zoff, edge)
	else:
		generateFieldRNG(field, rows, cols, edge)
	generateLines(lines, field, rows, cols, threshold, interpolate)
	
	return {
		"field" : field,
		"lines" : lines,
		"res" : resolution,
		"bounds" : bounds
	}

func generateStaticPolygons(zoff : float = 0.0, threshold : float = 0.5, interpolate : bool = true, use_noise : bool = true, edge := Vector2.ZERO) -> Dictionary:
	var field : Array = []
	var polygons : Array = []
	if use_noise:
		generateFieldNoise(field, rows, cols, zoff, edge)
	else:
		generateFieldRNG(field, rows, cols, edge)
	generatePolygons(polygons, field, rows, cols, threshold, interpolate)
	
	return {
		"field" : field,
		"polygons" : polygons,
		"res" : resolution,
		"bounds" : bounds
	}

func generateStatic(zoff : float = 0.0, threshold : float = 0.5, interpolate : bool = true, use_noise : bool = true, edge := Vector2.ZERO) -> Dictionary:
	var field : Array = []
	var polygons : Array = []
	var lines : Array = []
	if use_noise:
		generateFieldNoise(field, rows, cols, zoff, edge)
	else:
		generateFieldRNG(field, rows, cols, edge)
	generatePolygons(polygons, field, rows, cols, threshold, interpolate)
	generateLines(lines, field, rows, cols, threshold, interpolate)
	
	return {
		"field" : field,
		"polygons" : polygons,
		"lines" : lines,
		"res" : resolution,
		"bounds" : bounds
	}



func generateFieldRNG(field : Array, rows : int, cols : int, edge := Vector2.ZERO) -> void:
	var start : Vector2 = bounds.position
	
	for j in range(0, rows):
		for i in range(0, cols):
			var value : float = rng.randf() * getEdgeFactor(i, j, cols - 1, rows - 1, edge)
#			value *= getDistanceFactor(i, j, cols - 1, rows - 1, edge)
			
			field.append(Vector3(start.x, start.y, 0.0) + Vector3(i * resolution, j * resolution, value))

func generateFieldNoise(field : Array, rows : int, cols : int, zoff : float = 0.0, edge := Vector2.ZERO) -> void:
	var noise_offset : Vector2 = noise_start_offset
	var start : Vector2 = bounds.position
	
	for j in range(0, rows):
		noise_offset.y += noise_increment.y
		for i in range(0, cols):
			var value : float = noise.get_noise_3d(noise_offset.x, noise_offset.y, zoff)
			value = (value + 1.0) * 0.5
			value *= getEdgeFactor(i, j, cols - 1, rows - 1, edge)
#			value *= getDistanceFactor(i, j, cols - 1, rows - 1, edge)
			
			field.append(Vector3(start.x, start.y, 0.0) + Vector3(i * resolution, j * resolution, value))
			noise_offset.x += noise_increment.x

func generateLines(lines : Array, field : Array, rows : int, cols : int, threshold : float = 0.5, interpolate : bool = true) -> void:
	for j in range(0, rows - 1):
		for i in range(0, cols - 1):
			var index : int = i + j * cols
			
			var top_left : Vector3 = field[index]
			var top_right : Vector3 = field[index + 1]
			var bottom_right : Vector3 = field[index + 1 + cols]
			var bottom_left : Vector3 = field[index + cols]
			
			var case : int = getCase(getState(top_left.z, threshold),getState(top_right.z, threshold),getState(bottom_right.z, threshold),getState(bottom_left.z, threshold))
			match case:
				1:
					lines.append(getMidpoint(top_left, bottom_left, threshold, interpolate))
					lines.append(getMidpoint(bottom_left, bottom_right, threshold, interpolate))
				14:
					lines.append(getMidpoint(top_left, bottom_left, threshold, interpolate))
					lines.append(getMidpoint(bottom_left, bottom_right, threshold, interpolate))
				
				2:
					lines.append(getMidpoint(top_right, bottom_right, threshold, interpolate))
					lines.append(getMidpoint(bottom_left, bottom_right, threshold, interpolate))
				13:
					lines.append(getMidpoint(top_right, bottom_right, threshold, interpolate))
					lines.append(getMidpoint(bottom_left, bottom_right, threshold, interpolate))
				
				3:
					lines.append(getMidpoint(top_left, bottom_left, threshold, interpolate))
					lines.append(getMidpoint(top_right, bottom_right, threshold, interpolate))
				12:
					lines.append(getMidpoint(top_left, bottom_left, threshold, interpolate))
					lines.append(getMidpoint(top_right, bottom_right, threshold, interpolate))
				
				4:
					lines.append(getMidpoint(top_left, top_right, threshold, interpolate))
					lines.append(getMidpoint(top_right, bottom_right, threshold, interpolate))
				11:
					lines.append(getMidpoint(top_left, top_right, threshold, interpolate))
					lines.append(getMidpoint(top_right, bottom_right, threshold, interpolate))
				
				5:
					lines.append(getMidpoint(top_left, top_right, threshold, interpolate))
					lines.append(getMidpoint(top_right, bottom_right, threshold, interpolate))
					lines.append(getMidpoint(top_left, bottom_left, threshold, interpolate))
					lines.append(getMidpoint(bottom_left, bottom_right, threshold, interpolate))
				10:
					lines.append(getMidpoint(top_left, top_right, threshold, interpolate))
					lines.append(getMidpoint(top_left, bottom_left, threshold, interpolate))
					lines.append(getMidpoint(bottom_left, bottom_right, threshold, interpolate))
					lines.append(getMidpoint(top_right, bottom_right, threshold, interpolate))
				
				6:
					lines.append(getMidpoint(top_left, top_right, threshold, interpolate))
					lines.append(getMidpoint(bottom_left, bottom_right, threshold, interpolate))
				9:
					lines.append(getMidpoint(top_left, top_right, threshold, interpolate))
					lines.append(getMidpoint(bottom_left, bottom_right, threshold, interpolate))
				
				7:
					lines.append(getMidpoint(top_left, top_right, threshold, interpolate))
					lines.append(getMidpoint(top_left, bottom_left, threshold, interpolate))
				8:
					lines.append(getMidpoint(top_left, top_right, threshold, interpolate))
					lines.append(getMidpoint(top_left, bottom_left, threshold, interpolate))

func generatePolygons(polygons : Array, field : Array, rows : int, cols : int, threshold : float = 0.5, interpolate : bool = true) -> void:
	for j in range(0, rows - 1):
		for i in range(0, cols - 1):
			var index : int = i + j * cols
			
			var top_left : Vector3 = field[index]
			var top_right : Vector3 = field[index + 1]
			var bottom_right : Vector3 = field[index + 1 + cols]
			var bottom_left : Vector3 = field[index + cols]
			
			var case : int = getCase(getState(top_left.z, threshold),getState(top_right.z, threshold),getState(bottom_right.z, threshold),getState(bottom_left.z, threshold))
			match case:
				15:
					var polygon : PoolVector2Array = [
						top_left,
						top_right,
						bottom_right,
						bottom_left
					]
					polygons.append(polygon)
				1:
					var polygon : PoolVector2Array = [
						getMidpoint(top_left, bottom_left, threshold, interpolate),
						getMidpoint(bottom_left, bottom_right, threshold, interpolate),
						bottom_left
					]
					polygons.append(polygon)
				14:
					var polygon : PoolVector2Array = [
						top_left, top_right, bottom_right,
						getMidpoint(bottom_left, bottom_right, threshold, interpolate),
						getMidpoint(top_left, bottom_left, threshold, interpolate)]
					polygons.append(polygon)
				2:
					var polygon : PoolVector2Array = [
						getMidpoint(top_right, bottom_right, threshold, interpolate),
						bottom_right,
						getMidpoint(bottom_left, bottom_right, threshold, interpolate)
					]
					polygons.append(polygon)
				13:
					var polygon : PoolVector2Array = [
						top_left,
						top_right,
						getMidpoint(top_right, bottom_right, threshold, interpolate),
						getMidpoint(bottom_left, bottom_right, threshold, interpolate),
						bottom_left
					]
					polygons.append(polygon)
				
				3:
					var polygon : PoolVector2Array = [
						getMidpoint(top_left, bottom_left, threshold, interpolate),
						getMidpoint(top_right, bottom_right, threshold, interpolate),
						bottom_right,
						bottom_left
					]
					polygons.append(polygon)
				12:
					var polygon : PoolVector2Array = [
						top_left,
						top_right,
						getMidpoint(top_right, bottom_right, threshold, interpolate),
						getMidpoint(top_left, bottom_left, threshold, interpolate)
					]
					polygons.append(polygon)
				
				4:
					var polygon : PoolVector2Array = [
						getMidpoint(top_left, top_right, threshold, interpolate),
						top_right,
						getMidpoint(top_right, bottom_right, threshold, interpolate)
					]
					polygons.append(polygon)
				11:
					var polygon : PoolVector2Array = [
						top_left,
						getMidpoint(top_left, top_right, threshold, interpolate),
						getMidpoint(top_right, bottom_right, threshold, interpolate),
						bottom_right,
						bottom_left
					]
					polygons.append(polygon)
				
				5:
					var polygon : PoolVector2Array = [
						getMidpoint(top_left, top_right, threshold, interpolate),
						top_right,
						getMidpoint(top_right, bottom_right, threshold, interpolate),
						getMidpoint(bottom_left, bottom_right, threshold, interpolate),
						bottom_left,
						getMidpoint(top_left, bottom_left, threshold, interpolate)
					]
					polygons.append(polygon)
				10:
					var polygon : PoolVector2Array = [
						top_left,
						getMidpoint(top_left, top_right, threshold, interpolate),
						getMidpoint(top_right, bottom_right, threshold, interpolate),
						bottom_right,
						getMidpoint(bottom_left, bottom_right, threshold, interpolate),
						getMidpoint(top_left, bottom_left, threshold, interpolate)
					]
					polygons.append(polygon)
				
				6:
					var polygon : PoolVector2Array = [
						getMidpoint(top_left, top_right, threshold, interpolate),
						top_right,
						bottom_right,
						getMidpoint(bottom_left, bottom_right, threshold, interpolate)
					]
					polygons.append(polygon)
				9:
					var polygon : PoolVector2Array = [
						top_left,
						getMidpoint(top_left, top_right, threshold, interpolate),
						getMidpoint(bottom_left, bottom_right, threshold, interpolate),
						bottom_left
					]
					polygons.append(polygon)
				
				7:
					var polygon : PoolVector2Array = [
						getMidpoint(top_left, top_right, threshold, interpolate),
						top_right,
						bottom_right,
						bottom_left,
						getMidpoint(top_left, bottom_left, threshold, interpolate)
					]
					polygons.append(polygon)
				8:
					var polygon : PoolVector2Array = [
						top_left,
						getMidpoint(top_left, top_right, threshold, interpolate),
						getMidpoint(top_left, bottom_left, threshold, interpolate)
					]
					polygons.append(polygon)

func generateCases(cases : Array, field : Array, rows : int, cols : int, threshold : float = 0.5, interpolate : bool = true) -> void:
	for j in range(0, rows - 1):
		for i in range(0, cols - 1):
			var index : int = i + j * cols
			
			var top_left : Vector3 = field[index]
			var top_right : Vector3 = field[index + 1]
			var bottom_right : Vector3 = field[index + 1 + cols]
			var bottom_left : Vector3 = field[index + cols]
			
			var case : int = getCase(getState(top_left.z, threshold),getState(top_right.z, threshold),getState(bottom_right.z, threshold),getState(bottom_left.z, threshold))
			cases.append(case)


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

