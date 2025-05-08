extends MultiplayerSynchronizer
class_name InputSynchronizer

var input_direction: int = 1
@onready var player: MultiplayerPlayer = $".."

var looking_at: Vector2 = Vector2(0,0)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	if get_multiplayer_authority() != multiplayer.get_unique_id():
		set_process(false)
		set_physics_process(false)
		
	input_direction = Input.get_axis("move_left", "move_right")
	looking_at = player.get_global_mouse_position()
	
func _physics_process(delta: float) -> void:
	input_direction = Input.get_axis("move_left", "move_right")
	looking_at = player.get_global_mouse_position()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not player.alive:
		return
		
	if Input.is_action_just_pressed("jump"):
		if player.can_jump:
			jump.rpc()
			
	if Input.is_action_just_pressed("attack"):
		attack.rpc(true)
	if Input.is_action_just_released("attack"):
		attack.rpc(false)


@rpc("call_local")
func jump():
	if multiplayer.is_server():
		player.do_jump = true

@rpc("call_local")
func attack(attacking: bool):
	if multiplayer.is_server():
		player.do_attack = attacking

		
		
