extends Control
class_name MyPopup

@export var title: String = "Title"
@export var text: String = "Text"
@export var button_text: String = "OK"
@export var hide_on_click: bool = true

signal button_clicked

func _ready() -> void:
	%Title.text = title
	%Text.text = text
	%Button.text = button_text
	show_copy_button(false)

func _on_button_pressed() -> void:
	if hide_on_click:
		visible = false
	
	button_clicked.emit()
	
func make_error_popup(err: Error, show_button: bool = false):
	visible = true
	%Title.text = "Error"
	%Text.text = str(err)
	show_copy_button(show_button)
	
func change_popup(title: String = "Title", text: String = "Text", show_button: bool = false, button_text: String = "OK"):
	visible = true
	%Title.text = title
	%Text.text = text
	%Button.text = button_text
	show_copy_button(show_button)
	
func show_copy_button(show: bool):
	if show:
		%CopyBtn.visible = true
		%MarginContainer.add_theme_constant_override("margin_left", %CopyBtn.size.x)
	else:
		%CopyBtn.visible = false
		%MarginContainer.add_theme_constant_override("margin_left", 0)

func _on_copy_btn_pressed() -> void:
	# Get the current contents of the clipboard
	var current_clipboard = DisplayServer.clipboard_get()
	# Set the contents of the clipboard
	DisplayServer.clipboard_set(%Text.text)
