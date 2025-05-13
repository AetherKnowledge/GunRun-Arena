extends Control

const SETTINGS_PANEL = preload("res://scenes/ui/settings_panel.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Settings.DEBUG_GAME or Settings.DEBUG_UI:
		var second_monitor_x = 10  # Change if your setup is different
		
		if Settings.DEBUG_GAME:
			get_tree().change_scene_to_file("res://scenes/multiplayer/debug_world.tscn")
			
			if is_port_open(MultiplayerManager.SERVER_PORT):
				DisplayServer.window_set_position(Vector2i(second_monitor_x, 200))
				MultiplayerManager.host("Host")
			else:
				MultiplayerManager.join(MultiplayerManager.SERVER_IP, MultiplayerManager.SERVER_PORT, "Client")
				DisplayServer.window_set_position(Vector2i(second_monitor_x, 800))
				
				
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/select_game.tscn")


func _on_options_pressed() -> void:
	$SettingsPanel.play()


func _on_exit_pressed() -> void:
	get_tree().quit()


func is_port_open(port: int, max_clients: int = 32) -> bool:
	var peer = ENetMultiplayerPeer.new()
	var result = peer.create_server(port, max_clients)
	if result == OK:
		peer.close()
		return true
	else:
		return false
