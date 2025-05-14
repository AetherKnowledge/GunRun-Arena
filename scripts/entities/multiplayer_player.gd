extends Player
class_name MultiplayerPlayer

const DEFAULT_WEAPON_SCENE = preload("res://scenes/weapons/glock.tscn")

# Node references
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurt_sfx: AudioStreamPlayer2D = $Hurt
@onready var jump_sfx: AudioStreamPlayer2D = $Jump
@onready var dash_cooldown: Timer = $DashCooldown
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var hud: HUD = %HUD
@export var input: PlayerInput
@onready var camera: Camera2D = $Camera2D
@onready var hp_bar: ProgressBar = $HPBar
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var invincibility_timer: Timer = $InvincibilityTimer

# Player states
var do_dash: bool = false
var do_attack: bool = false
var can_coyote_jump: bool = true
var holding_jump: bool = false
var kill_count: int = 0
var death_count: int = 0
var has_dashed: bool = false
var respawning: bool = false
var knockback_force: Vector2 = Vector2.ZERO
var has_knockback: bool = false

# Jumping vars
@export var max_jumps: int = 2
var air_jumps_remaining: int = 1
var jumps_remaining: int = 1
var jumps_count: int = 0
var ended_jump_early = false
var has_jumped: bool = false

# Dashing vars
@export var max_dash: int = 1
var can_dash: bool = true
var dash_remaining: int = 1

# Multiplayer
var username := "Player"
var player_id: int = 1:
	set(id):
		player_id = id
		input.set_multiplayer_authority(id)

# Weapon logic
var weapon: Weapon:
	set(value):
		
		if weapon and multiplayer.is_server():
			weapon.queue_free()
		
		weapon = value
		weapon.scale = WEAPON_SCALE
		weapon.position = WEAPON_POSITION
		
		if not multiplayer.is_server():
			return
		
		
		$Weapon.add_child(weapon, true)

# Health
@export var hp: int = 100:
	set(value):
		if value == hp:
			return
		elif value > hp and alive:
			$Heal.play()
			
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
		
	_respawn()
	_setup_camera()
	update_hud()
	
func _setup_camera() -> void:
	var is_local_player = multiplayer.get_unique_id() == player_id
	camera.enabled = is_local_player
	camera.visible = is_local_player
	if is_local_player:
		camera.make_current()

func _process(delta: float) -> void:
	if not alive:
		return
	
	if not multiplayer.is_server() or MultiplayerManager.host_mode:
		_process_animations(delta)
		update_hud()
		
	if do_attack:
		_attack()
	
func _rollback_tick(delta, tick, is_fresh):
	if respawning:
		respawning = false
		global_position = get_random_spawnpoint().global_position
		velocity = Vector2(0,0)
		$TickInterpolator.teleport()
	else:
		_process_movement(delta)

func _process_movement(delta: float) -> void:
	if not alive:
		return
	
	do_dash = input.input_dash
	holding_jump = input.input_jump
		
	do_attack = input.input_attack
	looking_at = input.looking_at
	direction = input.input_direction
	
	_force_update_is_on_floor()
	
	# Gravity
	if not is_on_floor():
		var gravity_force = get_gravity().y * 0.7
		
		# Jump Cuts only only after knockback timer is done
		if velocity.y < 0 and not holding_jump:
			velocity.y *= 0.7
		
		# Apex Jump Modifier
		elif abs(velocity.y) < APEX_VELOCITY_THRESHOLD:
			gravity_force *= APEX_GRAVITY_MULTIPLIER
			
		velocity.y += gravity_force * delta
		velocity.y = min(velocity.y, MAX_FALL_SPEED)
	
	# Jump handling
	_handle_jump_logic()
	
	# Dash handling
	_handle_dash_logic(delta)
	
	# Movement handling
	_handle_movement(delta)
	
	velocity *= NetworkTime.physics_factor
	move_and_slide()
	velocity /= NetworkTime.physics_factor

func _force_update_is_on_floor():
	var old_velocity = velocity
	velocity = Vector2.ZERO
	move_and_slide()
	velocity = old_velocity

func _handle_movement(delta: float) -> void:
	if has_knockback:
		has_knockback = false
		do_knockback(knockback_force)
	
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
	if can_dash and do_dash and not has_dashed:
		dash(delta)
	else:
		has_dashed = false
	
func dash(delta):
	has_dashed = true
	
	var dash_speed = max(DASH_SPEED, abs(velocity.x))
	dash_speed = min(dash_speed, MAX_DASH_SPEED)
	dash_speed = dash_speed * -1 if animated_sprite.flip_h else dash_speed
	
	velocity.x = dash_speed
	
	if velocity.y < 0:
		velocity.y = 0
		
	do_dash = false
	
	can_dash = false
	dash_cooldown.start()
	

func _handle_jump_logic() -> void:
	if is_on_floor():
		_reset_jump_states()
	elif coyote_timer.is_stopped():
		coyote_timer.start()

	jumps_remaining = max_jumps if is_on_floor() or can_coyote_jump else air_jumps_remaining
	var can_jump = is_on_floor() or can_coyote_jump or air_jumps_remaining > 0
	
	if holding_jump and can_jump and not has_jumped:
		has_jumped = true
		_jump()
	
	elif holding_jump and is_on_floor():
		has_jumped = true
		_jump()
	elif not holding_jump:
		has_jumped = false
		
func _reset_jump_states() -> void:
	ended_jump_early = false
	jumps_count = 0
	can_coyote_jump = true
	air_jumps_remaining = max_jumps - 1

func _jump() -> void:
	
	
	if is_on_floor() or can_coyote_jump:
		can_coyote_jump = false
	else:
		air_jumps_remaining -= 1
	
	jumps_count += 1
	velocity.y = -JUMP_VELOCITY
	animated_sprite.play("jump")
	
	jump_sfx.play()

func _buffer_jump() -> void:
	jump_buffer = true

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
	if not is_on_floor():
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
	if not alive or not invincibility_timer.is_stopped():
		return
	
	if not multiplayer.is_server() and not MultiplayerManager.host_mode:
		animated_sprite.play("hurt")
		hurt_sfx.play()
		return
	elif MultiplayerManager.host_mode:
		animated_sprite.play("hurt")
		hurt_sfx.play()

	hp -= damage

	# Knockback
	if alive and knockback_force != Vector2.ZERO:
		self.knockback_force = knockback_force
		has_knockback = true
		$KnockbackGravityCancelTimer.start()

func recoil(recoil_force: Vector2 = Vector2.ZERO) -> void:
	if alive and recoil_force != Vector2.ZERO:
		knockback_force = recoil_force
		has_knockback = true
		
func do_knockback(force: Vector2 = Vector2.ZERO):
	if alive and force != Vector2.ZERO:
		velocity = force * 10
		force = Vector2.ZERO

func kill() -> void:
	if not multiplayer.is_server():
		return
	hp = 0

func _process_death() -> void:
	if not alive:
		return
	
	alive = false
	death_count += 1
	animated_sprite.play("death")
	hurt_sfx.play()
	
	if multiplayer.is_server():
		weapon.queue_free()

	# Respawn
	await get_tree().create_timer(3.0).timeout
	_respawn()

func _respawn() -> void:
	$AnimationPlayer.play("invincible")
	invincibility_timer.start()
	collision.disabled = false
	animated_sprite.play("idle")
	hp = 100
	alive = true
	if multiplayer.is_server():
		weapon = DEFAULT_WEAPON_SCENE.instantiate().init(self)
		respawning = true

func get_random_spawnpoint() -> Marker2D:
	var spawnpoints = get_tree().get_nodes_in_group("SpawnPoints")
	if spawnpoints.size() < 1:
		return
		
	var rand_idx = randi() % spawnpoints.size()
	return spawnpoints[rand_idx]
	 
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
	$UsernameLabel.text = username
	
	if weapon and weapon is Gun:
		hud.ammo_label.text = "Ammo: " + str(weapon.ammo)
		hud.ammo_bar.max_value = weapon.max_ammo
		hud.ammo_bar.value = weapon.ammo


func _on_dash_cooldown_timeout() -> void:
	can_dash = true

func _on_weapon_spawner_spawned(node: Node) -> void:
	weapon = node as Weapon
	weapon.init(self)
	weapon.reparent($Weapon)
	weapon.PickupSFX.play()


func _on_invincibility_timer_timeout() -> void:
	$AnimationPlayer.stop()
