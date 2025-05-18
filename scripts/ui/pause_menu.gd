extends BlurredPanel
class_name PauseMenu

signal state_changed
var paused = false

func _ready() -> void:
	%GameCodeTxtBox.text = MultiplayerManager.server_oid

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
	MultiplayerManager.graceful_disconnect_to_server()

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


func _on_copy_btn_pressed() -> void:
	# Get the current contents of the clipboard
	var current_clipboard = DisplayServer.clipboard_get()
	# Set the contents of the clipboard
	DisplayServer.clipboard_set(%GameCodeTxtBox.text)
