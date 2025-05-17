@tool
extends LightOccluder2D
class_name AnimatedLightOccluder2D

@export var enabled: bool = true
@export var animated_sprite: AnimatedSprite2D
@export var cull_mode: OccluderPolygon2D.CullMode = OccluderPolygon2D.CULL_DISABLED as int
var animations = {}
var flip_h: bool = false

func _ready() -> void:
	if OS.has_feature("dedicated_server"):
		return
	
	if not animated_sprite or not animated_sprite.sprite_frames:
		return
	
	flip_h = animated_sprite.flip_h
	generate_occluders()
	animated_sprite.frame_changed.connect(_on_frame_changed)
	update_occluder(animated_sprite.frame)

func _process(delta: float) -> void:
	if OS.has_feature("dedicated_server"):
		return
	
	if not animated_sprite or not animated_sprite.sprite_frames:
		return
	
	if flip_h != animated_sprite.flip_h:
		flip_h = animated_sprite.flip_h
		scale.x *= -1
		
	# if has cull mode clockwise flip it to counter clockwise or vice versa
	if flip_h:
		if cull_mode == 1:
			occluder.cull_mode = 2
		elif cull_mode == 2:
			occluder.cull_mode = 1
	else:
		if cull_mode == 1:
			occluder.cull_mode = 1
		elif cull_mode == 2:
			occluder.cull_mode = 2

func generate_occluders() -> void:
	if OS.has_feature("dedicated_server"):
		return
	
	animations.clear()
	var sprite_frames = animated_sprite.sprite_frames
	if not sprite_frames:
		push_error("No SpriteFrames found on AnimatedSprite2D")
		return
	
	for animation in animated_sprite.sprite_frames.get_animation_names():
		
		var occluder_polygons: Array[OccluderPolygon2D] = []
		var frame_count = sprite_frames.get_frame_count(animation)
		
		for frame_idx in range(frame_count):
			var texture = sprite_frames.get_frame_texture(animation, frame_idx)
			if not texture:
				push_error("No texture for frame %d" % frame_idx)
				occluder_polygons.append(OccluderPolygon2D.new())
				continue
			
			# Get the image with correct texture settings
			var image = texture.get_image()
			if not image:
				push_error("Failed to get image from texture for frame %d" % frame_idx)
				occluder_polygons.append(OccluderPolygon2D.new())
				continue
			
			# Create a precise bitmap from alpha channel
			var bitmap = BitMap.new()
			bitmap.create_from_image_alpha(image)

			# Get pixel-perfect polygons with no simplification
			var polygons = bitmap.opaque_to_polygons(Rect2(Vector2(), bitmap.get_size()), 0)
			
			# Adjust for sprite positioning
			var texture_size = texture.get_size()
			var pixel_offset = Vector2(0.5, 0.5)  # Pixel center offsetO
			var sprite_offset = (-texture_size / 2.0) if animated_sprite.centered else Vector2.ZERO

			sprite_offset += animated_sprite.offset - pixel_offset

			# Create adjusted polygons
			var adjusted_polygons: Array[PackedVector2Array] = []
			for polygon in polygons:
				var adjusted_polygon = PackedVector2Array()
				for point in polygon:
					# Snap to pixel grid and apply offsets
					var snapped_point = point.floor() + pixel_offset + animated_sprite.position
					adjusted_polygon.append(snapped_point + sprite_offset)
				adjusted_polygons.append(adjusted_polygon)
			
			# Find largest polygon
			var largest_polygon: PackedVector2Array
			if adjusted_polygons.size() == 0:
				largest_polygon = []
			else:
				largest_polygon = find_largest_polygon(adjusted_polygons)
			
			
			# Create and store occluder
			var occluder = OccluderPolygon2D.new()
			occluder.cull_mode = cull_mode as int
			occluder.polygon = largest_polygon
			occluder_polygons.append(occluder)
		
		animations[animation] = occluder_polygons
	animated_sprite.frame_changed.emit()
		
func _on_frame_changed() -> void:
	if OS.has_feature("dedicated_server"):
		return
		
	if not enabled:
		return
		
	if not Settings.DynamicShadowEnabled and not Settings.PointLightsEnabled:
		return
	
	update_occluder(animated_sprite.frame)

func update_occluder(frame: int) -> void:
	if OS.has_feature("dedicated_server"):
		return
	
	var current_animation = animated_sprite.animation
	var occluder_polygons = animations[current_animation]
		
	if frame < 0 or frame >= occluder_polygons.size():
		push_error("Frame index out of range: %d" % frame)
		return
	occluder = occluder_polygons[frame]
	
func find_largest_polygon(polygons: Array[PackedVector2Array]) -> PackedVector2Array:
	var largest_polygon: PackedVector2Array = PackedVector2Array()
	var max_area := 0.0

	for polygon in polygons:
		var area : float = 0.0
		var points := polygon.size()
		if points >= 3:
			for i in range(points):
				var p1 = polygon[i]
				var p2 = polygon[(i + 1) % points]
				area += (p1.x * p2.y) - (p2.x * p1.y)
			area = abs(area) * 0.5
		else:
			area = 0.0

		if area > max_area:
			max_area = area
			largest_polygon = polygon
	
	return largest_polygon
