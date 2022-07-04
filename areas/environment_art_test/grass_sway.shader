shader_type spatial;
render_mode blend_mix,depth_draw_opaque,diffuse_burley,cull_disabled,skip_vertex_transform;
uniform vec4 albedo : hint_color;
uniform sampler2D texture_albedo : hint_albedo;
uniform float specular;
uniform float metallic;
uniform float alpha_scissor_threshold;
uniform float roughness : hint_range(0,1);
uniform float point_size : hint_range(0,128);
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

uniform vec3 player_position;
uniform float player_radius = 1.0;

uniform float sway_factor : hint_range(0.0, 1.0) = 0.5;
uniform vec3 sway_direction = vec3(0.0, 0.0, 1.0);
uniform vec2 scroll_speed;
uniform sampler2D sway_texture;


void vertex() {
	ROUGHNESS=roughness;
	UV=UV*uv1_scale.xy+uv1_offset.xy;
	
	vec3 world_origin = (WORLD_MATRIX * vec4(vec3(0.0), 1.0)).xyz;
	
	// v in model space
	vec3 v = VERTEX;
	float height = v.y;
	
	// v in world space
	v = (WORLD_MATRIX * vec4(v, 1.0)).xyz;
	
	// player distortion
	vec3 player_dir = normalize(world_origin - player_position);
	player_dir.y = -sqrt(player_dir.y * player_dir.y);
	float dist_factor = clamp(distance(world_origin * vec3(1.0, 1.0, 1.0), player_position * vec3(1.0, 1.0, 1.0)), 0.0, player_radius);
	dist_factor /= player_radius;
	dist_factor = 1.0 - dist_factor;
	v += player_dir * dist_factor * player_radius * (VERTEX).y;
	
	// grass sway
	vec2 sway_uv = world_origin.xz * 0.01;
	sway_uv += scroll_speed * TIME;
	sway_uv = mod(sway_uv, 1.0);
	
	float f = texture(sway_texture, sway_uv).r;
	f = (f - 0.5) * 2.0;
	f *= sway_factor;
	
	v += sway_direction * f * height;
	
	// transform into camera space
	VERTEX = (INV_CAMERA_MATRIX * vec4(v, 1.0)).xyz;
	NORMAL = (MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
}




void fragment() {
//	if (VERTEX.z < -30.0)
//	 discard;
	vec2 base_uv = UV;
	vec4 albedo_tex;
	if (-VERTEX.z > 14.0) 
		albedo_tex = texture(texture_albedo,base_uv);
	else
		albedo_tex = textureLod(texture_albedo, base_uv, 0);
	ALBEDO = mix(albedo_tex.rgb, albedo.rgb, 1.0 - albedo_tex.a);
	METALLIC = metallic;
	ROUGHNESS = roughness;
	SPECULAR = specular;
	ALPHA = albedo.a * albedo_tex.a;
	ALPHA_SCISSOR=alpha_scissor_threshold - min(pow(-VERTEX.z * 0.0002, 0.15), alpha_scissor_threshold);
	
	//EMISSION = vec3(1.0 - height) * ALBEDO * 0.5;
}

void light() {
	vec3 n = NORMAL;
	DIFFUSE_LIGHT += clamp(abs(dot(n, LIGHT)), 0.4, 1.0) * ATTENUATION * ALBEDO;
}