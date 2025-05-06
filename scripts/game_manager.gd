extends Node
class_name GameManager
@onready var pause_menu: PauseMenu = %PauseMenu

func pause():
	get_tree().paused = true

func resume():
	get_tree().paused = false

func restart():
	get_tree().reload_current_scene()

func _on_pause_menu_state_changed() -> void:
	get_tree().paused = pause_menu.paused
