extends Player
class_name MultiplayerPlayer

const DEFAULT_WEAPON_SCENE = preload("res://scenes/weapons/glock.tscn")

# Node references
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurt_sfx: AudioStreamPlayer2D = $Hurt
@onready var jump_sfx: AudioStreamPlayer2D = $Jump
@onready var jump_buffer_timer: Timer = $JumpBufferTimer
@onready var dash_cooldown: Timer = $DashCooldown
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var hud: HUD = %HUD
@onready var input_synchronizer: InputSynchronizer = %InputSynchronizer
@onready var camera: Camera2D = $Camera2D
@onready var hp_bar: ProgressBar = $HPBar
@onready var collision: CollisionShape2D = $CollisionShape2D

# Player states
var do_dash: bool = false
var do_jump: bool = false
var do_attack: bool = false
var _is_on_floor: bool = true
var can_coyote_jump: bool = true
var holding_jump: bool = false
var kill_count: int = 0
var death_count: int = 0

# Jumping vars
@export var max_jumps: int = 2
var air_jumps_remaining: int = 1
var jumps_remaining: int = 1
var jumps_count: int = 0
var ended_jump_early = false

# Dashing vars
@export var max_dash: int = 1
var can_dash: bool = true
var dash_remaining: int = 1

# Multiplayer
var player_id: int = 1:
	set(id):
		player_id = id
		%InputSynchronizer.set_multiplayer_authority(id)

# Weapon logic
var weapon: Weapon:
	set(value):
		if weapon:
			weapon.queue_free()
		weapon = value
		weapon.scale = WEAPON_SCALE
		weapon.position = WEAPON_POSITION
		add_child(weapon)

# Health
@export var hp: int = 100:
	set(value):
		if hp == value:
			return
		hp = clamp(value, 0, 100)
		update_hud()
		if hp == 0:
			_process_death()
			update_hud()

func _ready() -> void:
	if player_id == multiplayer.get_unique_id():
		hp_bar.visible = false
	else:
		%HUD.visible = false
		
	weapon = DEFAULT_WEAPON_SCENE.instantiate().init(self)
	_respawn()
	_setup_camera()

func _setup_camera() -> void:
	var is_local_player = multiplayer.get_unique_id() == player_id
	camera.enabled = is_local_player
	camera.visible = is_local_player
	if is_local_player:
		camera.make_current()

func _process(delta: float) -> void:
	if not alive:
		return
	update_hud()

func _physics_process(delta: float) -> void:
	if not alive:
		return
	
	holding_jump = input_synchronizer.input_jump
	do_attack = input_synchronizer.input_attack
	looking_at = input_synchronizer.looking_at
	direction = input_synchronizer.input_direction
	
	if is_multiplayer_authority() or MultiplayerManager.host_mode:
		_is_on_floor = is_on_floor()
		_process_movement(delta)
		
	if not multiplayer.is_server() or MultiplayerManager.host_mode:
		_process_animations(delta)
	
	if do_attack:
		_attack()

func _process_movement(delta: float) -> void:
	
	
	# Gravity
	if not is_on_floor():
		var gravity_force = get_gravity().y
		
		# Jump Cuts
		if velocity.y < 0 and not holding_jump:
			velocity.y *= 0.5
		
		# Apex Jump Modifier
		elif abs(velocity.y) < APEX_VELOCITY_THRESHOLD:
			gravity_force *= APEX_GRAVITY_MULTIPLIER
		
		velocity.y += gravity_force * delta
		velocity.y = min(velocity.y, MAX_FALL_SPEED)
	
	# Jump handling
	_handle_jump_logic(delta)
	
	# Dash handling
	_handle_dash_logic(delta)
	
	# Movement handling
	_handle_movement(delta)

	move_and_slide()

func _handle_movement(delta: float) -> void:
	var target_speed = direction * MAX_MOVEMENT_SPEED

	# Snappy ground acceleration
	var accel = 0.0
	if is_on_floor():
		accel = 800.0
	else:
		accel = 400.0  # slower air accel
	
	# Apex Bonus: more air control near jump apex
	if not is_on_floor() and abs(velocity.y) < APEX_VELOCITY_THRESHOLD:
		accel *= 1.5

	# Apply acceleration toward target speed
	velocity.x = move_toward(velocity.x, target_speed, accel * delta)

	# Apply friction when no input
	if direction == 0:
		var friction = 500.0 if is_on_floor() else 200.0
		velocity.x = move_toward(velocity.x, 0, friction * delta)

func _handle_dash_logic(delta):
	if can_dash and do_dash:
		dash(delta)
	else:
		do_dash = false
	
func dash(delta):
	var dash_speed = max(DASH_SPEED, abs(velocity.x))
	dash_speed = min(dash_speed, MAX_DASH_SPEED)
	dash_speed = dash_speed * -1 if animated_sprite.flip_h else dash_speed
	
	velocity.x = dash_speed
	
	if velocity.y < 0:
		velocity.y = 0
		
	do_dash = false
	
	can_dash = false
	dash_cooldown.start()
	

func _handle_jump_logic(delta) -> void:
	if is_on_floor():
		_reset_jump_states(delta)
	elif coyote_timer.is_stopped():
		coyote_timer.start()

	jumps_remaining = max_jumps if is_on_floor() or can_coyote_jump else air_jumps_remaining
	var can_jump = can_coyote_jump or air_jumps_remaining > 0

	if do_jump:
		if can_jump:
			_jump(delta)
		else:
			_buffer_jump()

func _reset_jump_states(delta) -> void:
	ended_jump_early = false
	jumps_count = 0
	can_coyote_jump = true
	air_jumps_remaining = max_jumps - 1
	if jump_buffer:
		_jump(delta)
		jump_buffer = false

func _jump(delta) -> void:
	if is_on_floor() or can_coyote_jump:
		can_coyote_jump = false
	else:
		air_jumps_remaining -= 1
	
	do_jump = false
	jumps_count += 1
	velocity.y -= max(velocity.y, 0) + JUMP_VELOCITY
	animated_sprite.play("jump")
	
	jump_sfx.play()

func _buffer_jump() -> void:
	jump_buffer = true
	jump_buffer_timer.start()

func _process_animations(delta: float) -> void:
	if not alive:
		return

	# Flip sprite
	#animated_sprite.flip_h = direction < 0 if direction else animated_sprite.flip_h
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true

	# Death animation priority
	if animated_sprite.animation in ["death", "hurt"] and animated_sprite.is_playing():
		return

	# Jumping/Falling
	if not _is_on_floor:
		animated_sprite.play("jump")
		return

	# Running/Idle
	if abs(velocity.x) > 10:
		animated_sprite.play("run")
	else:
		animated_sprite.play("idle")

func _attack() -> void:
	if weapon:
		weapon.attack()

func take_damage(damage: int, knockback_force: Vector2 = Vector2.ZERO) -> void:
	if not alive:
		return

	hp -= damage

	# Knockback
	if knockback_force != Vector2.ZERO:
		velocity = knockback_force * 10
		velocity.y = min(velocity.y, knockback_force.y * 10)

	animated_sprite.play("hurt")
	hurt_sfx.play()

func kill() -> void:
	if not multiplayer.is_server():
		return
	hp = 0

func _process_death() -> void:
	if not alive:
		return
	
	collision.disabled = true
	alive = false
	death_count += 1
	animated_sprite.play("death")
	hurt_sfx.play()

	# Respawn
	await get_tree().create_timer(3.0).timeout
	_respawn()

func _respawn() -> void:
	collision.disabled = false
	animated_sprite.play("idle")
	hp = 100
	alive = true
	weapon = DEFAULT_WEAPON_SCENE.instantiate().init(self)
	global_position = get_tree().get_current_scene().get_node("SpawnPoint").global_position

func _on_jump_buffer_timer_timeout() -> void:
	jump_buffer = false

func _on_coyote_timer_timeout() -> void:
	can_coyote_jump = false

func update_hud() -> void:
	hud.hp_label.text = "HP: " + str(hp)
	hud.x_vel_label.text = "X-Vel: " + str(int(velocity.x))
	hud.y_vel_label.text = "Y-Vel: " + str(int(velocity.y))
	hud.jumps_label.text = "Jumps: " + str(jumps_remaining)
	hud.kill_label.text = "Kills: " + str(kill_count)
	hud.death_label.text = "Deaths: " + str(death_count)
	hud.hp_bar.value = hp
	
	hp_bar.value = hp

	if weapon is Gun:
		hud.ammo_label.text = "Ammo: " + str(weapon.ammo)
		hud.ammo_bar.max_value = weapon.max_ammo
		hud.ammo_bar.value = weapon.ammo


func _on_dash_cooldown_timeout() -> void:
	can_dash = true
