@tool
extends LightOccluder2D
class_name AnimatedLightOccluder2D

@export var animated_sprite: AnimatedSprite2D
var animations = {}
var flip_h: bool = false

func _ready() -> void:
	if not animated_sprite or not animated_sprite.sprite_frames:
		return
	
	flip_h = animated_sprite.flip_h
	generate_occluders()
	animated_sprite.frame_changed.connect(_on_frame_changed)
	update_occluder(animated_sprite.frame)

func _process(delta: float) -> void:
	if not animated_sprite or not animated_sprite.sprite_frames:
		return
	
	if flip_h != animated_sprite.flip_h:
		flip_h = animated_sprite.flip_h
		scale.x *= -1

func generate_occluders() -> void:
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
			
			if adjusted_polygons.size() == 0:
				occluder_polygons.append(OccluderPolygon2D.new())
				return
			
			# Create and store occluder
			var occluder = OccluderPolygon2D.new()
			occluder.polygon = adjusted_polygons[0]
			occluder_polygons.append(occluder)
		
		animations[animation] = occluder_polygons

func _on_frame_changed() -> void:
	update_occluder(animated_sprite.frame)

func update_occluder(frame: int) -> void:
	var current_animation = animated_sprite.animation
	var occluder_polygons = animations[current_animation]
		
	if frame < 0 or frame >= occluder_polygons.size():
		push_error("Frame index out of range: %d" % frame)
		return
	occluder = occluder_polygons[frame]
