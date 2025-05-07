extends Control

@onready var local_multiplayer_panel: Panel = $VBoxContainer/LocalMultiplayer/LocalMultiplayerPanel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	local_multiplayer_panel.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


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
	await get_tree().change_scene_to_file("res://scenes/multiplayer/multiplayer.tscn")
	MultiplayerManager.host()


func join_pressed() -> void:
	await get_tree().change_scene_to_file("res://scenes/multiplayer/multiplayer.tscn")
	MultiplayerManager.join()
