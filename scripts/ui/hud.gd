extends Control
class_name UI

@onready var hp_label: Label = %HPLabel
@onready var x_vel_label: Label = %XVelLabel
@onready var y_vel_label: Label = %YVelLabel
@onready var ammo_label: Label = %AmmoLabel
@onready var player = $"../.."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not player is Player:
		return
	
	hp_label.text = "HP: " + str(player.hp)
	x_vel_label.text = "X-Vel: " + str(int(player.velocity.x))
	y_vel_label.text = "Y-Vel: " + str(int(player.velocity.y))
	
	if player.weapon is Gun:
		var gun = player.weapon as Gun
		ammo_label.text = "Ammo: " + str(gun.ammo)
		
