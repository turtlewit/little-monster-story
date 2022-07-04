shader_type spatial;
render_mode unshaded;

uniform float transparency = 0.5;

void fragment() {
	float dist = ceil(0.5 - distance(UV, vec2(0.5)));
	ALBEDO = vec3(0.0);
	ALPHA = min(dist, transparency);
}