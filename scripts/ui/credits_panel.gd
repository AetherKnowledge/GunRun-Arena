extends BlurredPanel

func _on_back_btn_pressed() -> void:
	play_backwards()

func _on_rich_text_label_meta_clicked(meta: Variant) -> void:
	OS.shell_open(meta)
