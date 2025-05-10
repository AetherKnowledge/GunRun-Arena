extends MultiplayerSynchronizer
class_name InputSynchronizer

var input_attack: bool = false
var input_direction: int = 1
var input_jump: bool = false
@onready var player: MultiplayerPlayer = $".."
@onready var movement_stick: VirtualJoystick = %MovementStick

var looking_at: Vector2 = Vector2(0,0)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	if get_multiplayer_authority() != multiplayer.get_unique_id():
		set_process(false)
		set_physics_process(false)
	
	input_direction = Input.get_axis("move_left", "move_right")
	looking_at = player.get_global_mouse_position()
	
func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("move_left") and not Input.is_action_pressed("move_right"):
		input_direction = -1
	elif Input.is_action_pressed("move_right") and not Input.is_action_pressed("move_left"):
		input_direction = 1
	else:
		input_direction = 0
	
	#input_direction = Input.get_axis("move_left", "move_right")
	
	looking_at = player.get_global_mouse_position()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not player.alive:
		return
		
	if Input.is_action_just_pressed("jump"):
		jump.rpc()
		input_jump = true
		if player.can_jump:
			player.jump_sfx.play()
	if Input.is_action_just_released("jump"):
		input_jump = false 
	
	if Input.is_action_just_pressed("dash"):
		dash.rpc()
			
	if Input.is_action_just_pressed("attack"):
		input_attack = true
	if Input.is_action_just_released("attack"):
		input_attack = false 

@rpc("call_local")
func jump():
	if multiplayer.is_server():
		player.do_jump = true
		
@rpc("call_local")
func dash():
	if multiplayer.is_server():
		player.do_dash = true
