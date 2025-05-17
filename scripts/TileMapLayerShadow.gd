extends TileMapLayer
class_name TileMapLayerShadow

func _ready() -> void:
	Settings.DynamicShadowEnabledChanged.connect(_on_dynamic_shadow_enabled_changed)
	visible = !Settings.DynamicShadowEnabled

func _on_dynamic_shadow_enabled_changed(value: bool):
	visible = !value
