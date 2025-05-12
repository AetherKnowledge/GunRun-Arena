extends BlurredPanel
class_name PauseMenu

signal state_changed
var paused = false

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

func _on_options_pressed() -> void:
	$SettingsPanel.play()

func _on_main_menu_pressed() -> void:
	resume()
	MultiplayerManager.disconnect_to_server()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func pause():
	paused = true
	state_changed.emit()
	play()
	show()

func resume():
	paused = false
	play_backwards()
	state_changed.emit()
	
	await animation_finished
	if $SettingsPanel.visible:
		$SettingsPanel.play_backwards()

func restart():
	resume()
	get_tree().reload_current_scene()
