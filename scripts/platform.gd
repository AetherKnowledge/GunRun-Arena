extends AnimatableBody2D

@export var animation_player_optional: AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if animation_player_optional:
		multiplayer.peer_connected.connect(on_player_connected)

func on_player_connected(id):
	if not multiplayer.is_server():
		animation_player_optional.stop()
		animation_player_optional.set_active(false)
