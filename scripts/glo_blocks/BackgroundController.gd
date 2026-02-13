extends Node2D
class_name GloBackgroundController

@onready var bg_rect: ColorRect = $ColorRect
@onready var center_glow: ColorRect = $CenterGlow
@onready var particles: GPUParticles2D = $Particles
@onready var streak_particles: GPUParticles2D = $StreakParticles

var _t: float = 0.0
var _viewport_size: Vector2 = Vector2.ZERO
var _combo_intensity: float = 0.0
var _base_a: Color = Color(0.88, 0.92, 1.0, 1.0)
var _base_b: Color = Color(0.08, 0.1, 0.16, 1.0)
var _hype_a: Color = Color(0.58, 0.72, 1.0, 1.0)
var _hype_b: Color = Color(0.16, 0.12, 0.24, 1.0)

func _ready() -> void:
	var bg_material := ShaderMaterial.new()
	bg_material.shader = preload("res://shaders/GradientBackground.gdshader")
	bg_material.set_shader_parameter("color_a", _base_a)
	bg_material.set_shader_parameter("color_b", _base_b)
	bg_rect.material = bg_material
	bg_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_rect.position = Vector2.ZERO

	var glow_material := ShaderMaterial.new()
	glow_material.shader = preload("res://shaders/CenterGlow.gdshader")
	glow_material.set_shader_parameter("glow_color", Color(0.48, 0.74, 1.0, 0.2))
	center_glow.material = glow_material
	center_glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center_glow.position = Vector2.ZERO

	particles.texture = _build_soft_particle_texture(34, 1.6)
	streak_particles.texture = _build_streak_texture(56, 16)
	_configure_particle_materials()
	_sync_layout()

func _process(delta: float) -> void:
	_t += delta
	_sync_layout()
	if bg_rect.material:
		bg_rect.material.set_shader_parameter("t", _t)
	if center_glow.material:
		center_glow.material.set_shader_parameter("t", _t)
	_apply_combo_visuals()

func set_combo_intensity(amount: float) -> void:
	_combo_intensity = clamp(amount, 0.0, 1.0)

func _apply_combo_visuals() -> void:
	var pulse: float = (sin(_t * 2.0) + 1.0) * 0.5
	var combo_mix: float = clamp(_combo_intensity * (0.7 + (0.3 * pulse)), 0.0, 1.0)
	if bg_rect.material:
		bg_rect.material.set_shader_parameter("color_a", _base_a.lerp(_hype_a, combo_mix))
		bg_rect.material.set_shader_parameter("color_b", _base_b.lerp(_hype_b, combo_mix))
	if center_glow.material:
		var alpha: float = lerp(0.18, 0.34, combo_mix)
		center_glow.material.set_shader_parameter("glow_color", Color(0.5, 0.78, 1.0, alpha))
	particles.modulate = Color(0.38, 0.86, 1.0, lerp(0.36, 0.62, combo_mix))
	streak_particles.modulate = Color(0.78, 0.9, 1.0, lerp(0.32, 0.56, combo_mix))

func _configure_particle_materials() -> void:
	var point_material := particles.process_material as ParticleProcessMaterial
	if point_material:
		point_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
		point_material.direction = Vector3(1.0, 0.0, 0.0)
		point_material.spread = 180.0
		point_material.gravity = Vector3.ZERO
		point_material.initial_velocity_min = 180.0
		point_material.initial_velocity_max = 320.0
		point_material.linear_accel_min = 120.0
		point_material.linear_accel_max = 220.0
		point_material.scale_min = 0.14
		point_material.scale_max = 0.3
	var streak_material := streak_particles.process_material as ParticleProcessMaterial
	if streak_material:
		streak_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
		streak_material.direction = Vector3(1.0, 0.0, 0.0)
		streak_material.spread = 180.0
		streak_material.gravity = Vector3.ZERO
		streak_material.initial_velocity_min = 460.0
		streak_material.initial_velocity_max = 760.0
		streak_material.linear_accel_min = 240.0
		streak_material.linear_accel_max = 420.0
		streak_material.scale_min = 0.3
		streak_material.scale_max = 0.7

func _sync_layout() -> void:
	var next_size: Vector2 = get_viewport_rect().size
	if next_size == _viewport_size:
		return
	_viewport_size = next_size
	var center: Vector2 = _viewport_size * 0.5
	particles.position = center
	streak_particles.position = center

func _build_soft_particle_texture(size: int, softness: float) -> Texture2D:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size * 0.5, size * 0.5)
	var radius: float = size * 0.5
	for y in range(size):
		for x in range(size):
			var d: float = center.distance_to(Vector2(x, y)) / radius
			var a: float = clamp(1.0 - d, 0.0, 1.0)
			a = pow(a, softness)
			if d < 0.28:
				a = min(1.0, a + 0.35)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
	return ImageTexture.create_from_image(image)

func _build_streak_texture(width: int, height: int) -> Texture2D:
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	var center_y: float = float(height) * 0.5
	for y in range(height):
		for x in range(width):
			var ux: float = float(x) / max(1.0, float(width - 1))
			var uy: float = abs(float(y) - center_y) / max(1.0, center_y)
			var along: float = 1.0 - abs((ux * 2.0) - 1.0)
			var x_falloff: float = pow(max(0.0, along), 0.55)
			var y_falloff: float = pow(max(0.0, 1.0 - uy), 1.3)
			var a: float = x_falloff * y_falloff
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
	return ImageTexture.create_from_image(image)
