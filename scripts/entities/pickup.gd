extends CharacterBody2D
class_name Pickup

const MAX_ITEM_FALL_SPEED = 100
const ak47_preload = preload("res://scenes/weapons/ak_47.tscn")
const shotgun_preload = preload("res://scenes/weapons/shotgun.tscn")

@onready var pickup_collision: CollisionShape2D = $PickupArea/PickupCollision
@onready var pickup_sound: AudioStreamPlayer2D = $PickupSound

func _ready() -> void:
	if not multiplayer.is_server():
		pickup_collision.disabled = true

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	
	if not is_on_floor():
		var gravity_force = get_gravity().y * 0.7
		
		velocity.y += gravity_force * delta
		velocity.y = min(velocity.y, MAX_ITEM_FALL_SPEED)
		
	move_and_slide()

func _on_pickup_area_body_entered(body: Node2D) -> void:
	if not multiplayer.is_server():
		return
	
	if body is Player:
		var player: Player = body as Player
		var gun: Weapon = shotgun_preload.instantiate().init(player)
		# must come first to queue free the old weapon
		player.weapon = gun
		pickup_collision.set_deferred("disabled", true)
		visible = false
		remove_pickup()

func _on_despawn_timer_timeout() -> void:
	if not multiplayer.is_server():
		return
	remove_pickup()
	
func remove_pickup():
	queue_free()
