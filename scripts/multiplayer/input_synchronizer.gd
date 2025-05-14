extends Node
class_name PlayerInput

const ATTACK_THRESHOLD: float = 0.8

## Input sent
var input_attack: bool = false
var input_direction: int = 0
var input_jump: bool = false
var input_dash: bool = false
var looking_at: Vector2 = Vector2(0,0)

# Input buffer
var buffer_input_attack: int = 0
var buffer_input_direction: int = 0
var buffer_input_jump: float = 0
var buffer_input_dash: bool = false
var buffer_looking_at: Vector2 = Vector2(0,0)
var movement_samples: int = 0

# Prediction
var confidence = 1

@onready var player: MultiplayerPlayer = $".."
@onready var rollback_synchronizer: RollbackSynchronizer = $"../RollbackSynchronizer"


var double_tap_time = 0.3
var left_tap_count = 0
var right_tap_count = 0
var last_valid_touch_pos: Vector2 = Vector2(0,0)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if get_multiplayer_authority() != multiplayer.get_unique_id():
		set_process(false)
		set_physics_process(false)
		set_process_input(false)
	else:
		_set_username(MultiplayerManager.username)
		
	NetworkTime.before_tick_loop.connect(_gather)
	NetworkTime.after_tick.connect(func(_dt, _t): _reset())
	
func _gather():
	# One off input
	input_dash = buffer_input_dash
	
	#Continious Inputs
	if movement_samples > 0:
		input_attack = buffer_input_attack/movement_samples
		input_direction = buffer_input_direction/movement_samples
		input_jump = buffer_input_jump/movement_samples
		looking_at = buffer_looking_at/movement_samples
	else:
		input_attack = false
		input_direction = 0
		input_jump = 0
		looking_at = Vector2.ZERO
	
	_reset_buffers()
		
func _reset_buffers():
	buffer_input_attack = 0
	buffer_input_direction = 0
	buffer_input_jump = 0
	buffer_input_dash = false
	buffer_looking_at = Vector2.ZERO
	movement_samples = 0

func _reset():
	input_dash = false
	
func _process(delta: float) -> void:
	_process_default_controls()
	movement_samples += 1
	
	
#func _input(event):
	#if not player.alive:
		#return
	#
	#if event is InputEventScreenTouch:
		#process_android_controls(event.pressed, event.position)
		#if Input.is_action_pressed("move_left"):
			#left_tap_count += 1
			#if left_tap_count == 1:
				#await get_tree().create_timer(double_tap_time).timeout
				#left_tap_count = 0
			#elif left_tap_count == 2:
				#left_tap_count = 0
				#input_dash = 1
				#await get_tree().create_timer(0.1).timeout
				#input_dash = 0
			#
		## Check for right input
		#elif Input.is_action_just_pressed("move_right"):
			#right_tap_count += 1
			#
			#if right_tap_count == 1:
				#await get_tree().create_timer(double_tap_time).timeout
				#right_tap_count = 0
			#elif right_tap_count == 2:
				#right_tap_count = 0
				#input_dash = 1
				#await get_tree().create_timer(0.1).timeout
				#input_dash = 0
		#
				#
	#elif event is InputEventScreenDrag:
		#process_android_controls(true, event.position)
	#
		#
#func process_android_controls(is_pressed: bool, touch_pos: Vector2):
	#var inside_movement_controls_area = false
	#for node in get_tree().get_nodes_in_group("MouseIgnore"):
		#if not node is Control or not (node as Control).visible:
			#continue 
		#
		#var global_rect = node.get_global_rect()
		#inside_movement_controls_area = global_rect.has_point(touch_pos)
		#
		#if inside_movement_controls_area:
			#break
	#
	#if not inside_movement_controls_area:
		#var canvas_transform = get_viewport().get_canvas_transform()
		#var canvas_layer_pos = canvas_transform.affine_inverse() * touch_pos
		#
		#looking_at = canvas_layer_pos
		#input_attack = is_pressed
			
		
func _process_default_controls():
	if Input.get_connected_joypads().size() > 0:
		var device := 0
		var right_stick_x := Input.get_joy_axis(device, JOY_AXIS_RIGHT_X)  # Right Stick X
		var right_stick_y := Input.get_joy_axis(device, JOY_AXIS_RIGHT_Y)  # Right Stick Y

		var aim_input := Vector2(right_stick_x, right_stick_y)

		if aim_input.length() > 0.2:
			buffer_looking_at += aim_input * Vector2(200, 200) + player.global_position
		else:
			buffer_looking_at += player.get_global_mouse_position()
	else:
		buffer_looking_at += player.get_global_mouse_position()
	
	if not is_pause_menu_visible():
		buffer_input_attack += Input.get_action_strength("attack")
	
	buffer_input_direction += Input.get_axis("move_left", "move_right")
	buffer_input_jump += Input.get_action_strength("jump")
	
	if Input.is_action_just_pressed("dash"):
		buffer_input_dash = true

func is_pause_menu_visible() -> bool:
	var nodes = get_tree().get_nodes_in_group("PauseMenu")
	if nodes.size() != 1 or not nodes.get(0) is PauseMenu:
		return false
	var pause_menu = nodes.get(0) as PauseMenu 
	return pause_menu.visible
		
@rpc("call_local")
func _set_username(username: String):
	if multiplayer.is_server():
		player.username = username
