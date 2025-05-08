extends AnimatedSprite2D
class_name Weapon

@export var weapon_name: GlobalEnums.Guns
@export var weapon_type: GlobalEnums.WeaponType
@export var damage: int = 10
@export var on_player: bool = false

signal attacked
var default_y_scale

func _ready() -> void:
	default_y_scale = scale.y	

func attack():
	attacked.emit()
