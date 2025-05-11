extends Area2D

@onready var game: GameManager = %GameManager

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		var player = body as Player
		player.kill()
	elif body is Pickup:
		var pickup = body as Pickup
		pickup.remove_pickup()
