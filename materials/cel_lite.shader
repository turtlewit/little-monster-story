shader_type spatial;
render_mode ambient_light_disabled;

uniform float multiplier = 1f;
uniform sampler2D albedo : hint_black_albedo;
uniform vec4 albedo_color : hint_color = vec4(0f, 0f, 0f, 1f);
uniform sampler2D toon_ramp : hint_albedo;
uniform sampler2D emission_map : hint_albedo;
uniform vec4 emission_color : hint_color;

void fragment() {
	ALBEDO = max(albedo_color.rgb, texture(albedo, UV).rgb) * multiplier;
	EMISSION = texture(emission_map, UV).rgb * emission_color.rgb;
}


void light() {
	float NdotL = dot(LIGHT, NORMAL) * ATTENUATION.x;
	vec3 toon = texture(toon_ramp, vec2(NdotL * 0.5 + 0.5)).rgb;
	DIFFUSE_LIGHT += ALBEDO * toon * LIGHT_COLOR;
}
