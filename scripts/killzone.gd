extends Area2D

@onready var game: GameManager = %GameManager
var player = null

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		var player = body as Player
		player.kill()
	
