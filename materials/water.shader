shader_type spatial;

uniform vec4 color : hint_color = vec4(1f);
uniform vec4 color2 : hint_color = vec4(0f, 0f, 0f, 1f);
uniform float glow_amount = 0f;
uniform float depth_factor = 1f;
uniform float wave_speed = 1f;
uniform float wave_amp = 0.2;
uniform sampler2D depth_ramp_tex : hint_albedo;
uniform sampler2D noise_tex : hint_albedo;
uniform sampler2D main_tex : hint_albedo;
uniform float distort_strength = 1f;
uniform float extra_height = 0f;


void vertex() {
	float noise_sample = textureLod(noise_tex, UV, 0.5).y;
	
	VERTEX.y += sin(TIME * wave_speed * noise_sample) * wave_amp * distort_strength + extra_height;
	VERTEX.x += cos(TIME * wave_speed * noise_sample) * wave_amp * distort_strength;
}


void fragment() {
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z;

	float foam_line = 1f - clamp(depth_factor * (linear_depth - FRAGCOORD.z / FRAGCOORD.w), 0f, 1f);
	if (FRAGCOORD.z / FRAGCOORD.w > linear_depth) {
		discard;
	}
		
	vec4 foam_ramp = vec4(texture(depth_ramp_tex, vec2(foam_line, 0.5)).rgb, 1f);
	vec4 albedo = texture(main_tex, UV);
	
	bool threshold = albedo.r < 0.25 || albedo.r > 0.55;
	albedo = (float(threshold) * color) + (float(!threshold) * color2);
	
	ALBEDO = foam_ramp.rgb * albedo.rgb;
	ALPHA = color.a * foam_ramp.a * albedo.a;
	EMISSION = color.rgb * color2.rgb * glow_amount;
}
