extends Area2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
const gun_preload = preload("res://scenes/weapons/ak_47.tscn")

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		
		var player: Player = body as Player
		var gun: Weapon = gun_preload.instantiate().init(player)
		# must come first to queue free the old weapon
		player.weapon = gun
		
		animation_player.play("pickup")
