extends Player
class_name MultiplayerPlayer

const default_weapon = preload("res://scenes/weapons/glock.tscn")
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurt: AudioStreamPlayer2D = $Hurt
@onready var jump_sfx: AudioStreamPlayer2D = $Jump
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

var do_jump = false
var do_attack = false
var _is_on_floor = true

@onready var input_synchronizer: InputSynchronizer = %InputSynchronizer

var player_id: int = 1:
	set(id):
		player_id = id
		%InputSynchronizer.set_multiplayer_authority(id)

@export var hp := 100:
	set(value):
		var old_hp = hp
		hp = clamp(value, 0, 100)
		$HPBar.value = hp
		
		if hp == 0:
			if not animated_sprite.animation == "death":
				animated_sprite.play("death")
		
		if hp < old_hp:
			took_damage.emit()
			
		if hp == 0:
			process_death()

func _ready() -> void:
	weapon = default_weapon.instantiate().init(self)
	
	if multiplayer.get_unique_id() == player_id:
		$Camera2D.make_current()
	else:
		$Camera2D.enabled = false
		$CanvasLayer.visible = false

func _physics_process(delta: float) -> void:
	# checks if alive
	if not alive:
		return
	if multiplayer.is_server():
		_is_on_floor = is_on_floor()
		process_movement(delta)
		
	if not multiplayer.is_server() || MultiplayerManager.host_mode:
		process_animations(delta)
		
	if do_attack:
		attack()
		
func process_animations(delta):
	if not alive:
		return  # Dead, no animations should override death

	# Death animation has priority
	if animated_sprite.animation == "death":
		return

	# Hurt animation priority
	if animated_sprite.animation == "hurt" and animated_sprite.is_playing():
		return

	# Flip the sprite based on direction
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true

	# Jumping and Falling logic
	if not _is_on_floor:
		if velocity.y < 0:
			if animated_sprite.animation != "jump":
				animated_sprite.play("jump")
		else:
			if animated_sprite.animation != "fall":
				animated_sprite.play("fall")
		return  # Jump/fall overrides run/idle
	
	# Running animation
	if abs(velocity.x) > 10:
		if animated_sprite.animation != "run":
			animated_sprite.play("run")
	else:
		# Idle when not moving
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")

		
		
func process_movement(delta):
	do_attack = input_synchronizer.attacking
	looking_at = input_synchronizer.looking_at
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
		
	if do_jump:
		if can_jump:
			jump()
			do_jump = false
		else:
			jump_buffer = true
			jump_buffer_timer.start()	
			do_jump = false

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	direction = input_synchronizer.input_direction
			
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
	animated_sprite.play("jump")
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
	animated_sprite.play("hurt")
	hurt.play()
	
func kill():
	if not multiplayer.is_server():
		return # Server authoritative
	hp = 0

func process_death() -> void:
	hurt.play()
	
	if not multiplayer.is_server():
		return # Only server should apply death
	
	alive = false
	
	# Start 3 second death timer
	await get_tree().create_timer(3.0).timeout
	animated_sprite.play("idle")
	# Respawn logic
	hp = 100
	alive = true
	weapon = default_weapon.instantiate().init(self)
	position = (get_tree().get_current_scene().get_node("SpawnPoint") as Marker2D).global_position


func _on_jump_buffer_timer_timeout() -> void:
	jump_buffer = false

func _on_coyote_timer_timeout() -> void:
	can_jump = false
