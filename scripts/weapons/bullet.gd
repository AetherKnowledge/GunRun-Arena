extends AnimatedSprite2D
class_name Bullet
@onready var collider: RayCast2D = $RayCast2D

var speed: float = 120
var damage: int = 0
var knockback_force: Vector2 = Vector2(200,200)

func _physics_process(delta: float) -> void:
	global_position += Vector2(1,0).rotated(rotation) * speed * delta
	if collider.is_colliding() and not collider.get_collider() is Player:
		if collider.get_collider() is Player:
			var enemy = collider.get_collider() as Player
			enemy.take_damage(damage, get_recoil_force(enemy))
		
		queue_free()
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not is_playing():
		play("on_air")

func _on_timer_timeout() -> void:
	queue_free()

func get_recoil_force(player: Player) -> Vector2:
	var knockback_strength = 4
	var direction_to_player = sign(player.global_position.x - global_position.x)
	return Vector2(direction_to_player * knockback_strength, -knockback_strength)  # up and away
