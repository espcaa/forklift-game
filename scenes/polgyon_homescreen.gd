extends Polygon2D

func _ready():
	var screen_size = get_viewport_rect().size
	get_parent().get_node("SubViewport").size = screen_size

	polygon = [
		Vector2(0, 0),                          # top-left
		Vector2(screen_size.x*50/100, 0),              # top-right
		Vector2(screen_size.x*30/100, screen_size.y),
		Vector2(0, screen_size.y)               # bottom-left
	]

	texture = get_parent().get_node("SubViewport").get_texture()
