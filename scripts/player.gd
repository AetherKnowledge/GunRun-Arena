extends CharacterBody2D
class_name Player

const SPEED = 130.0
const JUMP_VELOCITY = -300.0
var alive = true

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var death_sfx: AudioStreamPlayer2D = $Death
@onready var jump_sfx: AudioStreamPlayer2D = $Jump

func _input(event):
	if event.is_action_pressed("jump") and is_on_floor() and alive:
		jump_sfx.stop()
		jump_sfx.play(0.0)


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# checks if alive
	if not alive:
		if not animated_sprite.animation == "death":
			animated_sprite.play("death")
		return
		
	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

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

	move_and_slide()
	
func kill() -> void:
	alive = false
	if not death_sfx.playing and not alive:
		death_sfx.play()
	
