extends Node2D

func _process(delta: float) -> void:
	if get_viewport().get_visible_rect().size.x != Settings.DEFAULT_WIDTH:
		position.x = get_viewport().get_visible_rect().size.x/2
		
		
