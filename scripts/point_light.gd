extends PointLight2D
class_name PointLight

func _ready() -> void:
	Settings.PointLightsEnabledChanged.connect(_on_point_light_enabled_changed)
	enabled = Settings.PointLightsEnabled

func _on_point_light_enabled_changed(value: bool):
	enabled = value
