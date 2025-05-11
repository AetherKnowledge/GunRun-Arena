extends CharacterBody2D
class_name Pickup

const MAX_ITEM_FALL_SPEED = 100
var WEAPON_SCENES = {
	GlobalEnums.Guns.Glock: preload("res://scenes/weapons/glock.tscn"),
	GlobalEnums.Guns.AK47: preload("res://scenes/weapons/ak_47.tscn"),
	GlobalEnums.Guns.Shotgun: preload("res://scenes/weapons/shotgun.tscn"),
	GlobalEnums.Guns.Sniper: preload("res://scenes/weapons/sniper.tscn"),
	GlobalEnums.Guns.RPG: preload("res://scenes/weapons/rpg.tscn")
}

@onready var pickup_collision: CollisionShape2D = $PickupArea/PickupCollision
@onready var pickup_sound: AudioStreamPlayer2D = $PickupSound
var item: Weapon

func _ready() -> void:
	if not multiplayer.is_server():
		pickup_collision.disabled = true
		return
		
	item = get_random_weapon_scene().instantiate()
	$AnimatedSprite2D.sprite_frames = item.sprite_frames
	$AnimatedSprite2D.scale *= 0.313
	$AnimatedSprite2D.play("default")

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
		# must come first to queue free the old weapon
		item.init(player)
		player.weapon = item
		pickup_collision.set_deferred("disabled", true)
		visible = false
		remove_pickup()

func _on_despawn_timer_timeout() -> void:
	if not multiplayer.is_server():
		return
	remove_pickup()
	
func remove_pickup():
	queue_free()
	
func get_random_weapon_scene() -> PackedScene:
	var random_gun = GlobalEnums.Guns.values()[randi() % GlobalEnums.Guns.values().size()]
	return WEAPON_SCENES[random_gun]
	
