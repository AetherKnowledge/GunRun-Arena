extends Bullet
class_name ExplodingBullet

var explosion_radius: float = 100.0
var exploded = false

func explode():
	exploded = true
	$RayCast2D.enabled = false
	scale *= 20
	
	for other_player in get_tree().get_nodes_in_group("Players"):
		if other_player.global_position.distance_to(global_position) <= explosion_radius:
			var distance = other_player.global_position.distance_to(global_position)
			var explosion_damage = (1 - (distance/explosion_radius)) * damage
			other_player.take_damage(explosion_damage, get_recoil_force(other_player))
	
	play("explosion")
	$ExplosionSFX.play()
	await animation_finished
	visible = false
	
	await $ExplosionSFX.finished
	# Queue the bullet for deletion after exploding
	queue_free()

func process_physics_server(delta: float):
	if exploded:
		return
	
	global_position += Vector2(1,0).rotated(rotation) * speed * delta
	if initial_pos.distance_to(global_position) >= max_distance:
		explode()
		return	
	
	elif collider.is_colliding():
		var target = collider.get_collider()
		if target is MultiplayerPlayer and (target as MultiplayerPlayer).player_id == player_id:
			return
		else:
			explode()
			
