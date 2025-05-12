@tool
extends VBoxContainer

@export var label_text: String = "Label"
@export var min_value: int = 0
@export var max_value: int = 100
@export var value: int = 0

signal value_changed(value: float)

func _process(delta: float) -> void:
	$Slider.value = value
	$Label.text = label_text
	$Slider.max_value = max_value
	$Slider.min_value = min_value

func _on_slider_value_changed(value: float) -> void:
	if Engine.is_editor_hint():
		print(value)
		return
	
	self.value = value
	value_changed.emit(value)
