extends MultiplayerSynchronizer
class_name InputSynchronizer

const ATTACK_THRESHOLD: float = 0.8
var input_attack: bool = false
var input_direction: int = 1
var input_jump: bool = false
var input_dash: bool = false

@onready var player: Player = $".."
#@export var player: Player

var looking_at: Vector2 = Vector2(0,0)
var username: String = "Player"

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
		username = MultiplayerManager.username

func _physics_process(delta: float) -> void:
	_process_default_controls()

func _input(event):
	if event is InputEventScreenTouch:
		process_android_controls(event.pressed, event.position)
		if Input.is_action_pressed("move_left"):
			left_tap_count += 1
			if left_tap_count == 1:
				await get_tree().create_timer(double_tap_time).timeout
				left_tap_count = 0
			elif left_tap_count == 2:
				left_tap_count = 0
				input_dash = true
				await get_tree().create_timer(0.1).timeout
				input_dash = false
				
		# Check for right input
		elif Input.is_action_just_pressed("move_right"):
			right_tap_count += 1
			
			if right_tap_count == 1:
				await get_tree().create_timer(double_tap_time).timeout
				right_tap_count = 0
			elif right_tap_count == 2:
				right_tap_count = 0
				input_dash = true
				await get_tree().create_timer(0.1).timeout
				input_dash = false
				
	elif event is InputEventScreenDrag:
		process_android_controls(true, event.position)
	
		
func process_android_controls(is_pressed: bool, touch_pos: Vector2):
	var inside_movement_controls_area = false
	for node in get_tree().get_nodes_in_group("MouseIgnore"):
		if not node is Control or not (node as Control).visible:
			continue 
		
		var bruh = (node as Control).visible
		var global_rect = node.get_global_rect()
		inside_movement_controls_area = global_rect.has_point(touch_pos)
		
		if inside_movement_controls_area:
			break
	
	if not inside_movement_controls_area:
		var canvas_transform = get_viewport().get_canvas_transform()
		var canvas_layer_pos = canvas_transform.affine_inverse() * touch_pos
		
		looking_at = canvas_layer_pos
		input_attack = is_pressed
			
		
func _process_default_controls():
	if is_pause_menu_visible() and input_attack:
		input_attack = false
	
	if Input.get_connected_joypads().size() > 0:
		var device := 0
		var right_stick_x := Input.get_joy_axis(device, JOY_AXIS_RIGHT_X)  # Right Stick X
		var right_stick_y := Input.get_joy_axis(device, JOY_AXIS_RIGHT_Y)  # Right Stick Y

		var aim_input := Vector2(right_stick_x, right_stick_y)

		if aim_input.length() > 0.2:
			looking_at = aim_input * Vector2(200, 200) + player.global_position
		else:
			looking_at = player.get_global_mouse_position()	
			
		if Input.is_action_just_pressed("attack"):
			input_attack = true
		if Input.is_action_just_released("attack"):
			input_attack = false
	
	
	if not Settings.TouchControlsEnabled:
		looking_at = player.get_global_mouse_position()
	
	input_direction = Input.get_axis("move_left", "move_right")
	input_jump = Input.get_action_strength("jump")
	input_dash = Input.get_action_strength("dash")	

func is_pause_menu_visible() -> bool:
	var nodes = get_tree().get_nodes_in_group("PauseMenu")
	if nodes.size() != 1 or not nodes.get(0) is PauseMenu:
		return false
	var pause_menu = nodes.get(0) as PauseMenu 
	return pause_menu.visible
