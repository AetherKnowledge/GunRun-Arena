extends Control
class_name TouchControl

var click_cooldown := false
var last_click_position: Vector2 = Vector2(0,0)

func _input(event):
	if OS.get_name() != "Android" and not Settings.DEBUG_ANDROID:
		return
	
	if event is InputEventScreenTouch:
		if event.position == Vector2(0, 0):
			return
		
		if not click_cooldown:
			simulate_mouse_click(event.pressed, event.position)
			start_click_cooldown()

		if Settings.DEBUG_ANDROID:
			if event.pressed:
				print("Touched at: ", event.position)
			else:
				print("Released at: ", event.position)

func simulate_mouse_click(is_pressed: bool, touch_position: Vector2):
	# Convert raw screen touch position into viewport (stretched) coordinates
	var viewport_size = get_viewport().get_visible_rect().size
	var window_size = DisplayServer.window_get_size() as Vector2
	var scaled = (window_size - viewport_size)/2 + touch_position
	
	var scaled_pos = scaled
	
	var ev := InputEventMouseButton.new()
	ev.global_position = scaled_pos
	ev.position = scaled_pos
	ev.button_index = 1
	ev.pressed = is_pressed
	Input.parse_input_event(ev)

func start_click_cooldown():
	click_cooldown = true
	await get_tree().create_timer(0.01).timeout
	click_cooldown = false
