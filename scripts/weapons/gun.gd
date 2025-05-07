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

func _process(delta: float) -> void:
	super._process(delta)
	
	# Rotate towards mouse
	var target_pos = get_global_mouse_position()
	var dir = (target_pos - shoot_pos.global_position).normalized()
	rotation = dir.angle()

	# Smooth flip based on mouse position
	# flip v doesnt flip shoot pos
	if get_global_mouse_position().x < global_position.x:
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

func start_cooldown() -> void:
	can_fire = false
	await get_tree().create_timer(cooldown).timeout
	can_fire = true
	
func shoot():
	var new_bullet: Bullet = bullet_scene.instantiate()
	new_bullet.global_position = shoot_pos.global_position
	# Calculate direction vector from shoot_pos to mouse position
	var dir = (get_global_mouse_position() - shoot_pos.global_position).normalized()
	# Set bullet rotation to face that direction
	new_bullet.global_rotation = dir.angle()
	
	get_tree().root.add_child(new_bullet)
	
	stop()
	play("shoot")
	shoot_sfx.play()
	ammo -= 1
	start_cooldown()
