extends Node

const player_scene = preload("res://scenes/entities/multiplayer_player.tscn")
const SERVER_IP = "127.0.0.1"
const SERVER_PORT = 8080

var is_multiplayer = true
var host_mode = false
var players_node: Node2D
var player_count: int = 0

signal player_connected(player: MultiplayerPlayer)
signal player_disconnected(player: MultiplayerPlayer)

func _ready() -> void:
	if OS.has_feature("dedicated_server"):
		print("Starting Dedicated Server...")
		get_tree().change_scene_to_file("res://scenes/multiplayer/multiplayer.tscn")
		host()
		

func host():
	print("Starting game on Address: %s and Port %s " % [SERVER_IP, str(SERVER_PORT)])
	
	host_mode = true
	var server_peer = ENetMultiplayerPeer.new()
	server_peer.create_server(SERVER_PORT)
	
	multiplayer.multiplayer_peer = server_peer
	
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	if not OS.has_feature("dedicated_server"):
		add_player(1)
		player_count += 1
	
func join(address: String, port: int):
	print("Joining Game at Address: %s and Port %s " % [address, str(port)])
	
	var client_peer = ENetMultiplayerPeer.new()
	client_peer.create_client(address,port)
	
	multiplayer.multiplayer_peer = client_peer
	
func add_player(id: int):
	print("Player %s has joined " % id)
	
	var player = player_scene.instantiate()
	player.player_id = id
	player.name = str(id)
	
	#have to wait for scene to load before adding node
	while get_tree().get_current_scene() == null:
		await get_tree().process_frame
		
	players_node = get_tree().get_current_scene().get_node("Players")
	players_node.add_child(player)
	player_count += 1
	
	if host_mode:
		player_connected.emit(player)

func remove_player(id: int):
	print("Player %s has left " % id)
	if not players_node.get_node(str(id)):
		return
	players_node.get_node(str(id)).queue_free()
	player_count -= 1
	
	if host_mode:
		player_disconnected.emit()

func disconnect_to_server():
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null 
		print("Disconnected from server.")
