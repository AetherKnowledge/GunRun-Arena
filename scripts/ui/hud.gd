extends Control
class_name HUD

@onready var hp_bar: TextureProgressBar = $HPBar
@onready var ammo_bar: TextureProgressBar = $AmmoBar

@onready var hp_label: Label = %HPLabel
@onready var x_vel_label: Label = %XVelLabel
@onready var y_vel_label: Label = %YVelLabel
@onready var ammo_label: Label = %AmmoLabel
@onready var ping_label: Label = %PingLabel
@onready var jumps_label: Label = %JumpsLabel
@onready var kill_label: Label = %KillLabel
@onready var death_label: Label = %DeathLabel

var last_ping_time: int = 0
var ping_ms: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

		
func _on_ping_timer_timeout() -> void:
	if not MultiplayerManager.is_multiplayer:
		return
	last_ping_time = Time.get_ticks_msec()
	if not multiplayer.is_server():
		rpc_id(1, "ping_request", last_ping_time)  # assuming server has peer ID 1
	ping_label.text = "Ping: %d ms" % ping_ms

@rpc("any_peer")
func ping_request(client_time: int):
	var sender_id = multiplayer.get_remote_sender_id()
	rpc_id(sender_id, "ping_response", client_time)

@rpc("authority")
func ping_response(client_time: int):
	var now = Time.get_ticks_msec()
	ping_ms = now - client_time
	$PingLabel.text = "Ping: %d ms" % ping_ms
