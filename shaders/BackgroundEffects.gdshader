shader_type canvas_item;

uniform int effect_mode = 0;
uniform float t = 0.0;
uniform float combo = 0.0;
uniform float overlay_alpha = 1.0;
uniform vec2 resolution = vec2(1170.0, 2532.0);

uniform vec4 color_a : source_color = vec4(0.88, 0.92, 1.0, 1.0);
uniform vec4 color_b : source_color = vec4(0.08, 0.10, 0.16, 1.0);
uniform vec4 color_c : source_color = vec4(0.42, 0.78, 1.0, 1.0);
uniform vec4 color_d : source_color = vec4(0.72, 0.90, 1.0, 1.0);
uniform vec4 mode_tint : source_color = vec4(1.0, 1.0, 1.0, 0.0);

float hash11(float p) {
	p = fract(p * 0.1031);
	p *= p + 33.33;
	p *= p + p;
	return fract(p);
}

float hash21(vec2 p) {
	vec3 p3 = fract(vec3(p.x, p.y, p.x) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p) {
	vec3 p3 = fract(vec3(p.x, p.y, p.x) * vec3(0.1031, 0.1030, 0.0973));
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.xx + p3.yz) * p3.zy);
}

float noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - (2.0 * f));
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 5; i++) {
		value += noise2(p) * amp;
		p = (p * 2.03) + vec2(17.13, 9.47);
		amp *= 0.5;
	}
	return value;
}

vec3 saturate_color(vec3 col, float amount) {
	float lum = dot(col, vec3(0.299, 0.587, 0.114));
	return mix(vec3(lum), col, amount);
}

vec2 centered_uv(vec2 uv) {
	float aspect = resolution.x / max(resolution.y, 1.0);
	return vec2((uv.x - 0.5) * aspect, uv.y - 0.5);
}

vec3 effect_aurora(vec2 uv) {
	vec2 p = uv * vec2(1.6, 2.4);
	float n = fbm(p + vec2(0.0, t * 0.08));
	float band = sin((uv.y * 5.6 + n * 2.8 + t * 0.32 + uv.x * 1.9) * 3.14159);
	band = (band * 0.5) + 0.5;
	float glow = smoothstep(0.35, 1.0, band) * (0.6 + (1.0 - uv.y) * 0.4);
	vec3 col = mix(color_b.rgb, color_a.rgb, clamp(uv.y + n * 0.2, 0.0, 1.0));
	col += color_c.rgb * glow * 0.45;
	col += color_d.rgb * pow(max(0.0, band - 0.72), 2.0) * 0.75;
	return col;
}

vec3 effect_soft_shapes(vec2 uv) {
	float aspect = resolution.x / max(resolution.y, 1.0);
	vec3 col = mix(color_b.rgb * 0.82, color_a.rgb * 0.65, uv.y * 0.55 + 0.2);
	for (int i = 0; i < 6; i++) {
		float fi = float(i);
		float speed = 0.025 + 0.025 * hash11(fi * 5.13 + 2.0);
		vec2 seed = vec2(hash11(fi * 13.27 + 1.0), hash11(fi * 7.91 + 3.0));
		vec2 center = fract(seed + vec2(t * speed * (0.65 + hash11(fi * 2.3)), t * speed * (0.35 + hash11(fi * 4.7))));
		center.x += sin(t * 0.22 + fi * 2.1) * 0.1;
		center.y += cos(t * 0.18 + fi * 1.7) * 0.05;
		vec2 d = uv - center;
		d.x *= aspect;
		float radius = 0.15 + 0.12 * hash11(fi * 3.41 + 8.0);
		float blob = 1.0 - smoothstep(radius * 0.5, radius, length(d));
		vec3 tint = mix(color_c.rgb, color_d.rgb, hash11(fi * 11.73 + 0.4));
		col += tint * blob * 0.38;
	}
	return col;
}

vec3 effect_grid_pulse(vec2 uv) {
	vec2 grid = uv * vec2(12.0, 20.0);
	vec2 f = abs(fract(grid) - 0.5);
	float lines = 1.0 - smoothstep(0.34, 0.5, max(f.x, f.y));
	float radial = length(centered_uv(uv));
	float pulse = 0.5 + 0.5 * sin(radial * 34.0 - t * 4.5);
	float wave = smoothstep(0.2, 1.0, pulse);
	vec3 col = mix(color_b.rgb * 0.8, color_a.rgb * 0.9, uv.y);
	col += color_c.rgb * lines * (0.28 + wave * 0.9);
	col += color_d.rgb * pow(lines, 2.0) * 0.38;
	return col;
}

vec3 effect_flow_particles(vec2 uv) {
	vec3 col = mix(color_b.rgb * 0.85, color_a.rgb * 0.58, uv.y * 0.65);
	vec2 grid_uv = uv * vec2(38.0, 64.0);
	vec2 base_cell = floor(grid_uv);
	vec2 cell_uv = fract(grid_uv);
	float dots = 0.0;
	for (int yi = 0; yi < 3; yi++) {
		for (int xi = 0; xi < 3; xi++) {
			vec2 offset = vec2(float(xi - 1), float(yi - 1));
			vec2 cell = base_cell + offset;
			vec2 rnd = hash22(cell);
			float ang = noise2(cell * 0.19 + vec2(t * 0.2, -t * 0.15)) * 6.28318;
			vec2 pos = fract(rnd + vec2(cos(ang), sin(ang)) * 0.33 + vec2(t * 0.12, -t * 0.08));
			vec2 delta = (offset + pos) - cell_uv;
			float d = length(delta);
			float twinkle = 0.55 + 0.45 * sin(t * 2.4 + rnd.x * 8.0);
			dots += (1.0 - smoothstep(0.0, 0.24, d)) * twinkle;
		}
	}
	dots = clamp(dots * 0.38, 0.0, 1.0);
	col += color_c.rgb * dots * 0.96;
	col += color_d.rgb * pow(dots, 2.0) * 0.35;
	col += vec3(1.0) * pow(dots, 3.0) * 0.32;
	return col;
}

vec3 effect_rays_dust(vec2 uv) {
	vec3 col = mix(color_b.rgb * 0.7, color_a.rgb * 0.75, uv.y);
	vec2 p = uv - vec2(0.5, -0.08);
	float ang = atan(p.x, p.y);
	float radial_noise = noise2(vec2(ang * 4.0, t * 0.08));
	float rays = sin(ang * 17.0 + radial_noise * 5.0 + t * 0.65);
	rays = pow(rays * 0.5 + 0.5, 3.2);
	float falloff = pow(clamp(1.0 - uv.y, 0.0, 1.0), 1.7);
	float beam = rays * falloff;
	vec2 dust_uv = uv * resolution * 0.17 + vec2(t * 8.0, -t * 5.0);
	float dust = smoothstep(0.986, 1.0, hash21(floor(dust_uv)));
	col += color_c.rgb * beam * 0.88;
	col += color_d.rgb * beam * 0.24;
	col += vec3(1.0) * dust * (0.16 + falloff * 0.3);
	return col;
}

vec3 effect_caustics(vec2 uv) {
	vec3 base = mix(color_b.rgb * 0.82, color_a.rgb * 0.86, uv.y * 0.6 + 0.2);
	vec2 q = uv * 5.2;
	float accum = 0.0;
	for (int i = 0; i < 4; i++) {
		float fi = float(i);
		q += vec2(sin(q.y * 1.25 + t * 0.95 + fi * 1.2), cos(q.x * 1.05 - t * 0.85 + fi * 1.6)) * 0.34;
		accum += abs(sin(q.x) + cos(q.y));
	}
	float caustic = pow(clamp((accum / 4.0) * 0.48, 0.0, 1.0), 2.0);
	vec3 col = base + color_c.rgb * caustic * 0.96;
	col += color_d.rgb * pow(caustic, 2.0) * 0.44;
	return col;
}

vec3 crt_gradient(vec2 uv) {
	float g = clamp(uv.y + sin((uv.x * 1.2 + t * 0.12) * 6.28318) * 0.03, 0.0, 1.0);
	return mix(color_a.rgb, color_b.rgb, g);
}

vec3 effect_crt(vec2 uv) {
	vec2 p = uv * 2.0 - 1.0;
	p *= 1.0 + dot(p, p) * 0.075;
	vec2 cuv = clamp(p * 0.5 + 0.5, 0.0, 1.0);
	float drift = sin(t * 1.3 + cuv.y * 28.0) * 0.008;
	float line_jitter = (hash21(vec2(floor(cuv.y * resolution.y * 0.5), floor(t * 60.0))) - 0.5) * 0.006;
	cuv.x = clamp(cuv.x + line_jitter, 0.0, 1.0);
	vec3 cr = crt_gradient(cuv + vec2(drift, 0.0));
	vec3 cg = crt_gradient(cuv);
	vec3 cb = crt_gradient(cuv - vec2(drift, 0.0));
	vec3 col = vec3(cr.r, cg.g, cb.b);
	float scan_a = sin(cuv.y * resolution.y * 1.8) * 0.12;
	float scan_b = sin(cuv.y * resolution.y * 0.6 + t * 7.0) * 0.05;
	col *= 0.9 + scan_a + scan_b;
	float mask_phase = fract(cuv.x * resolution.x * 0.5);
	vec3 mask = vec3(
		smoothstep(0.0, 0.34, 1.0 - abs(mask_phase - 0.16)),
		smoothstep(0.0, 0.34, 1.0 - abs(mask_phase - 0.50)),
		smoothstep(0.0, 0.34, 1.0 - abs(mask_phase - 0.84))
	);
	col *= mix(vec3(0.82), mask * 1.28, 0.24);
	float static_noise = hash21(floor(cuv * resolution * 0.42) + vec2(floor(t * 48.0), floor(t * 31.0)));
	col += (static_noise - 0.5) * 0.1;
	float vignette = 1.0 - smoothstep(0.55, 1.02, length(p));
	col *= vignette;
	col += color_c.rgb * 0.08 * sin(t * 3.0 + cuv.y * 120.0);
	col *= vec3(0.58, 1.12, 0.44);
	return col;
}

vec3 effect_starfield(vec2 uv) {
	vec3 col = mix(color_b.rgb * 0.92, color_a.rgb * 0.28, uv.y * 0.25);
	for (int i = 0; i < 3; i++) {
		float layer = float(i) + 1.0;
		float scale = mix(38.0, 120.0, layer / 3.0);
		vec2 suv = uv * scale + vec2(t * (0.24 + layer * 0.28), t * (0.08 + layer * 0.11));
		vec2 cell = floor(suv);
		vec2 f = fract(suv);
		vec2 star = hash22(cell);
		float d = length(f - star);
		float size = 0.03 / layer;
		float spark = 1.0 - smoothstep(size, size * 2.5, d);
		float twinkle = 0.5 + 0.5 * sin(t * (2.0 + layer) + hash21(cell) * 9.0);
		float strength = spark * twinkle * (1.1 / layer);
		vec3 tone = mix(vec3(0.8, 0.9, 1.0), vec3(1.0), hash21(cell + vec2(17.0, 31.0)));
		col += tone * strength * 0.9;
		float streak_seed = hash21(cell + floor(vec2(t * 0.7, t * 0.3)));
		float streak = smoothstep(0.998, 1.0, streak_seed);
		streak *= 1.0 - smoothstep(0.0, 0.06, abs(f.y - 0.5));
		streak *= smoothstep(0.2, 1.0, f.x);
		col += vec3(0.9, 0.95, 1.0) * streak * (0.35 / layer);
	}
	return col;
}

vec3 effect_paper(vec2 uv) {
	vec2 p = uv * resolution * 0.0038;
	float grain = fbm(p * 3.2);
	float fibers = noise2(p * 14.0 + vec2(2.3, 7.1));
	float hatch = 0.5 + 0.5 * sin((uv.x + uv.y) * resolution.y * 0.018 + fibers * 4.0);
	vec3 paper = mix(color_b.rgb, color_a.rgb, grain);
	vec2 light_center = vec2(0.25 + sin(t * 0.12) * 0.1, 0.55 + cos(t * 0.08) * 0.06);
	vec2 delta = uv - light_center;
	delta.x *= resolution.x / max(resolution.y, 1.0);
	float light = 1.0 - smoothstep(0.18, 1.0, length(delta));
	vec3 col = paper + color_c.rgb * light * 0.3;
	col += color_d.rgb * (hatch - 0.5) * 0.12;
	col += color_d.rgb * (fibers - 0.5) * 0.14;
	return col;
}

vec3 effect_reactive(vec2 uv) {
	vec3 col = effect_aurora(uv);
	float r = length(centered_uv(uv));
	float ripple = sin(r * 70.0 - t * 9.5) * exp(-r * 4.8);
	float flare = (0.5 + 0.5 * sin(t * 7.5)) * combo;
	col += color_d.rgb * ripple * combo * 0.9;
	col += color_c.rgb * flare * 0.35;
	col = mix(col, col + color_a.rgb * 0.2, combo * 0.4);
	return col;
}

void fragment() {
	vec2 uv = UV;
	vec3 col = effect_aurora(uv);
	if (effect_mode == 1) {
		col = effect_soft_shapes(uv);
	} else if (effect_mode == 2) {
		col = effect_grid_pulse(uv);
	} else if (effect_mode == 3) {
		col = effect_flow_particles(uv);
	} else if (effect_mode == 4) {
		col = effect_rays_dust(uv);
	} else if (effect_mode == 5) {
		col = effect_caustics(uv);
	} else if (effect_mode == 6) {
		col = effect_crt(uv);
	} else if (effect_mode == 7) {
		col = effect_starfield(uv);
	} else if (effect_mode == 8) {
		col = effect_paper(uv);
	} else if (effect_mode == 9) {
		col = effect_reactive(uv);
	}
	float sat = 1.18;
	if (effect_mode == 6) {
		sat = 1.05;
	} else if (effect_mode == 8) {
		sat = 0.88;
	}
	col = saturate_color(col, sat);
	col = mix(col, col * mode_tint.rgb, clamp(mode_tint.a, 0.0, 1.0));
	float boost = 1.08 + combo * 0.16;
	col *= boost;
	col = pow(max(col, vec3(0.0)), vec3(0.95));
	COLOR = vec4(clamp(col, vec3(0.0), vec3(1.0)), clamp(overlay_alpha, 0.0, 1.0));
}
