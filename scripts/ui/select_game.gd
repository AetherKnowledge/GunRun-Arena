extends Control

@onready var local_multiplayer_panel: Panel = $VBoxContainer/LocalMultiplayer/LocalMultiplayerPanel
@onready var popup_panel: Panel = $PopupPanel
@onready var username_txt_box: TextEdit = %UsernameTxtBox
@onready var game_code_txt_box: TextEdit = %GameCodeTxtBox
@onready var popup: MyPopup = $Popup
@onready var noray_box: CheckBox = %NorayBox

var popup_default_height: float = 287

var is_popup_panel_up: bool = false
var textbox_focused: bool = false
var do_host := false
var join_public: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	popup_default_height = popup_panel.size.y
	popup_panel.visible = false
	$PanelBlur.visible = false
	local_multiplayer_panel.visible = false
	$Popup.visible = false
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		show_popup_panel(false)

func local_multiplayer() -> void:
	pass # Replace with function body.


func local_multiplayer_mouse_entered() -> void:
	local_multiplayer_panel.visible = true


func local_multiplayer_mouse_exited() -> void:
	local_multiplayer_panel.visible = false


func on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func single_player_pressed() -> void:
	MultiplayerManager.is_multiplayer = false
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func host_pressed() -> void:
	join_public = false
	do_host = true
	popup_panel.size.y = popup_default_height/1.5
	
	%GameCodeLabel.visible = false
	%GameCodeTxtBox.visible = false
	%NorayBox.visible = true
	show_popup_panel(true)

func join_pressed() -> void:
	join_public = false
	do_host = false
	%GameCodeLabel.visible = true
	%GameCodeTxtBox.visible = true
	popup_panel.size.y = popup_default_height
	%NorayBox.visible = false
	show_popup_panel(true)

func _on_connect_pressed() -> void:
	if get_tree().root.get_node("Multiplayer"):
		get_tree().root.get_node("Multiplayer").queue_free()
		
	if do_host:
		var noray = noray_box.button_pressed
		var username = username_txt_box.text if username_txt_box.text != "" else username_txt_box.placeholder_text
		var err = await MultiplayerManager.host(username, noray)
		if err != OK:
			popup.position.y = popup_panel.position.y/2
			popup.make_error_popup(err)
			return
		
		if noray:
			popup.change_popup("Game Code", Noray.oid, true, "Start Game")
			await popup.button_clicked
		
		get_tree().change_scene_to_file("res://scenes/multiplayer/multiplayer.tscn")
		popup_panel.visible = false
	else:
		var username = username_txt_box.text if username_txt_box.text != "" else username_txt_box.placeholder_text
		var address = %GameCodeTxtBox.text
		
		if join_public:
			var err = await join_with_ip(MultiplayerManager.PUBLIC_LOBBY_ADDRESS, username)
			if err != OK:
				popup.position.y = popup_panel.position.y/2
				popup.make_error_popup(err)
				return
				
			get_tree().change_scene_to_file("res://scenes/multiplayer/multiplayer.tscn")
			popup_panel.visible = false
		
		# Attempt to join with ip first
		var err = await join_with_ip(address, username)
		if err != OK:
			print("Not ip attempting to connect with noray")
			err = await join_noray(address, username)
		
		if err != OK:
			print("Cannot join game")
			popup.position.y = popup_panel.position.y/2
			popup.make_error_popup(err)
			return
		
		get_tree().change_scene_to_file("res://scenes/multiplayer/multiplayer.tscn")
		popup_panel.visible = false
		
	
func join_noray(oid: String, username: String) -> Error:
	var err = await MultiplayerManager.join_noray(game_code_txt_box.text, username)
	if err != OK:
		return err
	
	return OK
	
func join_with_ip(full_address: String, username: String) -> Error:
	var parts = full_address.split(":")
	if parts.size() == 2 and parts[1].is_valid_int():
		var address = parts[0]
		var port = int(parts[1])
		var err = await MultiplayerManager.join_ip(address, port, username)
		return err
	else:
		print("Invalid address format. Use address:port")
		return 27
		
func _on_cancel_pressed() -> void:
	show_popup_panel(false)

func show_popup_panel(show: bool):
	popup_panel.visible = show
	
	if show:
		$PanelBlur.visible = show
		$AnimationPlayer.play("blur")
	else:
		$AnimationPlayer.play_backwards("blur")
		await $AnimationPlayer.animation_finished
		move_popup_panel(false)
		$AnimationPlayer.seek(0, true)
		$PanelBlur.visible = show
		

func panel_focus():
	%GameCodeTxtBox.release_focus()
	%UsernameTxtBox.release_focus()
	show_popup_panel(false)

func textbox_focus():
	textbox_focused = true
	move_popup_panel(true)

func textbox_unfocus():
	if not textbox_focused:
		move_popup_panel(false)
		
func move_popup_panel(up: bool):
	if OS.get_name() != "Android":
		return
	
	if is_popup_panel_up == up:
		return
	
	is_popup_panel_up = up
	
	if up:
		$AnimationPlayer.play("move_up_join_panel")
	else:
		$AnimationPlayer.play_backwards("move_up_join_panel")
	

func _on_panel_blur_gui_input(event: InputEvent) -> void:
	if not textbox_focused:
		return
	
	if event is InputEventMouse and event.is_pressed():
		panel_focus()
	if event is InputEventScreenTouch and event.is_pressed():
		panel_focus()


func _on_public_lobby_pressed() -> void:
	join_public = true
	do_host = false
	%GameCodeLabel.visible = false
	%GameCodeTxtBox.visible = false
	popup_panel.size.y = popup_default_height
	%NorayBox.visible = false
	show_popup_panel(true)
