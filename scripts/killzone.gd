extends Area2D

@onready var timer: Timer = $Timer
var player = null

func _on_body_entered(body: Node2D) -> void:
	print("You died!")
	
	if body is Player:
		player = body as Player
		player.alive = false
		
	Engine.time_scale = 0.5
	timer.start()

func _on_timer_timeout() -> void:
	Engine.time_scale = 1
	if player != null:
		player.alive = true
	get_tree().reload_current_scene()
