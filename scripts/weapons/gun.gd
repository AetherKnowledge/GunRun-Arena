extends Weapon
class_name Gun

const bullet_scene = preload("res://scenes/weapons/bullet.tscn")
@export var ammo: int = 0
@export var cooldown: float = 0.5

@onready var shoot_sfx: AudioStreamPlayer2D = $ShootSFX
@onready var empty_sfx: AudioStreamPlayer2D = $EmptySFX
@onready var pickup_sfx: AudioStreamPlayer2D = $PickupSFX
@onready var shoot_pos: Marker2D = $ShootPos

var can_fire = true


func attack():
	if not can_fire:
		return
	
	super.attack()
	
	if ammo > 0:
		shoot()
	elif ammo < 1 and not animation == "empty":
		stop()
		play("empty")
		empty_sfx.play()

func start_cooldown() -> void:
	can_fire = false
	await get_tree().create_timer(cooldown).timeout
	can_fire = true
	
func shoot():
	var new_bullet: Bullet = bullet_scene.instantiate()
	new_bullet.global_position = shoot_pos.global_position
	new_bullet.global_rotation = shoot_pos.global_rotation
	
	get_tree().root.add_child(new_bullet)
	
	stop()
	play("shoot")
	shoot_sfx.play()
	ammo -= 1
	start_cooldown()
