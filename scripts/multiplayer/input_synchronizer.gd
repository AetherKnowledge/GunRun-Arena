extends MultiplayerSynchronizer
class_name InputSynchronizer

var input_direction: int = 1
@onready var player: MultiplayerPlayer = $".."
@export var attacking: bool = false

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
		jump.rpc()
			
	if Input.is_action_just_pressed("attack"):
		attacking = true
	if Input.is_action_just_released("attack"):
		attacking = false 

@rpc("call_local")
func jump():
	if multiplayer.is_server():
		player.do_jump = true
		
