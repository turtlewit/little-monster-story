/*
-------------------------------------
Godot 3.2 Cel Shader v2.0.0
Modified by Diane Sparks
-------------------------------------
Copyright (c) 2017 David E Lipps

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
documentation files (the "Software"),to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,and/or sell copies of the Software, and
to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions
of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

shader_type spatial;
render_mode ambient_light_disabled, skip_vertex_transform;

uniform vec4 base_color : hint_color = vec4(1f);
uniform vec4 shade_color : hint_color = vec4(1f);
uniform float shade_threshold : hint_range(-1f, 1f) = 0f;
uniform float shade_softness : hint_range(0f, 1f) = 0.01;
uniform float shadow_threshold : hint_range(0f, 1f) = 0.7;
uniform float shadow_softness : hint_range(0f, 1f) = 0.01;
uniform sampler2D base_texture : hint_albedo;
uniform sampler2D shade_texture : hint_albedo;

uniform sampler2D emission_map : hint_black_albedo;
uniform vec4 emission_color : hint_color = vec4(0f);

uniform bool additive_color = false;
uniform float additive_intensity : hint_range(0f, 1f) = 0.005;

uniform vec2 uv_offset = vec2(0f);
uniform float uv_rotation = 0f;
uniform float uv_rotation_mid : hint_range(0f, 1f) = 0.5f;
uniform vec2 uv_scale = vec2(1f);

uniform float sway_factor : hint_range(0.0, 1.0) = 0.05;
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
	
//	v += sway_direction * f * pow(clamp(length(VERTEX.xz), 0.5, 1.0), 2.0);
	v += sway_direction * f;
	
	// transform into camera space
	VERTEX = (INV_CAMERA_MATRIX * vec4(v, 1.0)).xyz;
	NORMAL = (MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
}

vec2 rotate_uv(vec2 uv, float rotation, float mid) {
    return vec2(
      cos(rotation) * (uv.x - mid) + sin(rotation) * (uv.y - mid) + mid,
      cos(rotation) * (uv.y - mid) - sin(rotation) * (uv.x - mid) + mid
    );
}

vec2 final_uv(vec2 uv) {
	return rotate_uv(uv, uv_rotation, uv_rotation_mid) * uv_scale + uv_offset;
}


vec3 to_grayscale(vec3 from) {
	float y = 0.2126 * from.r + 0.7152 * from.g + 0.0722 * from.b;
	return vec3(y, y, y);
}


void fragment() {
	vec4 emission_tex = texture(emission_map, final_uv(UV));
	vec4 base_tex = texture(base_texture, final_uv(UV));
	EMISSION = emission_tex.rgb * emission_color.rgb * base_tex.rgb;
}


void light() {
	float NdotL = dot(NORMAL, LIGHT);
	float is_lit = step(shade_threshold, NdotL);
	vec3 base = texture(base_texture, final_uv(UV)).rgb;
	vec3 shade = texture(shade_texture, final_uv(UV)).rgb;
	
	
	vec3 ambient_color = to_grayscale(texture(shade_texture, final_uv(UV)).rgb) * shade_color.rgb;
	
	// Additive color
	base += (base_color.rgb * additive_intensity) * float(additive_color);
	shade += (shade_color.rgb * additive_intensity) * float(additive_color);
	
	// Multiplicative color
	base *= max(vec3(float(additive_color)), base_color.rgb);
	shade *= max(vec3(float(additive_color)), shade_color.rgb);
	
	float shade_value = smoothstep(shade_threshold - shade_softness, shade_threshold + shade_softness, NdotL);	
	vec3 shadow_value = smoothstep(shadow_threshold - shadow_softness, shadow_threshold + shadow_softness,  ATTENUATION);
	
	shade_value = min(shade_value, shadow_value.x);
	//vec3 diffuse = mix(shade, base, shade_value);
	//DIFFUSE_LIGHT = max(mix(diffuse * LIGHT_COLOR * shadow_value, ambient_color, round(1.0 - shadow_value)), DIFFUSE_LIGHT);
	if (length(shadow_value) < 1.0 || step(0.0, NdotL) < 0.1) {
		if (length(DIFFUSE_LIGHT) < 0.001) {
			DIFFUSE_LIGHT += ambient_color;
		}
	} else {
		DIFFUSE_LIGHT += base * LIGHT_COLOR * step(0.0, NdotL);
	}
}
