extends AnimatedSprite2D
class_name Bullet
@onready var collider: RayCast2D = $RayCast2D

var bullet_type: GlobalEnums.BulletTypes
var max_distance: int = 100
var speed: float = 200
var damage: int = 1
var knockback_strength = 10
var player: Player
var player_id: int = 100
var initial_pos: Vector2
var bullet_hit_has_played = false

func init(player: Player, shoot_pos: Marker2D, dir_angle: float, max_distance: int = 100, damage: int = 1, knockback_strength: int = 10):
	self.player = player
	self.max_distance = max_distance
	self.damage = damage
	self.knockback_strength = knockback_strength
	self.initial_pos = shoot_pos.global_position
	
	if player is Player:
		self.player_id = player.player_id
	
	# Position Bullet on barrel of gun
	global_position = shoot_pos.global_position
	
	# Set bullet rotation to face that direction
	global_rotation = dir_angle
	return self

func _ready() -> void:
	visible = false
	await get_tree().process_frame
	
	Settings.BulletLightsEnabledChanged.connect(_on_bullet_light_enabled_changed)
	$PointLight2D.visible = Settings.BulletLightsEnabled
	
	visible = true
	play("default")
	await animation_finished
	play("on_air")
	
func _on_bullet_light_enabled_changed(value: bool):
	$PointLight2D.visible = value

func _physics_process(delta: float) -> void:

	if multiplayer.is_server():
		process_physics_server(delta)
		return
	
	if not multiplayer.is_server() and not MultiplayerManager.host_mode:
		if not collider.is_colliding() or not collider.get_collider() is Player:
			return
		
		var hit_player = collider.get_collider() as Player
		if hit_player.player_id != player_id and not bullet_hit_has_played:
			hit_player.take_damage(damage, get_knockback_force(hit_player))
			bullet_hit_has_played = true
			
	

func process_physics_server(delta: float):
	global_position += Vector2(1,0).rotated(rotation) * speed * delta
	if initial_pos.distance_to(global_position) >= max_distance:
		queue_free()
		return	
	
	if not collider.is_colliding():
		return
	
	var target = collider.get_collider()
	if not target is Player:
		queue_free()
		return
		
	var hit_player = target as Player
	if hit_player.player_id != player.player_id:
		hit_player.take_damage(damage, get_knockback_force(hit_player))
		if not hit_player.alive:
			player.kill_count += 1
		queue_free()

func _on_timer_timeout() -> void:
	queue_free()

func get_knockback_force(player: Player) -> Vector2:
	var collision_shape = player.get_node("CollisionShape2D")
	var shape_center = player.to_global(collision_shape.position)
	
	var direction_to_center = (shape_center - global_position).normalized()
	direction_to_center.y *= 3
	
	return direction_to_center * knockback_strength
