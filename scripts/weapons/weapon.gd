extends AnimatedSprite2D
class_name Weapon

@export var weapon_name: GlobalEnums.Items
@export var weapon_type: GlobalEnums.WeaponType
@export_range(1, 100, 1) var damage: int = 10
@export var PickupSFX: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
@export_range(1,200, 1) var knockback_strength = 10

var player: Player
var default_y_scale

func init(player: Player):
	self.player = player
	return self

func _ready() -> void:
	default_y_scale = scale.y	

func attack():
	pass
