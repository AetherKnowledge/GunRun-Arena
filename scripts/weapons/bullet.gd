extends AnimatedSprite2D
class_name Bullet
@onready var collider: RayCast2D = $RayCast2D

var speed: float = 200
var damage: int = 0
var knockback_force: Vector2 = Vector2(200,200)
var player: Player

func init(shoot_pos: Marker2D, damage: int, player: Player):
	self.player = player
	self.damage = damage
	
	global_position = shoot_pos.global_position
	# Calculate direction vector from shoot_pos to mouse position
	var dir = (player.looking_at - shoot_pos.global_position).normalized()
	# Set bullet rotation to face that direction
	global_rotation = dir.angle()
	return self

func _ready() -> void:
	visible = false
	await get_tree().process_frame
	visible = true

func _physics_process(delta: float) -> void:
	global_position += Vector2(1,0).rotated(rotation) * speed * delta
	if not collider.is_colliding():
		return
	
	var target = collider.get_collider()
	if not target is Player:
		queue_free()
		return
		
	var hit_player = target as Player
	if not MultiplayerManager.is_multiplayer:
		hit_player.take_damage(damage, get_recoil_force(hit_player))		
		
		queue_free()
		return
	
	# Multiplayer case
	if hit_player.player_id != player.player_id:
		hit_player.take_damage(damage, get_recoil_force(hit_player))
		if not hit_player.alive:
			player.kill_count += 1
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
