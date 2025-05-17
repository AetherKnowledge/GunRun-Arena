extends Sprite2D
class_name HouseDim

func _ready() -> void:
	pass
	#Settings.PointLightsEnabledChanged.connect(_on_point_lights_enabled_changed)
	#set_instance_shader_parameter("shader_enabled", Settings.PointLightsEnabled)

func _on_point_lights_enabled_changed(value: bool):
	pass
	#set_instance_shader_parameter("shader_enabled", Settings.PointLightsEnabled)
