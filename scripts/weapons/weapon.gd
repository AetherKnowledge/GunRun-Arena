extends AnimatedSprite2D
class_name Weapon

@export var weapon_name: GlobalEnums.Guns
@export var weapon_type: GlobalEnums.WeaponType
@export var damage: int = 10
@export var on_player: bool = false

signal attacked
var attacking: bool = false
var default_y_scale


func _ready() -> void:
	default_y_scale = scale.y

func _process(delta: float) -> void:
	if not on_player:
		return
	
	if Input.is_action_just_pressed("attack"):
		attacking = true
	if Input.is_action_just_released("attack"):
		attacking = false
		
	if attacking:
		attack()

func attack():
	attacked.emit()
