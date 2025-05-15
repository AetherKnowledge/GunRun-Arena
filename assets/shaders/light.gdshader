shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;
uniform float threshold : hint_range(0.0, 1.0) = 0.05;

const vec3 sky_colors[4] = vec3[](
    vec3(0.3137, 0.5529, 0.8),    // #508DCC
    vec3(0.2392, 0.4314, 0.6275), // #3D6EA0
    vec3(0.1843, 0.3647, 0.5529), // #2F5D8D
    vec3(0.2118, 0.2157, 0.3843)  // #363762
);
const vec3 light_colors = vec3(0.4863, 0.6745, 0.8784);

void fragment() {
    vec4 screen_col = texture(SCREEN_TEXTURE, SCREEN_UV);
    
    // Match raw screen color to sky tones (pre-lighting!)
    for (int i = 0; i < 4; i++) {
        if (distance(screen_col.rgb, sky_colors[i]) < threshold) {
            discard; // Don't draw dimmer over sky
        }
    }

    COLOR = texture(TEXTURE, UV) * COLOR; // Respect modulate and dimmer alpha
	// Draw dimmer normally
    //COLOR = vec4(0.0, 0.0, 0.0, dim_strength) * COLOR.a;
}