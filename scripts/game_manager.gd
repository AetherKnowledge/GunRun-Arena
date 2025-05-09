extends Node
class_name GameManager
		
func pause():
	get_tree().paused = true

func resume():
	get_tree().paused = false

func restart():
	get_tree().reload_current_scene()

func remove_single_player():
	pass
