shader_type canvas_item;

uniform vec4 color_a : source_color;
uniform vec4 color_b : source_color;
uniform float t = 0.0;
uniform float drift = 1.0;

void fragment() {
	vec2 uv = UV;
	float wave = sin((uv.y + uv.x * 0.35 + t * 0.05) * 6.2831) * 0.06 * drift;
	float mixv = clamp(uv.y + wave, 0.0, 1.0);
	vec4 col = mix(color_a, color_b, mixv);
	COLOR = col;
}
