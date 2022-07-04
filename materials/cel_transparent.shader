/*
-------------------------------------
Godot 3.2 Cel Shader v2.0.0
Modified by Diane Sparks - Optimized out if statements and added further uniforms
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
render_mode ambient_light_disabled, shadows_disabled, depth_draw_alpha_prepass;

uniform vec4 base_color : hint_color = vec4(1.0);
uniform vec4 shade_color : hint_color = vec4(1.0);
uniform vec4 rim_tint : hint_color = vec4(0.75);

uniform float shade_threshold : hint_range(-1.0, 1.0, 0.001) = 0.0;
uniform float shade_softness : hint_range(0.0, 1.0, 0.001) = 0.01;

uniform bool use_shadow = false;
uniform float shadow_threshold : hint_range(0.00, 1.0, 0.001) = 0.7;
uniform float shadow_softness : hint_range(0.0, 1.0, 0.001) = 0.1;

uniform sampler2D base_texture: hint_albedo;
uniform sampler2D shade_texture: hint_albedo;

uniform vec4 emission_color : hint_color;
uniform sampler2D emission_map : hint_black_albedo;

uniform sampler2D shadow_texture : hint_albedo;
uniform float shadow_texture_scale = 1f;

void light() {
	float NdotL = dot(NORMAL, LIGHT);
	float is_lit = step(shade_threshold, NdotL);
	vec3 base = texture(base_texture, UV).rgb * base_color.rgb;
	vec3 shade = texture(shade_texture, UV).rgb * shade_color.rgb  * (texture(shadow_texture, vec2(UV.x + TIME * 0.025, UV.y) * shadow_texture_scale).rgb);
	vec3 diffuse = base;

	float shade_value = smoothstep(shade_threshold - shade_softness, shade_threshold + shade_softness, NdotL);
	diffuse = mix(shade, base, shade_value);
	
	float shadow_value = max(smoothstep(shadow_threshold - shadow_softness, shadow_threshold + shadow_softness, ATTENUATION.r), float(!use_shadow) * shade_value);
	shade_value = min(shade_value, shadow_value);
	diffuse = mix(shade, base, shade_value);
	is_lit = step(shadow_threshold, shade_value);
	
	vec3 result = diffuse * LIGHT_COLOR * ATTENUATION;
	DIFFUSE_LIGHT += result;
}

void fragment() {
	vec4 emission_tex = texture(emission_map, UV);
	vec4 base_tex = texture(base_texture, UV);
	EMISSION = emission_tex.rgb * emission_color.rgb * base_tex.rgb;
	ALPHA = base_tex.a;
}
