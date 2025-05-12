extends BlurredPanel

func _ready() -> void:
	%MasterVolume.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master"))) * 100
	%MusicVolume.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))) * 100
	%SFXVolume.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX"))) * 100
	
	print(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master"))) * 100)
	print(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))) * 100)
	print(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX"))) * 100)

func _on_back_btn_pressed() -> void:
	play_backwards()

func _on_master_volume_value_changed(value: float) -> void:
	var dB = linear_to_db(value/100)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), dB)


func _on_music_volume_value_changed(value: float) -> void:
	var dB = linear_to_db(value/100)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), dB)


func _on_sfx_volume_value_changed(value: float) -> void:
	var dB = linear_to_db(value/100)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), dB)
	
