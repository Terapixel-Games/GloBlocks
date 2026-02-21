extends Resource
class_name GameplayConfig

enum PlayfieldLayoutMode {
	SQUARE_CENTERED,
	ROTATE_TO_LANDSCAPE
}

@export var base_ball_speed: float = 920.0
@export var max_speed_cap: float = 1680.0
@export var speed_increase_interval_seconds: float = 7.5
@export var speed_increase_percent: float = 0.08

@export var paddle_width: float = 260.0
@export var paddle_height: float = 28.0
@export var paddle_y_offset: float = 218.0
@export var paddle_smoothing: float = 18.0

@export var min_reflection_angle_degrees: float = 18.0
@export var paddle_bounce_range_degrees: float = 62.0

@export var ball_radius: float = 14.0
@export var ball_spawn_offset: float = 72.0
@export var launch_angle_degrees: float = 24.0

@export var rows: int = 7
@export var cols: int = 8
@export var block_size: Vector2 = Vector2(116.0, 46.0)
@export var spacing: Vector2 = Vector2(14.0, 14.0)
@export var grid_origin: Vector2 = Vector2(120.0, 286.0)

@export var durability_tiers: PackedInt32Array = PackedInt32Array([1, 2, 3, 4])
@export var durability_colors: PackedColorArray = PackedColorArray([
	Color(0.22, 0.89, 1.0, 0.9),
	Color(0.62, 0.46, 1.0, 0.92),
	Color(1.0, 0.34, 0.82, 0.94),
	Color(1.0, 0.97, 0.85, 0.96),
])
@export var durability_base_points: PackedInt32Array = PackedInt32Array([100, 180, 280, 420])

@export var combo_reset_on_paddle_hit: bool = true
@export var combo_multiplier_curve: PackedFloat32Array = PackedFloat32Array([1.0, 1.5, 2.0, 3.0, 5.0, 8.0, 13.0])
@export var combo_cap: int = 48

@export var hit_freeze_duration: float = 0.03
@export var hit_freeze_time_scale: float = 0.08
@export var screen_shake_strength: float = 2.4
@export var screen_shake_duration: float = 0.09

@export var playfield_margin_x: float = 80.0
@export var playfield_top: float = 200.0
@export var playfield_bottom_margin: float = 120.0
@export var playfield_min_width: float = 320.0
@export var playfield_min_height: float = 420.0
@export var playfield_layout_mode: PlayfieldLayoutMode = PlayfieldLayoutMode.SQUARE_CENTERED
@export var layout_reference_size: Vector2 = Vector2(1010.0, 1010.0)
@export var side_hud_trigger_aspect: float = 1.25
@export var side_hud_width: float = 260.0
@export var side_hud_width_ratio: float = 0.24
@export var side_hud_left_margin: float = 24.0
@export var side_hud_top_margin: float = 24.0
@export var paddle_bottom_padding_ratio: float = 0.06
@export var paddle_bottom_padding_min: float = 12.0
@export var wall_thickness: float = 22.0

@export var physics_substep_radius_factor: float = 0.5
@export var physics_max_substeps: int = 16
@export var collision_push_out_min: float = 0.5
@export var speed_interval_min_seconds: float = 0.05

@export var playfield_glow_padding: float = 34.0
@export var playfield_frame_padding: float = 14.0
@export var combo_glow_padding: float = 18.0
@export var combo_glow_max_alpha: float = 0.2

@export var high_score_save_key: String = "globlocks_best"

func tier_color(tier: int) -> Color:
	if durability_colors.is_empty():
		return Color(1, 1, 1, 0.92)
	var idx: int = clamp(tier - 1, 0, durability_colors.size() - 1)
	return durability_colors[idx]

func tier_points(tier: int) -> int:
	if durability_base_points.is_empty():
		return 0
	var idx: int = clamp(tier - 1, 0, durability_base_points.size() - 1)
	return int(durability_base_points[idx])

func combo_multiplier_for(combo_count: int) -> float:
	if combo_count <= 0:
		return 1.0
	if combo_multiplier_curve.is_empty():
		return 1.0
	var idx: int = clamp(combo_count - 1, 0, combo_multiplier_curve.size() - 1)
	return max(1.0, float(combo_multiplier_curve[idx]))
