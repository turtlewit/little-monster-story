shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;
uniform vec4 albedo0 : hint_color;
uniform vec4 albedo1 : hint_color;
uniform vec4 albedo2 : hint_color;
uniform vec4 albedo3 : hint_color;
uniform sampler2D texture_mask : hint_albedo;
uniform float specular;
uniform float metallic;
uniform float roughness : hint_range(0,1);
uniform float point_size : hint_range(0,128);
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;


void vertex() {
	UV=UV*uv1_scale.xy+uv1_offset.xy;
}




void fragment() {
	vec2 base_uv = UV;
	vec4 mask = texture(texture_mask, base_uv);
	ALBEDO = mix(mix(mix(albedo0, albedo1, mask.r * mask.a), albedo2, mask.g * mask.a), albedo3, mask.b * mask.a).rgb;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	SPECULAR = specular;
}
