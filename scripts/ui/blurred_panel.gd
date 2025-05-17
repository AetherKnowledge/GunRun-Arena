@tool
extends PanelContainer
class_name BlurredPanel

signal now_shown
signal now_hidden

var blur_panel: ColorRect = ColorRect.new()
var animation_player: AnimationPlayer = AnimationPlayer.new()
const BLUR_SHADER = preload("res://assets/shaders/blur.gdshader")

@export var do_animation: bool = true
@export_range(0, 10, 0.001) var min_blur_ammount: float = 0
@export_range(0.1, 10, 0.001) var max_blur_ammount: float = 1

@export_range(0, 255, 1) var min_opacity: int = 0
@export_range(0, 255, 1) var max_opacity: int = 255

@export_range(0, 255, 1) var min_background_opacity: int = 0
@export_range(0, 255, 1) var max_background_opacity: int = 150

@export_range(0.1, 10, 0.001) var animation_length: float = 0.3


@export var hide_on_action: String = ""
@export var show_on_action: String = ""

signal animation_finished

func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	
	modulate.a = max_opacity
	self_modulate.a = max_background_opacity

func _input(event):
	if not animation_player.is_playing():
		if hide_on_action and Input.is_action_just_pressed(hide_on_action):
			play_backwards()
		elif show_on_action and Input.is_action_just_pressed(show_on_action):
			play()

# If overriding do super._init()
func _init() -> void:
	if Engine.is_editor_hint():
		return
	
	# This part is here to initialize blur panel first
	blur_panel.material = ShaderMaterial.new()
	blur_panel.material.shader = BLUR_SHADER
	blur_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	blur_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	blur_panel.name = "BlurPanel"
	
	add_child(blur_panel, true)
	animation_player.animation_finished.connect(animation_player_animation_finished)
	
	# This is here cuz export variables arent ready in init
	# We need to wait for ready for them to be loaded
	await ready
	
	blur_panel.material.set_shader_parameter("LOD", min_blur_ammount)
	_create_animation()
	add_child(animation_player)
	
	if not do_animation:
		blur_panel.material.set_shader_parameter("LOD", max_blur_ammount)
		self_modulate.a = float(max_background_opacity) / 255.0
		modulate.a = float(max_opacity) / 255.0
	else:
		visible = false
		
	
func _create_animation() -> void:
	var anim_library = AnimationLibrary.new()
	var anim = Animation.new()
	anim.length = animation_length
	
	# Animate blur
	var lod_track = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(lod_track, "BlurPanel:material:shader_parameter/lod")
	anim.track_insert_key(lod_track, 0, min_blur_ammount)
	anim.track_insert_key(lod_track, animation_length, max_blur_ammount)
	anim.track_set_interpolation_type(lod_track, Animation.INTERPOLATION_CUBIC)
	
	# Animate background opacity
	var background_opacity_track = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(background_opacity_track, ".:self_modulate:a")
	anim.track_insert_key(background_opacity_track, 0, float(min_background_opacity) / 255.0)
	anim.track_insert_key(background_opacity_track, animation_length, float(max_background_opacity) / 255.0)
	anim.track_set_interpolation_type(background_opacity_track, Animation.INTERPOLATION_CUBIC)
	
	# Animate self and children opacity
	var opacity_track = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(opacity_track, ".:modulate:a")
	anim.track_insert_key(opacity_track, 0, float(min_opacity) / 255.0)
	anim.track_insert_key(opacity_track, animation_length, float(max_opacity) / 255.0)
	anim.track_set_interpolation_type(opacity_track, Animation.INTERPOLATION_CUBIC)

	anim_library.add_animation("blur", anim)
	animation_player.add_animation_library("blur", anim_library)
	
func play(custom_blend: float = -1, custom_speed: float = 1.0, from_end: bool = false):
	if animation_player.is_playing():
		return
	
	visible = true
	animation_player.play("blur/blur", custom_blend, custom_speed, from_end)

func play_backwards(custom_blend: float = -1, custom_speed: float = 1.0):
	if animation_player.is_playing():
		return
	
	animation_player.play_backwards("blur/blur", custom_blend)
	
func animation_player_animation_finished(anim_name: StringName) -> void:
	animation_finished.emit()
	if animation_player.current_animation_position == 0:
		visible = false
		now_hidden.emit()
	else:
		now_shown.emit()
