extends CharacterBody2D

const SPEED = 40
var direction = 1
var damage = 0

@onready var ray_cast_right: RayCast2D = $RayCastRight
@onready var ray_cast_left: RayCast2D = $RayCastLeft
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Flip the sprite
	if ray_cast_right.is_colliding():
		direction = -1
		animated_sprite.flip_h = true
	if ray_cast_left.is_colliding():
		direction = 1
		animated_sprite.flip_h = false
			
	# Apply movement
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	move_and_slide()


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body is Player:
		var player = body as Player
		player.take_damage(damage, get_knockback_force(player))

func get_knockback_force(player: Player) -> Vector2:
	var knockback_strength = 4
	var direction_to_player = sign(player.global_position.x - global_position.x)
	return Vector2(direction_to_player * knockback_strength, -knockback_strength)  # up and away
