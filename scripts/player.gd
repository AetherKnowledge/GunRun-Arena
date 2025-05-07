extends CharacterBody2D
class_name Player

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurt: AudioStreamPlayer2D = $Hurt
@onready var jump_sfx: AudioStreamPlayer2D = $Jump
@onready var death_timer: Timer = $DeathTimer
@onready var jump_buffer_timer: Timer = $JumpBufferTimer
@onready var coyote_timer: Timer = $CoyoteTimer

var jump_buffer = false
var can_jump = false

const SPEED = 120
const JUMP_VELOCITY = -300.0
var alive = true

signal took_damage
signal died

var hp := 100:
	set(value):
		hp = clamp(value, 0, 100)
		took_damage.emit()
		if hp == 0:
			died.emit()

func _physics_process(delta: float) -> void:
	
	# checks if alive
	if not alive:
		if not animated_sprite.animation == "death":
			animated_sprite.play("death")
		return
	
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

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("move_left", "move_right")
	
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
			
	# Apply movement
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	#if direction:
		#var horizontal = clamp(direction * SPEED, velocity.x, direction * SPEED)
		#velocity.x = move_toward(velocity.x, horizontal, 300 * delta)
	#else:
		#velocity.x = move_toward(velocity.x, 0, SPEED * 300 * delta)

	move_and_slide()
	
	

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
