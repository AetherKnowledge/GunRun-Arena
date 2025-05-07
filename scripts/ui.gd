extends Control
class_name UI

@onready var hp_label: Label = %HPLabel
@onready var x_vel_label: Label = %XVelLabel
@onready var y_vel_label: Label = %YVelLabel
@onready var ammo_label: Label = %AmmoLabel

var hp: int = 0
var xvel: int = 0
var yvel: int = 0
var ammo: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	hp_label.text = "HP: " + str(hp)
	x_vel_label.text = "X-Vel: " + str(xvel)
	y_vel_label.text = "Y-Vel: " + str(yvel)
	ammo_label.text = "Ammo: " + str(ammo)
