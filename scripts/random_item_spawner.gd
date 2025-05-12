extends Area2D

const PICKUP_SCENE = preload("res://scenes/entities/pickup.tscn")
@export_range(0,100,1) var max_items: int = 8

func _physics_process(delta: float) -> void:
	pass

func spawn_item_on_segment():
	if not $CollisionShape2D:
		return
	
	var segment_shape = $CollisionShape2D.shape as SegmentShape2D
	var a = segment_shape.a
	var b = segment_shape.b
	
	# Pick a random point between a and b
	var t = randf() # random float between 0.0 and 1.0
	var random_point = a.lerp(b, t)

	# Apply the collision shape's global transform
	var global_point = $CollisionShape2D.global_transform * random_point
	
	var pickup = PICKUP_SCENE.instantiate()
	get_tree().get_current_scene().get_node("Items").add_child(pickup, true)
	pickup.global_position = global_point

func _on_spawn_timer_timeout() -> void:
	if get_child_count() >= max_items + 3 or MultiplayerManager.player_count < 1:
		return
	
	spawn_item_on_segment()
