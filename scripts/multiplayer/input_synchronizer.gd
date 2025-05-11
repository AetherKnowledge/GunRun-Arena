extends MultiplayerSynchronizer
class_name InputSynchronizer

const ATTACK_THRESHOLD: float = 0.8
var input_attack: bool = false
var input_direction: int = 1
var input_jump: bool = false

@onready var player: MultiplayerPlayer = $".."
@onready var aim_stick: VirtualJoystick = %HUD.aim_stick
@onready var hud: HUD = %HUD
@onready var canvas_layer: CanvasLayer = %CanvasLayer

var looking_at: Vector2 = Vector2(0,0)

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
	
	input_direction = Input.get_axis("move_left", "move_right")
	looking_at = player.get_global_mouse_position()

func _input(event):
	if not player.alive:
		return
	
	_process_default_controls()
	
	if OS.get_name() != "Android" and not Settings.DEBUG_MODE:
		_process_pc_controls()
		return
	
	if event is InputEventScreenTouch:
		process_android_controls(event.pressed, event.position)
		if Input.is_action_pressed("move_left"):
			left_tap_count += 1
			print(left_tap_count)
			print(right_tap_count)
			if left_tap_count == 1:
				await get_tree().create_timer(double_tap_time).timeout
				left_tap_count = 0
			elif left_tap_count == 2:
				left_tap_count = 0
				dash.rpc()
				
		# Check for right input
		elif Input.is_action_just_pressed("move_right"):
			right_tap_count += 1
			print(left_tap_count)
			print(right_tap_count)
			
			if right_tap_count == 1:
				await get_tree().create_timer(double_tap_time).timeout
				right_tap_count = 0
			elif right_tap_count == 2:
				right_tap_count = 0
				dash.rpc()
				
	elif event is InputEventScreenDrag:
		process_android_controls(true, event.position)
	
		
func process_android_controls(is_pressed: bool, touch_pos: Vector2):
	if not hud or not hud.movement_controls or not canvas_layer:
		return
	
	var ignore_area_pos = hud.movement_controls.position  # Top-left corner
	var ignore_area_size = hud.movement_controls.size * get_viewport().get_stretch_transform().get_scale()
	
	var inside_ignore_area = (touch_pos.x >= ignore_area_pos.x and touch_pos.x <= ignore_area_pos.x + ignore_area_size.x
		and touch_pos.y >= ignore_area_pos.y and touch_pos.y <= ignore_area_pos.y + ignore_area_size.y)
	
	if not inside_ignore_area:
		var canvas_transform = get_viewport().get_canvas_transform()
		var canvas_layer_pos = canvas_transform.affine_inverse() * touch_pos
		
		looking_at = canvas_layer_pos
		input_attack = is_pressed
			
func _process_pc_controls():
	if Input.get_connected_joypads().size() < 1:
		looking_at = player.get_global_mouse_position()
	
	if Input.is_action_just_pressed("attack"):
		input_attack = true
	if Input.is_action_just_released("attack"):
		input_attack = false
		
func _process_stick_aim_controls():
	aim_stick = %HUD.aim_stick
	if not aim_stick:
		return
		
	if aim_stick.output != Vector2(0,0):
		looking_at = aim_stick.output * Vector2(200,200) + player.global_position
	
	if abs(aim_stick.output.x) > ATTACK_THRESHOLD or abs(aim_stick.output.y) > ATTACK_THRESHOLD:
		Input.action_press("attack")
	else:
		Input.action_release("attack")
		

func _process_default_controls():
	#input_direction = Input.get_axis("move_left", "move_right")
	if Input.get_connected_joypads().size() > 0:
		var device := 0  # Usually 0 for the first connected gamepad
		var right_stick_x := Input.get_joy_axis(device, JOY_AXIS_RIGHT_X)  # Right Stick X
		var right_stick_y := Input.get_joy_axis(device, JOY_AXIS_RIGHT_Y)  # Right Stick Y

		var aim_input := Vector2(right_stick_x, right_stick_y)

		# Deadzone check (avoid small drift)
		if aim_input.length() > 0.2:
			looking_at = aim_input * Vector2(200, 200) + player.global_position

	
	if Input.is_action_pressed("move_left") and not Input.is_action_pressed("move_right"):
		input_direction = -1
	elif Input.is_action_pressed("move_right") and not Input.is_action_pressed("move_left"):
		input_direction = 1
	else:
		input_direction = 0
	
	if Input.is_action_just_pressed("jump"):
		jump.rpc()
		input_jump = true
		if player.can_jump:
			player.jump_sfx.play()
	if Input.is_action_just_released("jump"):
		release_jump.rpc()
		input_jump = false 
			
	if Input.is_action_just_pressed("dash"):
		dash.rpc()

@rpc("call_local")
func jump():
	if multiplayer.is_server():
		player.do_jump = true
		
@rpc("call_local")
func release_jump():
	if multiplayer.is_server():
		player.release_jump = true
		
@rpc("call_local")
func dash():
	if multiplayer.is_server():
		player.do_dash = true
