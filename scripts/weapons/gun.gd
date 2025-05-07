extends Weapon
class_name Gun

@export var ammo: int = 0
@export var cooldown: float = 0.5 # seconds
@export var fire_sfx: AudioStream
@export var empty_sfx: AudioStream
@export var pickup_sfx: AudioStream

var fire_stream: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
var empty_stream: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
var pickup_stream: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
var can_fire = true

func _ready() -> void:
	add_child(fire_stream)
	add_child(empty_stream)
	add_child(pickup_stream)
	
	fire_stream.bus = "SFX"
	empty_stream.bus = "SFX"
	pickup_stream.bus = "SFX"
	
	fire_stream.stream = fire_sfx
	empty_stream.stream = empty_sfx
	pickup_stream.stream = pickup_sfx

func attack():
	if not can_fire:
		return
	
	super.attack()
	
	if ammo > 0:
		stop()
		play("fire")
		fire_stream.play()
		ammo -= 1
		start_cooldown()
	elif ammo < 1 and not animation == "empty":
		stop()
		play("empty")
		empty_stream.play()

func start_cooldown() -> void:
	can_fire = false
	await get_tree().create_timer(cooldown).timeout
	can_fire = true
	
