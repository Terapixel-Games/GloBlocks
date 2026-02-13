extends StaticBody2D
class_name Block

signal durability_changed(block: Block, previous_tier: int, new_tier: int)
signal broken(block: Block, broken_tier: int, tint: Color)

@onready var visual: ColorRect = $Visual
@onready var glow: ColorRect = $Glow

var _config: GameplayConfig
var tier: int = 1
var _size: Vector2 = Vector2(116.0, 46.0)

func setup(config: GameplayConfig, durability_tier: int, block_size: Vector2) -> void:
	_config = config
	_size = block_size
	_set_visual_size()
	set_tier(durability_tier)

func set_tier(new_tier: int) -> void:
	tier = max(1, new_tier)
	_apply_tint(_config.tier_color(tier) if _config != null else Color(0.22, 0.89, 1.0, 0.9))

func apply_hit() -> Dictionary:
	var previous_tier: int = tier
	var next_tier: int = max(0, tier - 1)
	if next_tier <= 0:
		emit_signal("broken", self, previous_tier, _config.tier_color(previous_tier))
		queue_free()
	else:
		set_tier(next_tier)
		emit_signal("durability_changed", self, previous_tier, next_tier)
	return {
		"previous_tier": previous_tier,
		"new_tier": next_tier,
		"destroyed": next_tier <= 0,
	}

func get_rect() -> Rect2:
	return Rect2(global_position - (_size * 0.5), _size)

func get_tint() -> Color:
	if _config == null:
		return Color(0.22, 0.89, 1.0, 0.9)
	return _config.tier_color(tier)

func _set_visual_size() -> void:
	visual.size = _size
	visual.position = -_size * 0.5
	visual.pivot_offset = _size * 0.5
	glow.size = _size + Vector2(18.0, 18.0)
	glow.position = -glow.size * 0.5
	glow.pivot_offset = glow.size * 0.5

func _apply_tint(tint: Color) -> void:
	visual.color = tint
	var mat := visual.material as ShaderMaterial
	if mat == null:
		mat = ShaderMaterial.new()
		mat.shader = preload("res://shaders/TileGlass.gdshader")
		visual.material = mat
	mat.set_shader_parameter("tint_color", tint)
	mat.set_shader_parameter("blur_radius", 2.0)
	mat.set_shader_parameter("border", 0.08)
	mat.set_shader_parameter("corner_radius", 0.14)
	mat.set_shader_parameter("edge_color", tint.lightened(0.34))
	glow.color = Color(tint.r, tint.g, tint.b, 0.25 + (0.08 * float(min(4, tier))))
