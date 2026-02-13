shader_type canvas_item;
render_mode unshaded;

uniform vec4 glow_color : source_color = vec4(0.48, 0.72, 1.0, 0.3);
uniform float radius : hint_range(0.05, 1.0) = 0.32;
uniform float softness : hint_range(0.2, 4.0) = 1.4;
uniform float pulse_strength : hint_range(0.0, 0.4) = 0.06;
uniform float t = 0.0;

void fragment() {
	vec2 p = UV - vec2(0.5);
	float d = length(p);
	float r = max(0.001, radius);
	float core = 1.0 - smoothstep(0.0, r, d);
	core = pow(max(core, 0.0), softness);
	float pulse = 1.0 + sin(t * 1.15) * pulse_strength;
	float a = glow_color.a * core * pulse;
	COLOR = vec4(glow_color.rgb, a);
}
