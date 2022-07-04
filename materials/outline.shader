shader_type spatial;
render_mode unshaded, cull_front;

uniform float grow = 1.0;
uniform vec4 color : hint_color = vec4(1.0);

void vertex()
{
	VERTEX = VERTEX + (NORMAL * grow);
}

void fragment()
{
	ALBEDO = color.rgb;
}