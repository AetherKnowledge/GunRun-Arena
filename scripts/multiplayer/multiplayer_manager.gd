extends Node

const player_scene = preload("res://scenes/entities/player.tscn")
const SERVER_IP = "sia.buyitproperties.uk"
const SERVER_PORT = 8890
var SERVER_FULL_ADDRESS = SERVER_IP + ":" + str(SERVER_PORT)

var is_multiplayer = true
var host_mode = false
var players_node: Node2D
var player_count: int = 0
var username: String = "Player"
var server_oid: String = ""
var suddenly_disconnected: bool = false

signal player_connected(player: Player)
signal player_disconnected(player: Player)
signal ready_to_add_players

func _ready() -> void:
	if OS.has_feature("dedicated_server"):
		print("Starting Dedicated Server...")
		get_tree().change_scene_to_file("res://scenes/multiplayer/multiplayer.tscn")
		host()

func host(username: String = "Player") -> Error:
	print("Connecting to noray on Address: %s and Port %s " % [SERVER_IP, str(SERVER_PORT)])
	var err = await _connect_to_noray()
	if err != OK:
		print("Error Code: " + str(err))
		return err
	
	host_mode = true
	var server_peer = ENetMultiplayerPeer.new()
	err = server_peer.create_server(Noray.local_port)
	if err != OK:
		print("Error Code: " + str(err))
		return err
	
	server_oid = Noray.oid
	multiplayer.multiplayer_peer = server_peer
	Noray.on_connect_nat.connect(_noray_client_connected)
	Noray.on_connect_relay.connect(_noray_client_connected)
	Noray.on_disconnect_from_host.connect(sudden_disconnect_to_server)
	
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	if not OS.has_feature("dedicated_server"):
		self.username = username
		add_player(1)
		player_count += 1
	
	return OK
	
func join(oid: String, username: String) -> Error:
	print("Joining Game at OID: %s" % oid)
	self.username = username
	
	var err = await _connect_to_noray()
	if err != OK:
		print("Error Code: " + str(err))
		return err
	
	Noray.on_connect_nat.connect(_connect_via_nat)
	Noray.on_connect_relay.connect(_connect_via_relay)
	
	Noray.connect_nat(oid)
	server_oid = oid
	return OK

func _connect_to_noray() -> Error:
	# Connect to noray
	var err = await Noray.connect_to_host(SERVER_IP, SERVER_PORT)
	if err != OK:
		print("Error Code: " + str(err))
		return err
		
	print("Connected to Noray")
	
	# Register host
	Noray.register_host()
	await Noray.on_pid

	# Register remote address
	# This is where noray will direct traffic
	err = await Noray.register_remote()
	if err != OK:
		print(err)
		return err
		
	print("Registered to Noray")
	return OK
	
func _connect_via_nat(address: String, port: int) -> Error:
	print("Connecting via NAT")
	var err = await _connect_to_host(address, port)
	if err != OK:
		print("Error Code: %s NAT Connection Failed, Attempting Relay" + str(err))
		Noray.connect_relay(server_oid)
		return err
	
	print("Connected to host with NAT")
	return OK
	
func _connect_via_relay(address: String, port: int) -> Error:
	print("Attempting to Connect with Relay")
	return await _connect_to_host(address, port)

func _connect_to_host(address: String, port: int) -> Error:
	#Do a handshake
	var udp = PacketPeerUDP.new()
	udp.bind(Noray.local_port)
	udp.set_dest_address(address, port)
	
	var err = await PacketHandshake.over_packet_peer(udp)
	udp.close()
	
	if err != OK:
		print("Error Code: " + str(err))
		return err
	
	# Connect to host
	var client_peer = ENetMultiplayerPeer.new()
	err = client_peer.create_client(address, port, 0, 0, 0, Noray.local_port)
	if err != OK:
		print("Error Code: " + str(err))
		return err
		
	print("Connected Successfully")
	
	multiplayer.server_disconnected.connect(sudden_disconnect_to_server)
	multiplayer.multiplayer_peer = client_peer
	return OK

func _noray_client_connected(address: String, port: int) -> Error:
	print("Client connecting")
	var client_peer = multiplayer.multiplayer_peer as ENetMultiplayerPeer
	var err = await PacketHandshake.over_enet(client_peer.host, address, port)
	
	if err != OK:
		print("Noray packet handshake failed %s" % err)
		return err
		
	return OK
	
func add_player(id: int):
	print("Player %s has joined " % id)
	
	var player = player_scene.instantiate()
	player.player_id = id
	player.name = str(id)
	
	#have to wait for scene to load before adding node
	while not get_tree().get_current_scene() || not get_tree().get_current_scene().get_node("Players"):
		await ready_to_add_players
		
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
		
		if not multiplayer.is_server() and not host_mode:
			Noray.disconnect_from_host()
		
		multiplayer.multiplayer_peer = null 
		print("Disconnected from server.")
		await get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
		
func graceful_disconnect_to_server():
	suddenly_disconnected = false
	disconnect_to_server()
	
func sudden_disconnect_to_server():
	suddenly_disconnected = true
	disconnect_to_server()
	
