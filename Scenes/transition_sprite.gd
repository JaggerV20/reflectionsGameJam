extends Sprite2D


func _ready():
	var viewport_size = get_viewport().size
	position = Vector2(viewport_size.x / 2, viewport_size.y / 2) 
