extends AnimatedSprite2D
class_name Weapon

enum WeaponType {MELEE, RANGED}
@export var weapon_name: String = "None"
@export var weapon_type: WeaponType
@export var damage: int = 10
var attacking: bool = false
signal attacked

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("attack"):
		attacking = true
	if Input.is_action_just_released("attack"):
		attacking = false
		
	if attacking:
		attack()
	
	look_at(get_global_mouse_position())
	rotation_degrees = wrap(rotation_degrees, 0, 360)
	if rotation_degrees > 90 and rotation_degrees < 270:
		flip_v = true
	else:
		flip_v = false
	pass

func attack():
	attacked.emit()
