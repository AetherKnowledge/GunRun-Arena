extends CharacterBody2D
class_name Pickup

const MAX_ITEM_FALL_SPEED = 100
var ITEM_SCENES = {
	GlobalEnums.Items.Health: "HEALTH",
	GlobalEnums.Items.Glock: preload("res://scenes/weapons/glock.tscn"),
	GlobalEnums.Items.AK47: preload("res://scenes/weapons/ak47.tscn"),
	GlobalEnums.Items.Shotgun: preload("res://scenes/weapons/shotgun.tscn"),
	GlobalEnums.Items.Sniper: preload("res://scenes/weapons/sniper.tscn"),
	GlobalEnums.Items.RPG: preload("res://scenes/weapons/rpg.tscn")
}

@onready var pickup_collision: CollisionShape2D = $PickupArea/PickupCollision
@onready var pickup_sound: AudioStreamPlayer2D = $PickupSound

@export var do_random_item: bool = true
@export var selected_item: GlobalEnums.Items = GlobalEnums.Items.Glock
@export var do_despawn: bool = true
@export_range(5, 10000, 0.1) var time_to_despawn: float = 60

var item
var changed_texture = false

func _ready() -> void:
	if not multiplayer.is_server():
		pickup_collision.disabled = true
		return
	
	if do_despawn:
		$DespawnTimer.start()
		
	$DespawnTimer.wait_time = time_to_despawn
	if do_random_item:
		selected_item = (randi() % GlobalEnums.Items.values().size()) as GlobalEnums.Items
		
	item = ITEM_SCENES[selected_item]
	if item is PackedScene:
		item = item.instantiate()
	
		$AnimatedSprite2D.sprite_frames = item.sprite_frames
		$AnimatedSprite2D.scale *= 0.313
		$AnimatedSprite2D.play("default")
	else:
		$AnimatedSprite2D.scale *= 0.7
		$AnimatedSprite2D.play("default")
	
	$AnimatedLightOccluder2D.generate_occluders()
	$AnimatedLightOccluder2D.scale = $AnimatedSprite2D.scale


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		if not changed_texture:
			sync_weapon_texture_on_client()
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
		if item is Weapon:
			item.init(player)
			player.weapon = item
		else:
			player.hp += randi_range(10,50)
			
		pickup_collision.set_deferred("disabled", true)
		visible = false
		remove_pickup()

func _on_despawn_timer_timeout() -> void:
	if not multiplayer.is_server():
		return
	remove_pickup()
	
func remove_pickup():
	queue_free()
	
#func get_random_item():
	#selected_item = randi() % GlobalEnums.Items.values().size()
	#var random_gun = GlobalEnums.Items.values()[selected_item]
	#return ITEM_SCENES[random_gun]
	
func sync_weapon_texture_on_client():
	changed_texture = true
	var item_idx = GlobalEnums.Items.values()[selected_item]
	var random_item = ITEM_SCENES[item_idx]
	if random_item is PackedScene:
		random_item = random_item.instantiate()
		$AnimatedSprite2D.sprite_frames = random_item.sprite_frames
		$AnimatedSprite2D.scale *= 0.313
		$AnimatedSprite2D.play("default")
	else:
		$AnimatedSprite2D.scale *= 0.7
		$AnimatedSprite2D.play("default")
		
	$AnimatedLightOccluder2D.generate_occluders()
	$AnimatedLightOccluder2D.scale = $AnimatedSprite2D.scale
