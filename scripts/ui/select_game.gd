extends Control

@onready var local_multiplayer_panel: Panel = $VBoxContainer/LocalMultiplayer/LocalMultiplayerPanel
@onready var join_panel: Panel = $JoinPanel
@onready var address_txt_box: TextEdit = $JoinPanel/MarginContainer/VBoxContainer/AddressTxtBox

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	join_panel.visible = false
	local_multiplayer_panel.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		join_panel.visible = false


func local_multiplayer() -> void:
	pass # Replace with function body.


func local_multiplayer_mouse_entered() -> void:
	local_multiplayer_panel.visible = true


func local_multiplayer_mouse_exited() -> void:
	local_multiplayer_panel.visible = false


func on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func single_player_pressed() -> void:
	MultiplayerManager.is_multiplayer = false
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func host_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/multiplayer/multiplayer.tscn")
	MultiplayerManager.host()

func join_pressed() -> void:
	join_panel.visible = true

func start_singleplayer_game():
	if get_tree().root.get_node("Game"):
		get_tree().root.get_node("Game").queue_free()
	
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func start_multiplayer_game():
	if get_tree().root.get_node("Multiplayer"):
		get_tree().root.get_node("Multiplayer").queue_free()
	
	get_tree().change_scene_to_file("res://scenes/multiplayer/multiplayer.tscn")


func _on_connect_pressed() -> void:
	join_panel.visible = false
	start_multiplayer_game()
	parse_and_join(address_txt_box.text)
	
func parse_and_join(full_address: String):
	var parts = full_address.split(":")
	if parts.size() == 2 and parts[1].is_valid_int():
		var address = parts[0]
		var port = int(parts[1])
		MultiplayerManager.join(address, port)
	else:
		print("Invalid address format. Use address:port")



func _on_cancel_pressed() -> void:
	join_panel.visible = false
