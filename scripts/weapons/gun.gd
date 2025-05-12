extends Weapon
class_name Gun

const default_bullet_scene = preload("res://scenes/weapons/bullet.tscn")
const exploding_bullet_scene = preload("res://scenes/weapons/exploding_bullet.tscn")
@export var bullet_type: GlobalEnums.BulletTypes = GlobalEnums.BulletTypes.Default

@export var max_ammo: int = 100
@export_range(50, 1000, 1) var max_distance = 100

var ammo: int = max_ammo:
	set(value):
		ammo = max(0, value)
		
@export_range(0.05, 10.0, 0.05) var cooldown: float = 0.5:
	set(value):
		cooldown = max(0.05, value)
		cooldown = min(10, value)

@onready var shoot_sfx: AudioStreamPlayer2D = $ShootSFX
@onready var empty_sfx: AudioStreamPlayer2D = $EmptySFX
@onready var pickup_sfx: AudioStreamPlayer2D = $PickupSFX
@onready var shoot_pos: Marker2D = $ShootPos

var can_fire = true

func _ready() -> void:
	ammo = max_ammo

func _process(delta: float) -> void:
	if not player:
		return
	
	# Rotate towards mouse
	var target_pos = player.looking_at
	var dir = (target_pos - shoot_pos.global_position).normalized()
	rotation = dir.angle()

	# Smooth flip based on mouse position
	# flip v doesnt flip shoot pos
	if player.looking_at.x < global_position.x:
		scale.y = player.WEAPON_SCALE.y * -1
	else:
		scale.y = player.WEAPON_SCALE.y
		
		
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
	elif ammo < 1 and not empty_sfx.playing: 
		empty_sfx.play()

func start_cooldown() -> void:
	can_fire = false
	await get_tree().create_timer(cooldown).timeout
	can_fire = true
	
func shoot():
	# Calculate direction vector from shoot_pos to mouse position
	if multiplayer.is_server():
		var new_bullet: Bullet = make_bullet(player, bullet_type)
		get_tree().get_current_scene().get_node("Bullets").add_child(new_bullet, true)
	
	stop()
	play("shoot")
	shoot_sfx.play()
	ammo -= 1
	start_cooldown()
	
func make_bullet(player: Player, bullet_type: GlobalEnums.BulletTypes, dir_angle: float = (player.looking_at - shoot_pos.global_position).normalized().angle()) -> Bullet:
	return get_bullet(bullet_type).instantiate().init(player, shoot_pos, dir_angle, max_distance,damage, knockback_strength)
		

func get_bullet(bullet_type: GlobalEnums.BulletTypes) -> PackedScene:
	match bullet_type:
		GlobalEnums.BulletTypes.Explosive:
			return exploding_bullet_scene
		_:
			return default_bullet_scene
	
