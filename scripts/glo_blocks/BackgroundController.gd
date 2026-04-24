extends Node2D
class_name GloBackgroundController

const BACKGROUND_SHADER := preload("res://shaders/BackgroundEffects.gdshader")
const GLOW_SHADER := preload("res://shaders/CenterGlow.gdshader")
const EFFECT_NAMES := [
	"Gradient Aurora",
	"Parallax Soft Shapes",
	"Grid Pulse",
	"Flow Field Particles",
	"Light Rays + Dust",
	"Liquid Caustics",
	"Retro CRT",
	"Starfield Drift",
	"Paper Texture Lighting",
	"Gameplay Reactive"
]

enum BaseBackgroundMode {
	COLOR,
	IMAGE
}

@export_range(0, 9, 1) var initial_effect_index: int = 0
@export var debug_effect_hotkeys_enabled: bool = true
@export var debug_overlay_enabled: bool = true
@export_range(0.0, 30.0, 0.1) var debug_auto_cycle_seconds: float = 0.0
@export var base_background_mode: BaseBackgroundMode = BaseBackgroundMode.COLOR
@export var base_background_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var effect_controls_base_color: bool = false
@export var base_background_image: Texture2D
@export_range(0.0, 1.0, 0.01) var fx_overlay_alpha: float = 1.0

@onready var base_layer: TextureRect = $BaseLayer
@onready var bg_rect: ColorRect = $ColorRect
@onready var center_glow: ColorRect = $CenterGlow
@onready var particles: GPUParticles2D = $Particles
@onready var streak_particles: GPUParticles2D = $StreakParticles

var _t: float = 0.0
var _viewport_size: Vector2 = Vector2.ZERO
var _combo_intensity: float = 0.0
var _effect_index: int = 0
var _auto_cycle_elapsed: float = 0.0
var _base_a: Color = Color(0.88, 0.92, 1.0, 1.0)
var _base_b: Color = Color(0.08, 0.1, 0.16, 1.0)
var _base_c: Color = Color(0.42, 0.78, 1.0, 1.0)
var _base_d: Color = Color(0.72, 0.9, 1.0, 1.0)
var _hype_a: Color = Color(0.58, 0.72, 1.0, 1.0)
var _hype_b: Color = Color(0.16, 0.12, 0.24, 1.0)
var _hype_c: Color = Color(0.68, 0.86, 1.0, 1.0)
var _hype_d: Color = Color(0.92, 0.97, 1.0, 1.0)
var _effect_overlay_alpha: float = 1.0
var _effect_time_scale: float = 1.0
var _effect_glow_base: Color = Color(0.5, 0.78, 1.0, 0.18)
var _effect_glow_hype: Color = Color(0.62, 0.88, 1.0, 0.34)
var _particles_base: Color = Color(0.38, 0.86, 1.0, 0.36)
var _particles_hype: Color = Color(0.64, 0.94, 1.0, 0.62)
var _streaks_base: Color = Color(0.78, 0.9, 1.0, 0.32)
var _streaks_hype: Color = Color(0.92, 0.97, 1.0, 0.56)
var _effect_tint_base: Color = Color(1.0, 1.0, 1.0, 0.0)
var _effect_tint_hype: Color = Color(1.0, 1.0, 1.0, 0.0)
var _solid_texture: Texture2D
var _debug_layer: CanvasLayer
var _debug_label: Label

func _ready() -> void:
	var bg_material := ShaderMaterial.new()
	bg_material.shader = BACKGROUND_SHADER
	bg_material.set_shader_parameter("color_a", _base_a)
	bg_material.set_shader_parameter("color_b", _base_b)
	bg_material.set_shader_parameter("color_c", _base_c)
	bg_material.set_shader_parameter("color_d", _base_d)
	bg_material.set_shader_parameter("mode_tint", _effect_tint_base)
	bg_material.set_shader_parameter("overlay_alpha", fx_overlay_alpha)
	bg_rect.material = bg_material
	bg_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_rect.position = Vector2.ZERO

	var glow_material := ShaderMaterial.new()
	glow_material.shader = GLOW_SHADER
	glow_material.set_shader_parameter("glow_color", Color(0.48, 0.74, 1.0, 0.2))
	center_glow.material = glow_material
	center_glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center_glow.position = Vector2.ZERO

	particles.texture = _build_soft_particle_texture(34, 1.6)
	streak_particles.texture = _build_streak_texture(56, 16)
	_configure_particle_materials()
	_apply_base_background()
	_effect_index = clampi(initial_effect_index, 0, EFFECT_NAMES.size() - 1)
	_apply_effect_mode()
	_ensure_debug_overlay()
	set_process_unhandled_input(debug_effect_hotkeys_enabled)
	_sync_layout()

func _process(delta: float) -> void:
	_t += delta
	_update_auto_cycle(delta)
	_sync_layout()
	if bg_rect.material:
		bg_rect.material.set_shader_parameter("t", _t * _effect_time_scale)
	if center_glow.material:
		center_glow.material.set_shader_parameter("t", _t)
	_apply_combo_visuals()

func _unhandled_input(event: InputEvent) -> void:
	if not debug_effect_hotkeys_enabled:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_BRACKETLEFT, KEY_COMMA, KEY_MINUS, KEY_KP_SUBTRACT:
				previous_effect()
			KEY_BRACKETRIGHT, KEY_PERIOD, KEY_EQUAL, KEY_KP_ADD, KEY_TAB:
				next_effect()
			KEY_1:
				set_effect_index(0)
			KEY_2:
				set_effect_index(1)
			KEY_3:
				set_effect_index(2)
			KEY_4:
				set_effect_index(3)
			KEY_5:
				set_effect_index(4)
			KEY_6:
				set_effect_index(5)
			KEY_7:
				set_effect_index(6)
			KEY_8:
				set_effect_index(7)
			KEY_9:
				set_effect_index(8)
			KEY_0:
				set_effect_index(9)

func set_combo_intensity(amount: float) -> void:
	_combo_intensity = clamp(amount, 0.0, 1.0)

func set_effect_index(index: int) -> void:
	var count: int = EFFECT_NAMES.size()
	if count <= 0:
		return
	_effect_index = wrapi(index, 0, count)
	_auto_cycle_elapsed = 0.0
	_apply_effect_mode()

func next_effect() -> void:
	set_effect_index(_effect_index + 1)

func previous_effect() -> void:
	set_effect_index(_effect_index - 1)

func get_effect_name() -> String:
	if _effect_index >= 0 and _effect_index < EFFECT_NAMES.size():
		return EFFECT_NAMES[_effect_index]
	return "Unknown"

func get_effect_index() -> int:
	return _effect_index

func _apply_combo_visuals() -> void:
	var pulse: float = (sin(_t * 2.0) + 1.0) * 0.5
	var combo_mix: float = clamp(_combo_intensity * (0.7 + (0.3 * pulse)), 0.0, 1.0)
	if bg_rect.material:
		bg_rect.material.set_shader_parameter("color_a", _base_a.lerp(_hype_a, combo_mix))
		bg_rect.material.set_shader_parameter("color_b", _base_b.lerp(_hype_b, combo_mix))
		bg_rect.material.set_shader_parameter("color_c", _base_c.lerp(_hype_c, combo_mix))
		bg_rect.material.set_shader_parameter("color_d", _base_d.lerp(_hype_d, combo_mix))
		bg_rect.material.set_shader_parameter("mode_tint", _effect_tint_base.lerp(_effect_tint_hype, combo_mix))
		bg_rect.material.set_shader_parameter("combo", combo_mix)
		var overlay_base: float = clamp(_effect_overlay_alpha * fx_overlay_alpha, 0.0, 1.0)
		bg_rect.material.set_shader_parameter("overlay_alpha", clamp(max(0.92, overlay_base) + (combo_mix * 0.08), 0.0, 1.0))
	if center_glow.material:
		center_glow.material.set_shader_parameter("glow_color", _effect_glow_base.lerp(_effect_glow_hype, combo_mix))
	particles.modulate = _particles_base.lerp(_particles_hype, combo_mix)
	streak_particles.modulate = _streaks_base.lerp(_streaks_hype, combo_mix)

func _update_auto_cycle(delta: float) -> void:
	if debug_auto_cycle_seconds <= 0.0:
		return
	_auto_cycle_elapsed += delta
	if _auto_cycle_elapsed < debug_auto_cycle_seconds:
		return
	_auto_cycle_elapsed = 0.0
	next_effect()

func _apply_effect_mode() -> void:
	if bg_rect.material:
		bg_rect.material.set_shader_parameter("effect_mode", _effect_index)
	_apply_effect_profile()
	_configure_effect_overlays()
	_apply_combo_visuals()
	_update_debug_label()

func _apply_effect_profile() -> void:
	var profile: Dictionary = _effect_profile_for(_effect_index)
	_base_a = profile.get("base_a", _base_a)
	_base_b = profile.get("base_b", _base_b)
	_base_c = profile.get("base_c", _base_c)
	_base_d = profile.get("base_d", _base_d)
	_hype_a = profile.get("hype_a", _hype_a)
	_hype_b = profile.get("hype_b", _hype_b)
	_hype_c = profile.get("hype_c", _hype_c)
	_hype_d = profile.get("hype_d", _hype_d)
	_effect_overlay_alpha = float(profile.get("overlay_alpha", _effect_overlay_alpha))
	_effect_time_scale = float(profile.get("time_scale", _effect_time_scale))
	_effect_glow_base = profile.get("glow_base", _effect_glow_base)
	_effect_glow_hype = profile.get("glow_hype", _effect_glow_hype)
	_particles_base = profile.get("particles_base", _particles_base)
	_particles_hype = profile.get("particles_hype", _particles_hype)
	_streaks_base = profile.get("streaks_base", _streaks_base)
	_streaks_hype = profile.get("streaks_hype", _streaks_hype)
	var tint_profile: Dictionary = _effect_tint_for(_effect_index)
	_effect_tint_base = tint_profile.get("base", _effect_tint_base)
	_effect_tint_hype = tint_profile.get("hype", _effect_tint_hype)
	_effect_tint_base = profile.get("tint_base", _effect_tint_base)
	_effect_tint_hype = profile.get("tint_hype", _effect_tint_hype)
	if base_background_mode == BaseBackgroundMode.COLOR:
		if effect_controls_base_color:
			base_layer.modulate = profile.get("bg_color", base_background_color)
		else:
			base_layer.modulate = base_background_color

func _effect_tint_for(index: int) -> Dictionary:
	match index:
		0:
			return {"base": Color(0.86, 0.97, 1.0, 0.12), "hype": Color(0.9, 1.0, 1.0, 0.24)}
		1:
			return {"base": Color(1.0, 0.74, 0.92, 0.22), "hype": Color(0.98, 0.92, 0.68, 0.34)}
		2:
			return {"base": Color(0.64, 0.88, 1.0, 0.2), "hype": Color(0.76, 0.96, 1.0, 0.3)}
		3:
			return {"base": Color(0.66, 1.0, 0.9, 0.22), "hype": Color(0.8, 1.0, 0.94, 0.34)}
		4:
			return {"base": Color(1.0, 0.8, 0.52, 0.24), "hype": Color(1.0, 0.9, 0.7, 0.34)}
		5:
			return {"base": Color(0.64, 0.96, 1.0, 0.26), "hype": Color(0.8, 1.0, 1.0, 0.36)}
		6:
			return {"base": Color(0.66, 1.0, 0.58, 0.28), "hype": Color(0.8, 1.0, 0.7, 0.38)}
		7:
			return {"base": Color(0.8, 0.88, 1.0, 0.14), "hype": Color(0.94, 0.98, 1.0, 0.24)}
		8:
			return {"base": Color(1.0, 0.9, 0.74, 0.28), "hype": Color(1.0, 0.96, 0.84, 0.38)}
		9:
			return {"base": Color(0.84, 0.72, 1.0, 0.24), "hype": Color(1.0, 0.84, 0.98, 0.38)}
		_:
			return {"base": Color(1.0, 1.0, 1.0, 0.0), "hype": Color(1.0, 1.0, 1.0, 0.0)}

func _effect_profile_for(index: int) -> Dictionary:
	match index:
		0:
			return {
				"base_a": Color(0.72, 0.86, 1.0, 1.0),
				"base_b": Color(0.02, 0.06, 0.14, 1.0),
				"base_c": Color(0.08, 0.96, 1.0, 1.0),
				"base_d": Color(0.88, 0.96, 1.0, 1.0),
				"hype_a": Color(0.82, 0.92, 1.0, 1.0),
				"hype_b": Color(0.04, 0.09, 0.2, 1.0),
				"hype_c": Color(0.3, 0.98, 1.0, 1.0),
				"hype_d": Color(0.98, 1.0, 1.0, 1.0),
				"overlay_alpha": 1.0,
				"time_scale": 1.0,
				"bg_color": Color(0.02, 0.05, 0.1, 1.0),
				"glow_base": Color(0.46, 0.82, 1.0, 0.18),
				"glow_hype": Color(0.66, 0.92, 1.0, 0.36),
				"particles_base": Color(0.36, 0.86, 1.0, 0.38),
				"particles_hype": Color(0.62, 0.95, 1.0, 0.66)
			}
		1:
			return {
				"base_a": Color(0.94, 0.5, 0.96, 1.0),
				"base_b": Color(0.09, 0.03, 0.18, 1.0),
				"base_c": Color(0.12, 0.98, 0.88, 1.0),
				"base_d": Color(1.0, 0.78, 0.36, 1.0),
				"hype_a": Color(1.0, 0.72, 0.95, 1.0),
				"hype_b": Color(0.14, 0.06, 0.2, 1.0),
				"hype_c": Color(0.68, 0.98, 0.94, 1.0),
				"hype_d": Color(1.0, 0.9, 0.62, 1.0),
				"overlay_alpha": 0.96,
				"time_scale": 1.4,
				"bg_color": Color(0.07, 0.03, 0.14, 1.0),
				"particles_base": Color(1.0, 0.7, 0.96, 0.36),
				"particles_hype": Color(0.86, 1.0, 0.92, 0.6)
			}
		2:
			return {
				"base_a": Color(0.18, 0.36, 0.98, 1.0),
				"base_b": Color(0.0, 0.02, 0.08, 1.0),
				"base_c": Color(0.0, 0.94, 1.0, 1.0),
				"base_d": Color(0.78, 0.94, 1.0, 1.0),
				"hype_a": Color(0.3, 0.54, 1.0, 1.0),
				"hype_b": Color(0.02, 0.04, 0.14, 1.0),
				"hype_c": Color(0.32, 0.98, 1.0, 1.0),
				"hype_d": Color(0.84, 0.94, 1.0, 1.0),
				"overlay_alpha": 1.0,
				"time_scale": 1.3,
				"bg_color": Color(0.0, 0.02, 0.09, 1.0),
				"glow_base": Color(0.22, 0.74, 1.0, 0.2),
				"glow_hype": Color(0.46, 0.88, 1.0, 0.36)
			}
		3:
			return {
				"base_a": Color(0.24, 0.98, 0.86, 1.0),
				"base_b": Color(0.0, 0.07, 0.12, 1.0),
				"base_c": Color(0.58, 1.0, 0.92, 1.0),
				"base_d": Color(0.88, 0.98, 1.0, 1.0),
				"hype_a": Color(0.52, 0.96, 0.9, 1.0),
				"hype_b": Color(0.03, 0.12, 0.16, 1.0),
				"hype_c": Color(0.78, 1.0, 0.96, 1.0),
				"hype_d": Color(0.96, 1.0, 1.0, 1.0),
				"overlay_alpha": 1.0,
				"time_scale": 1.8,
				"bg_color": Color(0.01, 0.08, 0.12, 1.0),
				"particles_base": Color(0.58, 1.0, 0.9, 0.46),
				"particles_hype": Color(0.84, 1.0, 0.96, 0.72)
			}
		4:
			return {
				"base_a": Color(1.0, 0.78, 0.34, 1.0),
				"base_b": Color(0.15, 0.07, 0.01, 1.0),
				"base_c": Color(1.0, 0.94, 0.66, 1.0),
				"base_d": Color(1.0, 0.46, 0.15, 1.0),
				"hype_a": Color(1.0, 0.84, 0.52, 1.0),
				"hype_b": Color(0.17, 0.08, 0.03, 1.0),
				"hype_c": Color(1.0, 0.96, 0.76, 1.0),
				"hype_d": Color(1.0, 0.68, 0.32, 1.0),
				"overlay_alpha": 0.95,
				"time_scale": 1.15,
				"bg_color": Color(0.12, 0.07, 0.03, 1.0),
				"glow_base": Color(1.0, 0.78, 0.5, 0.2),
				"glow_hype": Color(1.0, 0.9, 0.65, 0.38),
				"streaks_base": Color(1.0, 0.84, 0.65, 0.42),
				"streaks_hype": Color(1.0, 0.94, 0.8, 0.68)
			}
		5:
			return {
				"base_a": Color(0.3, 0.98, 1.0, 1.0),
				"base_b": Color(0.01, 0.16, 0.28, 1.0),
				"base_c": Color(0.0, 0.9, 1.0, 1.0),
				"base_d": Color(0.78, 1.0, 0.96, 1.0),
				"hype_a": Color(0.58, 0.98, 1.0, 1.0),
				"hype_b": Color(0.04, 0.24, 0.34, 1.0),
				"hype_c": Color(0.36, 0.96, 1.0, 1.0),
				"hype_d": Color(0.9, 1.0, 0.98, 1.0),
				"overlay_alpha": 1.0,
				"time_scale": 1.65,
				"bg_color": Color(0.01, 0.12, 0.2, 1.0),
				"glow_base": Color(0.54, 0.94, 1.0, 0.22),
				"glow_hype": Color(0.76, 0.98, 1.0, 0.4)
			}
		6:
			return {
				"base_a": Color(0.34, 1.0, 0.22, 1.0),
				"base_b": Color(0.0, 0.03, 0.0, 1.0),
				"base_c": Color(0.22, 0.96, 0.18, 1.0),
				"base_d": Color(0.78, 1.0, 0.58, 1.0),
				"hype_a": Color(0.52, 1.0, 0.36, 1.0),
				"hype_b": Color(0.0, 0.06, 0.0, 1.0),
				"hype_c": Color(0.46, 1.0, 0.34, 1.0),
				"hype_d": Color(0.9, 1.0, 0.76, 1.0),
				"overlay_alpha": 1.0,
				"time_scale": 1.05,
				"bg_color": Color(0.0, 0.03, 0.0, 1.0),
				"glow_base": Color(0.52, 1.0, 0.4, 0.14),
				"glow_hype": Color(0.74, 1.0, 0.62, 0.28),
				"tint_base": Color(0.64, 1.0, 0.48, 0.34),
				"tint_hype": Color(0.8, 1.0, 0.66, 0.46)
			}
		7:
			return {
				"base_a": Color(0.64, 0.78, 1.0, 1.0),
				"base_b": Color(0.01, 0.01, 0.08, 1.0),
				"base_c": Color(0.88, 0.94, 1.0, 1.0),
				"base_d": Color(1.0, 1.0, 1.0, 1.0),
				"hype_a": Color(0.8, 0.86, 1.0, 1.0),
				"hype_b": Color(0.02, 0.02, 0.12, 1.0),
				"hype_c": Color(0.96, 0.98, 1.0, 1.0),
				"hype_d": Color(1.0, 1.0, 1.0, 1.0),
				"overlay_alpha": 0.94,
				"time_scale": 1.45,
				"bg_color": Color(0.01, 0.01, 0.07, 1.0),
				"particles_base": Color(0.72, 0.88, 1.0, 0.44),
				"particles_hype": Color(0.94, 0.98, 1.0, 0.72),
				"streaks_base": Color(0.86, 0.94, 1.0, 0.36),
				"streaks_hype": Color(0.98, 1.0, 1.0, 0.62)
			}
		8:
			return {
				"base_a": Color(0.9, 0.84, 0.66, 1.0),
				"base_b": Color(0.24, 0.2, 0.14, 1.0),
				"base_c": Color(1.0, 0.9, 0.68, 1.0),
				"base_d": Color(0.58, 0.5, 0.38, 1.0),
				"hype_a": Color(0.9, 0.84, 0.72, 1.0),
				"hype_b": Color(0.22, 0.18, 0.16, 1.0),
				"hype_c": Color(0.99, 0.92, 0.78, 1.0),
				"hype_d": Color(0.74, 0.64, 0.52, 1.0),
				"overlay_alpha": 0.84,
				"time_scale": 1.0,
				"bg_color": Color(0.2, 0.18, 0.14, 1.0),
				"glow_base": Color(1.0, 0.9, 0.72, 0.08),
				"glow_hype": Color(1.0, 0.95, 0.8, 0.18)
			}
		9:
			return {
				"base_a": Color(0.66, 0.54, 1.0, 1.0),
				"base_b": Color(0.07, 0.04, 0.16, 1.0),
				"base_c": Color(0.0, 1.0, 0.98, 1.0),
				"base_d": Color(1.0, 0.54, 0.94, 1.0),
				"hype_a": Color(0.82, 0.74, 1.0, 1.0),
				"hype_b": Color(0.1, 0.06, 0.24, 1.0),
				"hype_c": Color(0.5, 1.0, 1.0, 1.0),
				"hype_d": Color(1.0, 0.78, 0.98, 1.0),
				"overlay_alpha": 1.0,
				"time_scale": 1.7,
				"bg_color": Color(0.06, 0.04, 0.14, 1.0),
				"glow_base": Color(0.66, 0.5, 1.0, 0.2),
				"glow_hype": Color(0.8, 0.7, 1.0, 0.38),
				"particles_base": Color(0.62, 0.92, 1.0, 0.42),
				"particles_hype": Color(1.0, 0.78, 0.98, 0.7),
				"streaks_base": Color(0.78, 0.84, 1.0, 0.36),
				"streaks_hype": Color(1.0, 0.84, 1.0, 0.62)
			}
		_:
			return {}

func _configure_effect_overlays() -> void:
	var show_glow: bool = false
	var show_points: bool = false
	var show_streaks: bool = false
	match _effect_index:
		0:
			show_glow = true
			show_points = true
		1:
			show_points = true
			show_streaks = true
		3:
			show_points = true
			show_glow = true
		4:
			show_glow = true
			show_points = true
			show_streaks = true
		5:
			show_glow = true
			show_points = true
		6:
			show_glow = true
		7:
			show_points = true
			show_streaks = true
		8:
			show_glow = true
		9:
			show_glow = true
			show_points = true
			show_streaks = true
	center_glow.visible = show_glow
	particles.visible = show_points
	particles.emitting = show_points
	streak_particles.visible = show_streaks
	streak_particles.emitting = show_streaks

func _ensure_debug_overlay() -> void:
	if not debug_overlay_enabled:
		return
	_debug_layer = CanvasLayer.new()
	_debug_layer.layer = 8
	add_child(_debug_layer)
	_debug_label = Label.new()
	_debug_label.name = "BackgroundDebugLabel"
	_debug_label.add_theme_color_override("font_color", Color(0.92, 0.97, 1.0, 0.9))
	_debug_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	_debug_label.add_theme_constant_override("shadow_offset_x", 1)
	_debug_label.add_theme_constant_override("shadow_offset_y", 1)
	_debug_label.add_theme_font_size_override("font_size", 22)
	_debug_layer.add_child(_debug_label)
	_update_debug_label()

func _update_debug_label() -> void:
	if _debug_label == null:
		return
	_debug_label.text = "BG FX %d/10: %s\n[, ] / 1..0" % [_effect_index + 1, get_effect_name()]

func _apply_base_background() -> void:
	base_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base_layer.position = Vector2.ZERO
	base_layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	base_layer.stretch_mode = TextureRect.STRETCH_SCALE
	base_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if base_background_mode == BaseBackgroundMode.IMAGE and base_background_image != null:
		base_layer.texture = base_background_image
		base_layer.modulate = Color(1.0, 1.0, 1.0, 1.0)
		return
	base_layer.texture = _get_solid_texture()
	base_layer.modulate = base_background_color

func _get_solid_texture() -> Texture2D:
	if _solid_texture != null:
		return _solid_texture
	var width: int = 8
	var height: int = 128
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	var top := Color(0.08, 0.18, 0.36, 1.0)
	var mid := Color(0.06, 0.14, 0.32, 1.0)
	var bottom := Color(0.03, 0.06, 0.18, 1.0)
	for y in range(height):
		var v: float = float(y) / max(1.0, float(height - 1))
		var row_color: Color
		if v < 0.55:
			row_color = top.lerp(mid, v / 0.55)
		else:
			row_color = mid.lerp(bottom, (v - 0.55) / 0.45)
		for x in range(width):
			var u: float = float(x) / max(1.0, float(width - 1))
			var side_boost: float = 1.0 - abs((u * 2.0) - 1.0)
			var tint_mix: float = pow(side_boost, 1.5) * 0.18
			var tinted: Color = row_color.lerp(Color(0.12, 0.14, 0.44, 1.0), tint_mix)
			image.set_pixel(x, y, tinted)
	_solid_texture = ImageTexture.create_from_image(image)
	return _solid_texture

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
	base_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center_glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	particles.position = center
	streak_particles.position = center
	if bg_rect.material:
		bg_rect.material.set_shader_parameter("resolution", _viewport_size)
	if _debug_label:
		var top_padding: float = max(24.0, _viewport_size.y * 0.14)
		_debug_label.position = Vector2(24.0, top_padding)

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
