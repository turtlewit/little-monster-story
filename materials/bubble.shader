shader_type spatial;
render_mode cull_disabled;

uniform sampler2D distortion_texture : hint_albedo;
uniform sampler2D vision_texture : hint_albedo;
uniform vec4 fresnel_color : hint_color;
uniform float amplifier = 3.0;
uniform float speed : hint_range(0, 4) = 0.4;
uniform float distortion = 0.1;
uniform float texture_normal_scale = 1f;


float value(vec3 rgb) {
	return max(max(rgb.r, rgb.g), rgb.b);
}


void vertex() {
	vec4 surface = texture(distortion_texture, UV + vec2(TIME) * speed);
	VERTEX += NORMAL * value(surface.rgb) * distortion;
}


void fragment() {
	ROUGHNESS = 0f;
	METALLIC = 1f;
	RIM = 1f;
	RIM_TINT = 0f;
	
	float fresnel = sqrt(1f - dot(NORMAL, VIEW));
	ALBEDO = texture(vision_texture, vec2(NORMAL.x, -NORMAL.y) * texture_normal_scale).rgb + (fresnel * fresnel_color.rgb);
	EMISSION = vec3(0.7f);
}
