extends AnimatedSprite2D
class_name Bullet
@onready var collider: RayCast2D = $RayCast2D

var speed: float = 120

func _physics_process(delta: float) -> void:
	global_position += Vector2(1,0).rotated(rotation) * speed * delta
	if collider.is_colliding() and not collider.get_collider() is Player:
		queue_free()
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not is_playing():
		play("on_air")

func _on_timer_timeout() -> void:
	queue_free()
