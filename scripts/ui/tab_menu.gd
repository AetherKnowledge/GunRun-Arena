@tool
extends BlurredPanel

const player_stats_scene = preload("res://scenes/ui/player_stats.tscn")

func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	
	if Input.is_action_just_pressed("tab"):
		play()
	if Input.is_action_just_released("tab"):
		play_backwards()
		
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	hide()
	MultiplayerManager.player_connected.connect(add_player_to_tab_menu)
	MultiplayerManager.player_disconnected.connect(remove_player_to_tab_menu)
	
func add_player_to_tab_menu(player: Player):
	if multiplayer.is_server() and not MultiplayerManager.host_mode:
		return
		
	var player_stats = player_stats_scene.instantiate().init(player)
	player_stats.name = player.name
	%PlayerStatsContainer.add_child(player_stats)

func remove_player_to_tab_menu(player: Player):
	if multiplayer.is_server() and not MultiplayerManager.host_mode:
		return
		
	if not %PlayerStatsContainer.get_node(str(player.name)):
		return
	
	%PlayerStatsContainer.get_node(str(player.name)).queue_free()


func _on_multiplayer_spawner_spawned(node: Node) -> void:
	if not node is Player:
		return
		
	add_player_to_tab_menu(node as Player)

func _on_multiplayer_spawner_despawned(node: Node) -> void:
	if not node is Player:
		return
		
	remove_player_to_tab_menu(node as Player)
