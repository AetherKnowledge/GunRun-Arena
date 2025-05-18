extends Control

func _ready() -> void:
	MultiplayerManager.ready_to_add_players.emit()
	
