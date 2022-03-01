extends Line2D




func spawn(a : Vector2, b : Vector2, w : float = 1.0, color : Color = Color.white) -> void:
	width = max(w,2.0)
	default_color = color
	add_point(a)
	add_point(b)
