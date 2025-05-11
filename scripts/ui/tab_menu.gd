extends Control

@onready var color_rect: ColorRect = $ColorRect
const player_stats_scene = preload("res://scenes/ui/player_stats.tscn")

func _input(event: InputEvent) -> void:
	if not color_rect:
		return
		
	if Input.is_action_just_pressed("tab"):
		show()
	if Input.is_action_just_released("tab"):
		hide()
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()
	MultiplayerManager.player_connected.connect(add_player_to_tab_menu)
	MultiplayerManager.player_disconnected.connect(remove_player_to_tab_menu)
	
func add_player_to_tab_menu(player: MultiplayerPlayer):
	if multiplayer.is_server() and not MultiplayerManager.host_mode:
		return
		
	var player_stats = player_stats_scene.instantiate().init(player)
	player_stats.name = player.name
	%PlayerStatsContainer.add_child(player_stats)

func remove_player_to_tab_menu(player: MultiplayerPlayer):
	if multiplayer.is_server() and not MultiplayerManager.host_mode:
		return
		
	if not %PlayerStatsContainer.get_node(str(player.name)):
		return
	
	%PlayerStatsContainer.get_node(str(player.name)).queue_free()


func _on_multiplayer_spawner_spawned(node: Node) -> void:
	if not node is MultiplayerPlayer:
		return
		
	add_player_to_tab_menu(node as MultiplayerPlayer)

func _on_multiplayer_spawner_despawned(node: Node) -> void:
	if not node is MultiplayerPlayer:
		return
		
	remove_player_to_tab_menu(node as MultiplayerPlayer)
