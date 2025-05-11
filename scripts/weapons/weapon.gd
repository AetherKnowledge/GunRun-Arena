extends AnimatedSprite2D
class_name Weapon

@export var weapon_name: GlobalEnums.Guns
@export var weapon_type: GlobalEnums.WeaponType
@export var damage: int = 10
@export var PickupSFX: AudioStreamPlayer2D = AudioStreamPlayer2D.new()

var player: Player
var default_y_scale

func init(player: Player):
	self.player = player
	return self

func _ready() -> void:
	default_y_scale = scale.y	

func attack():
	pass
