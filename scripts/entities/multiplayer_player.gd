extends Player
class_name MultiplayerPlayer

const default_weapon = preload("res://scenes/weapons/glock.tscn")
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurt: AudioStreamPlayer2D = $Hurt
@onready var jump_sfx: AudioStreamPlayer2D = $Jump
@onready var death_timer: Timer = $DeathTimer
@onready var jump_buffer_timer: Timer = $JumpBufferTimer
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var weapon: Weapon

var can_jump = false
var do_jump = false
var do_attack = false
var looking_at: Vector2
var _is_on_floor = true
var jump_buffer = false
var direction: int = 1

const WEAPON_POSITION := Vector2(3,-4)
const WEAPON_SCALE := Vector2(0.313, 0.313)
const MAX_MOVEMENT_SPEED = 150
const MOVEMENT_SPEED = 40
const JUMP_VELOCITY = -300.0
var alive = true

signal took_damage
signal died
signal weapon_changing
signal weapon_changed

@onready var input_synchronizer: InputSynchronizer = %InputSynchronizer

var player_id: int = 1:
	set(id):
		player_id = id
		%InputSynchronizer.set_multiplayer_authority(id)

@export var hp := 100:
	set(value):
		hp = clamp(value, 0, 100)
		if hp == 100:
			return
		took_damage.emit()
		if hp == 0:
			died.emit()

func _ready() -> void:
	weapon = default_weapon.instantiate()
	weapon.player = self
	_on_weapon_changed()
	
	if multiplayer.get_unique_id() == player_id:
		$Camera2D.make_current()
	else:
		$Camera2D.enabled = false
		$CanvasLayer.visible = false

func _physics_process(delta: float) -> void:
	# checks if alive
	if multiplayer.is_server():
		if not alive:
			return
		_is_on_floor = is_on_floor()
		process_movement(delta)
		
	if not multiplayer.is_server() || MultiplayerManager.host_mode:
		process_animations(delta)
		
	if do_attack:
		attack()
		
func process_animations(delta):
	
	if not alive:
		if not animated_sprite.animation == "death":
			animated_sprite.play("death")
	
	# Flip the sprite
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true
		
	# Play animations
	if not _is_on_floor:
		animated_sprite.play("jump")
	elif direction == 0:
		animated_sprite.play("idle")
	else:
		animated_sprite.play("run")
		
func process_movement(delta):
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
	hurt.play()
	
func kill():
	hp = 0

func _on_death() -> void:
	alive = false
	if not hurt.playing and not alive:
		Engine.time_scale = 0.5
	death_timer.start()

func _on_death_timer_timeout() -> void:
	Engine.time_scale = 1
	alive = true
	position = (get_tree().get_current_scene().get_node("SpawnPoint") as Marker2D).global_position

func _on_jump_buffer_timer_timeout() -> void:
	jump_buffer = false

func _on_coyote_timer_timeout() -> void:
	can_jump = false

func _on_weapon_changed() -> void:
	weapon.scale = WEAPON_SCALE
	weapon.position = WEAPON_POSITION
	weapon.on_player = true
	add_child(weapon)

func _on_weapon_changing() -> void:
	weapon.queue_free()
