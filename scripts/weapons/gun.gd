extends Weapon
class_name Gun

const bullet_scene = preload("res://scenes/weapons/bullet.tscn")
@export_range(1, 200, 1) var ammo: int = 0:
	set(value):
		ammo = max(0, value)
		ammo = min(200, value)
		
@export_range(0.05, 10.0, 0.05) var cooldown: float = 0.5:
	set(value):
		cooldown = max(0.05, value)
		cooldown = min(10, value)

@onready var shoot_sfx: AudioStreamPlayer2D = $ShootSFX
@onready var empty_sfx: AudioStreamPlayer2D = $EmptySFX
@onready var pickup_sfx: AudioStreamPlayer2D = $PickupSFX
@onready var shoot_pos: Marker2D = $ShootPos

var can_fire = true
var player: Player

func _process(delta: float) -> void:
	if not on_player:
		return
	
	super._process(delta)
	
	# Rotate towards mouse
	var target_pos = player.looking_at
	var dir = (target_pos - shoot_pos.global_position).normalized()
	rotation = dir.angle()

	# Smooth flip based on mouse position
	# flip v doesnt flip shoot pos
	if player.looking_at.x < global_position.x:
		scale.y = default_y_scale * -1
	else:
		scale.y = default_y_scale
		
		
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
	var new_bullet: Bullet = bullet_scene.instantiate()
	new_bullet.global_position = shoot_pos.global_position
	new_bullet.damage = damage
	# Calculate direction vector from shoot_pos to mouse position
	var dir = (player.looking_at - shoot_pos.global_position).normalized()
	# Set bullet rotation to face that direction
	new_bullet.global_rotation = dir.angle()
	
	get_tree().root.add_child(new_bullet)
	
	stop()
	play("shoot")
	shoot_sfx.play()
	ammo -= 1
	start_cooldown()
