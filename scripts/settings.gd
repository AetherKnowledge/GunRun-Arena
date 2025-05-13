extends Node

const DEFAULT_WIDTH = 1920
const DEFAULT_HEIGT = 1080

signal TouchControlsEnabledChanged(value: bool)

const DEBUG_UI = false
const DEBUG_GAME = false
var TouchControlsEnabled = false:
	set(value):
		TouchControlsEnabled = value
		TouchControlsEnabledChanged.emit(value)

func _ready() -> void:
	TouchControlsEnabled = OS.get_name() == "Android"
