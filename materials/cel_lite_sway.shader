shader_type spatial;
render_mode skip_vertex_transform, ambient_light_disabled;

uniform float multiplier = 1f;
uniform sampler2D albedo : hint_black_albedo;
uniform vec4 albedo_color : hint_color = vec4(0f, 0f, 0f, 1f);
uniform sampler2D toon_ramp : hint_albedo;
uniform sampler2D emission_map : hint_albedo;
uniform vec4 emission_color : hint_color;

uniform float sway_factor : hint_range(0.0, 1.0) = 0.1;
uniform vec3 sway_direction = vec3(0.0, 0.0, 1.0);
uniform vec2 scroll_speed = vec2(.05, .025);
uniform sampler2D sway_texture;


void vertex() {
    vec3 world_origin = (WORLD_MATRIX * vec4(vec3(0.0), 1.0)).xyz;
    
    // v in model space
    vec3 v = VERTEX;
    float height = v.y;
    
    // v in world space
    v = (WORLD_MATRIX * vec4(v, 1.0)).xyz;
    
    // grass sway
    vec2 sway_uv = world_origin.xz * 0.01;
    sway_uv += scroll_speed * TIME;
    sway_uv = mod(sway_uv - (height * 0.001) + 0.1, 1.0);
    
    float f = texture(sway_texture, sway_uv).r;
    f = (f - 0.5) * 2.0;
    f *= sway_factor;
    
	// v += sway_direction * f * pow(clamp(length(VERTEX.xz), 0.5, 1.0), 2.0);
    v += sway_direction * f;
    
    // transform into camera space
    VERTEX = (INV_CAMERA_MATRIX * vec4(v, 1.0)).xyz;
    NORMAL = (MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
}


void fragment() {
	ALBEDO = max(albedo_color.rgb, texture(albedo, UV).rgb) * multiplier;
	EMISSION = texture(emission_map, UV).rgb * emission_color.rgb;
}


void light() {
	float NdotL = dot(LIGHT, NORMAL) * ATTENUATION.x;
	vec3 toon = texture(toon_ramp, vec2(NdotL * 0.5 + 0.5)).rgb;
	DIFFUSE_LIGHT += ALBEDO * toon * LIGHT_COLOR;
}
