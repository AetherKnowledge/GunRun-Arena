extends Node
class_name GameManager
@onready var pause_menu: PauseMenu = %PauseMenu
@onready var ui: UI = %UI
@onready var player: Player = %Player

func _process(delta: float) -> void:
	ui.hp = player.hp
	ui.xvel = player.velocity.x
	ui.yvel = player.velocity.y
	
	if player.weapon is Gun:
		var gun = player.weapon as Gun
		ui.ammo = gun.ammo

func pause():
	get_tree().paused = true

func resume():
	get_tree().paused = false

func restart():
	get_tree().reload_current_scene()

func _on_pause_menu_state_changed() -> void:
	get_tree().paused = pause_menu.paused
