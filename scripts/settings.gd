extends Node

const DEFAULT_WIDTH = 1920
const DEFAULT_HEIGT = 1080

signal TouchControlsEnabledChanged(value: bool)
signal PointLightsEnabledChanged(value: bool)
signal BulletLightsEnabledChanged(value: bool)
signal DynamicShadowEnabledChanged(value: bool)

const DEBUG_UI = false
const DEBUG_GAME = false
var TouchControlsEnabled = false:
	set(value):
		TouchControlsEnabled = value
		TouchControlsEnabledChanged.emit(value)
var PointLightsEnabled = true:
	set(value):
		PointLightsEnabled = value
		PointLightsEnabledChanged.emit(value)
var BulletLightsEnabled = true:
	set(value):
		BulletLightsEnabled = value
		BulletLightsEnabledChanged.emit(value)
var DynamicShadowEnabled = true:
	set(value):
		DynamicShadowEnabled = value
		DynamicShadowEnabledChanged.emit(value)

func _ready() -> void:
	if OS.get_name() == "Android":
		TouchControlsEnabled = true
		PointLightsEnabled = false
		BulletLightsEnabled = false
		DynamicShadowEnabled = false
