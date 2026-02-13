shader_type canvas_item;
render_mode unshaded;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float blur_radius = 2.0;
uniform vec4 tint_color : source_color = vec4(0.07, 0.12, 0.24, 0.68);
uniform float border = 0.08;
uniform float corner_radius = 0.11;
uniform vec4 edge_color : source_color = vec4(0.88, 0.95, 1.0, 0.42);
uniform float tint_mix : hint_range(0.0, 1.0) = 0.98;
uniform float saturation_boost : hint_range(0.8, 1.6) = 1.22;
uniform float bg_luma_mix : hint_range(0.0, 1.0) = 0.22;
uniform float specular_strength : hint_range(0.0, 1.0) = 0.34;
uniform float inner_shadow_strength : hint_range(0.0, 1.0) = 0.26;

float rounded_rect_sdf(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + vec2(r);
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 texel = SCREEN_PIXEL_SIZE * blur_radius;
	vec4 sum = vec4(0.0);
	sum += texture(SCREEN_TEXTURE, uv + vec2(-texel.x, 0.0));
	sum += texture(SCREEN_TEXTURE, uv + vec2(texel.x, 0.0));
	sum += texture(SCREEN_TEXTURE, uv + vec2(0.0, -texel.y));
	sum += texture(SCREEN_TEXTURE, uv + vec2(0.0, texel.y));
	sum += texture(SCREEN_TEXTURE, uv);
	vec4 blurred = sum / 5.0;
	vec2 p = UV - vec2(0.5);
	float radius = corner_radius;
	float sdf = rounded_rect_sdf(p, vec2(0.5 - border), radius);
	float inside = 1.0 - smoothstep(0.0, 0.006, sdf);
	// Edge highlight should only exist near the border, not across the full tile.
	float edge = (1.0 - smoothstep(0.0, 0.03, abs(sdf))) * inside;
	float inner_edge = smoothstep(-0.08, -0.01, sdf) * inside;

	// Keep tile hue anchored to logical tint color while still borrowing
	// some background luminance for a glass feel.
	float bg_luma = dot(blurred.rgb, vec3(0.2126, 0.7152, 0.0722));
	vec3 base_glass = mix(vec3(bg_luma), tint_color.rgb, 1.0 - bg_luma_mix);
	vec4 glass = vec4(mix(base_glass, tint_color.rgb, tint_mix), tint_color.a);
	float luma = dot(glass.rgb, vec3(0.2126, 0.7152, 0.0722));
	glass.rgb = mix(vec3(luma), glass.rgb, saturation_boost);
	glass.rgb = mix(glass.rgb, edge_color.rgb, edge * edge_color.a);
	float top_sheen = smoothstep(0.55, 0.08, UV.y) * inside;
	glass.rgb += vec3(0.24, 0.28, 0.34) * top_sheen * specular_strength;
	glass.rgb *= 1.0 - (inner_edge * inner_shadow_strength * 0.2);
	glass.a *= inside;
	COLOR = glass;
}
