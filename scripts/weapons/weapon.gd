extends AnimatedSprite2D
class_name Weapon

enum WeaponType {MELEE, RANGED}
@export var weapon_name: String = "None"
@export var weapon_type: WeaponType
@export var damage: int = 10
var attacking: bool = false
signal attacked
var default_y_scale

func _ready() -> void:
	default_y_scale = scale.y

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("attack"):
		attacking = true
	if Input.is_action_just_released("attack"):
		attacking = false
		
	if attacking:
		attack()
	
	# Rotate towards mouse
	look_at(get_global_mouse_position())

	# Smooth flip based on mouse position
	# flip v doesnt flip shoot pos
	if get_global_mouse_position().x < global_position.x:
		scale.y = default_y_scale * -1
	else:
		scale.y = default_y_scale

func attack():
	attacked.emit()
