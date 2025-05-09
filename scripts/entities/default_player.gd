extends Player
class_name DefaultPlayer

const default_weapon = preload("res://scenes/weapons/glock.tscn")
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurt: AudioStreamPlayer2D = $Hurt
@onready var jump_sfx: AudioStreamPlayer2D = $Jump
@onready var death_timer: Timer = $DeathTimer
@onready var jump_buffer_timer: Timer = $JumpBufferTimer
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var weapon: Weapon:
	set(value):
		if weapon != null:
			weapon.queue_free()
			
		weapon = value
		weapon.scale = WEAPON_SCALE
		weapon.position = WEAPON_POSITION
		add_child(weapon)
	

var hp := 100:
	set(value):
		hp = clamp(value, 0, 100)
		took_damage.emit()
		if hp == 0:
			died.emit()


func _ready() -> void:
	weapon = default_weapon.instantiate()
	weapon.player = self
	_on_weapon_changed()

func _physics_process(delta: float) -> void:
	
	# checks if alive
	if not alive:
		if not animated_sprite.animation == "death":
			animated_sprite.play("death")
		return
	
	do_movement(delta)
	do_animations(delta)
	
func do_animations(delta):
	# Flip the sprite
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true
		
	# Play animations
	if not is_on_floor():
		animated_sprite.play("jump")
	elif direction == 0:
		animated_sprite.play("idle")
	else:
		animated_sprite.play("run")
		
func do_movement(delta):
	looking_at = get_global_mouse_position()
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Handle jump.
	if not is_on_floor():
		coyote_timer.start()
	else:
		can_jump = true
		if jump_buffer:
			jump()
			jump_buffer = false
		
	if Input.is_action_just_pressed("jump") and alive:
		if can_jump:
			jump()
			
		else:
			jump_buffer = true
			jump_buffer_timer.start()
	
	if Input.is_action_just_pressed("attack"):
		holding_attack = true
	if Input.is_action_just_released("attack"):
		holding_attack = false
		
	if holding_attack:
		attack()

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	direction = Input.get_axis("move_left", "move_right")
			
	# Apply movement		
	if direction:
		var horizontal = clamp(direction * MAX_MOVEMENT_SPEED, velocity.x, direction * MAX_MOVEMENT_SPEED)
		velocity.x = move_toward(velocity.x, horizontal, MOVEMENT_SPEED * 10 * delta)
	else:
		var half_speed = abs(velocity.x/4)
		velocity.x = move_toward(velocity.x, 0, half_speed)

	move_and_slide()

func attack():
	if weapon:
		weapon.attack()

func jump():
	can_jump = false
	if velocity.y > JUMP_VELOCITY:
		velocity.y = 0
	velocity.y += JUMP_VELOCITY
	jump_sfx.stop()
	jump_sfx.play(0.0)
	
func take_damage(damage: int, knockback_force: Vector2 = Vector2.ZERO) -> void:
	hp -= damage
	# Apply knockback if force is provided
	if knockback_force != Vector2.ZERO:
		if velocity.y > knockback_force.y:
			velocity.y = 0
		knockback_force.x = knockback_force.x * 10
		knockback_force.y = knockback_force.y * 10
		velocity = knockback_force
	
func kill():
	hp = 0

func _on_took_damage() -> void:
	hurt.play()

func _on_death() -> void:
	alive = false
	if not hurt.playing and not alive:
		Engine.time_scale = 0.5
	death_timer.start()

func _on_death_timer_timeout() -> void:
	Engine.time_scale = 1
	alive = true
	get_tree().reload_current_scene()


func _on_jump_buffer_timer_timeout() -> void:
	jump_buffer = false

func _on_coyote_timer_timeout() -> void:
	can_jump = false


func _on_weapon_changed() -> void:
	weapon.scale = WEAPON_SCALE
	weapon.position = WEAPON_POSITION
	add_child(weapon)


func _on_weapon_changing() -> void:
	weapon.queue_free()
