extends Control
class_name PauseMenu

@onready var animation_player: AnimationPlayer = $AnimationPlayer
signal state_changed
var paused = false
		
func _ready() -> void:
	hide()

func _input(event):
	if event.is_action_pressed("pause"):
		testESC()
	
func testESC():
	if Input.is_action_just_pressed("pause") and !paused:
		pause()
	elif Input.is_action_just_pressed("pause") and paused:
		resume()

func _on_resume_pressed() -> void:
	resume()

func _on_restart_pressed() -> void:
	restart()

func _on_options_pressed() -> void:
	pass # Replace with function body.

func _on_main_menu_pressed() -> void:
	resume()
	MultiplayerManager.disconnect_to_server()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func pause():
	paused = true
	state_changed.emit()
	animation_player.play("blur")
	#get_tree().paused = paused
	show()

func resume():
	paused = false
	animation_player.play_backwards("blur")
	#get_tree().paused = paused
	state_changed.emit()

func restart():
	resume()
	get_tree().reload_current_scene()
