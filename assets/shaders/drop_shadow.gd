extends ColorRect

func _ready():
	var world := get_world_2d()
	# gets the combined occluder SDF for all layers
	var sdf_tex = world.get_sdf_occluder_texture_all_layers()
	material.set_shader_param("sdf_texture", sdf_tex)
