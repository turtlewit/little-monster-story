shader_type spatial;
render_mode depth_draw_alpha_prepass;

uniform vec4 color : hint_color;
uniform float threshold : hint_range(0f, 1f) = 0.5;
uniform sampler2D noise_texture : hint_albedo;

void fragment() {
	vec4 tex = texture(noise_texture, UV + vec2(TIME) * 0.01);
	ALPHA = float(tex.r > threshold);
	ALPHA_SCISSOR = 0.5;
	EMISSION = color.rgb;
}