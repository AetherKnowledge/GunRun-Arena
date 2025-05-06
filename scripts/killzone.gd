extends Area2D

@onready var timer: Timer = $Timer
@onready var game: GameManager = %GameManager
var player = null
var restarting = false

func _on_body_entered(body: Node2D) -> void:
	if restarting:
		return
	restarting = true
	
	print("You died!")
	
	if body is Player:
		player = body as Player
		player.kill()
		
	Engine.time_scale = 0.5
	timer.start()
	

func _on_timer_timeout() -> void:
	Engine.time_scale = 1
	if player != null:
		player.alive = true
	get_tree().reload_current_scene()
	
