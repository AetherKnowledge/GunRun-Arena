extends Button
class_name TouchUIButton

const EMPTY_TEXTURE = preload("res://assets/ui/empty-texture.png")
var touch_screen_button: TouchScreenButton = TouchScreenButton.new()

func _ready() -> void:
	if OS.get_name() != "Android"  and not Settings.DEBUG_ANDROID:
		return
	
	touch_screen_button.texture_normal = EMPTY_TEXTURE
	touch_screen_button.scale = self.size
	
	self.pressed.connect(test)
	self.add_child(touch_screen_button)
	
func _process(delta: float) -> void:
	if touch_screen_button.scale != self.size:
		touch_screen_button.scale = self.size
	
	if touch_screen_button.global_position != self.global_position:
		touch_screen_button.global_position = self.global_position

func test():
	print("bruh")
	
