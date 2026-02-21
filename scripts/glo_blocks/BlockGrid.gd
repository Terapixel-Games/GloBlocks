extends Node2D
class_name BlockGrid

signal block_hit(previous_tier: int, new_tier: int, destroyed: bool, hit_position: Vector2, tint: Color)

const BLOCK_SCENE := preload("res://scenes/glo_blocks/Block.tscn")
const GRID_TOP_PADDING_RATIO: float = 0.06
const GRID_TOP_PADDING_MIN: float = 14.0

var _config: GameplayConfig
var _pattern_config: PatternConfig
var _play_bounds: Rect2
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _blocks: Array[Block] = []
var _layout_origin: Vector2 = Vector2.ZERO
var _layout_block_size: Vector2 = Vector2.ZERO
var _layout_spacing: Vector2 = Vector2.ZERO

func configure(config: GameplayConfig, pattern_config: PatternConfig, play_bounds: Rect2) -> void:
	_config = config
	_pattern_config = pattern_config
	_play_bounds = play_bounds
	_rng.randomize()
	_rebuild_layout_metrics()

func rebuild_grid() -> void:
	clear_blocks()
	if _config == null:
		return
	for row in range(_config.rows):
		var row_tiers: Array[int] = []
		row_tiers.resize(_config.cols)
		for col in range(_config.cols):
			if _pattern_config != null and _pattern_config.symmetrical:
				var mirror_col: int = _config.cols - col - 1
				if col > mirror_col:
					row_tiers[col] = row_tiers[mirror_col]
					continue
			row_tiers[col] = _sample_tier()
		for col in range(_config.cols):
			_spawn_block(Vector2i(col, row), row_tiers[col])

func clear_blocks() -> void:
	for block in _blocks:
		if is_instance_valid(block):
			block.queue_free()
	_blocks.clear()

func find_collision(ball_center: Vector2, ball_radius: float) -> Dictionary:
	for block in _blocks:
		if not is_instance_valid(block):
			continue
		var rect: Rect2 = block.get_rect()
		var hit_data: Dictionary = _circle_rect_hit(ball_center, ball_radius, rect)
		if bool(hit_data.get("hit", false)):
			hit_data["block"] = block
			return hit_data
	return {"hit": false}

func apply_block_hit(block: Block, hit_position: Vector2) -> Dictionary:
	if block == null or not is_instance_valid(block):
		return {"destroyed": false, "previous_tier": 0, "new_tier": 0}
	var result: Dictionary = block.apply_hit()
	var destroyed: bool = bool(result.get("destroyed", false))
	if destroyed:
		_blocks.erase(block)
	var previous_tier: int = int(result.get("previous_tier", 1))
	var new_tier: int = int(result.get("new_tier", 0))
	var tint: Color = _config.tier_color(max(1, new_tier)) if not destroyed else _config.tier_color(previous_tier)
	emit_signal("block_hit", previous_tier, new_tier, destroyed, hit_position, tint)
	return result

func block_count() -> int:
	var count: int = 0
	for block in _blocks:
		if is_instance_valid(block):
			count += 1
	return count

func get_grid_rect() -> Rect2:
	if _config == null:
		return Rect2()
	return Rect2(_layout_origin, _grid_total_size(_layout_block_size, _layout_spacing))

func _spawn_block(cell: Vector2i, tier: int) -> void:
	var block := BLOCK_SCENE.instantiate() as Block
	add_child(block)
	block.setup(_config, tier, _layout_block_size)
	block.global_position = _cell_center(cell)
	_blocks.append(block)

func _cell_center(cell: Vector2i) -> Vector2:
	var step: Vector2 = _layout_block_size + _layout_spacing
	return _layout_origin + Vector2(
		(cell.x * step.x) + (_layout_block_size.x * 0.5),
		(cell.y * step.y) + (_layout_block_size.y * 0.5)
	)

func _sample_tier() -> int:
	if _pattern_config == null:
		return int(_config.durability_tiers[0]) if not _config.durability_tiers.is_empty() else 1
	return _pattern_config.sample_tier(_rng, _config.durability_tiers)

func _circle_rect_hit(center: Vector2, radius: float, rect: Rect2) -> Dictionary:
	var closest: Vector2 = Vector2(
		clamp(center.x, rect.position.x, rect.position.x + rect.size.x),
		clamp(center.y, rect.position.y, rect.position.y + rect.size.y)
	)
	var delta: Vector2 = center - closest
	var dist_sq: float = delta.length_squared()
	if dist_sq > radius * radius:
		return {"hit": false}
	var normal: Vector2
	if dist_sq > 0.0001:
		normal = delta.normalized()
	else:
		var left_pen: float = abs(center.x - rect.position.x)
		var right_pen: float = abs((rect.position.x + rect.size.x) - center.x)
		var top_pen: float = abs(center.y - rect.position.y)
		var bottom_pen: float = abs((rect.position.y + rect.size.y) - center.y)
		var min_pen: float = min(min(left_pen, right_pen), min(top_pen, bottom_pen))
		if min_pen == left_pen:
			normal = Vector2(-1.0, 0.0)
		elif min_pen == right_pen:
			normal = Vector2(1.0, 0.0)
		elif min_pen == top_pen:
			normal = Vector2(0.0, -1.0)
		else:
			normal = Vector2(0.0, 1.0)
	var push_out: float = radius - sqrt(max(0.0, dist_sq))
	return {
		"hit": true,
		"normal": normal,
		"push_out": max(_config.collision_push_out_min, push_out),
		"point": closest,
	}

func _rebuild_layout_metrics() -> void:
	if _config == null:
		_layout_origin = Vector2.ZERO
		_layout_block_size = Vector2.ZERO
		_layout_spacing = Vector2.ZERO
		return
	_layout_block_size = _config.block_size
	_layout_spacing = _config.spacing
	var natural_size: Vector2 = _grid_total_size(_layout_block_size, _layout_spacing)
	var width_scale: float = 1.0
	var height_scale: float = 1.0
	if natural_size.x > 0.0:
		width_scale = min(1.0, _play_bounds.size.x / natural_size.x)
	if natural_size.y > 0.0:
		height_scale = min(1.0, _play_bounds.size.y / natural_size.y)
	var fit_scale: float = max(0.1, min(width_scale, height_scale))
	if fit_scale < 1.0:
		_layout_block_size = _config.block_size * fit_scale
		_layout_spacing = _config.spacing * fit_scale
	var layout_size: Vector2 = _grid_total_size(_layout_block_size, _layout_spacing)
	var centered_x: float = _play_bounds.position.x + ((_play_bounds.size.x - layout_size.x) * 0.5)
	var top_padding: float = max(GRID_TOP_PADDING_MIN, _play_bounds.size.y * GRID_TOP_PADDING_RATIO)
	var desired_y: float = _play_bounds.position.y + top_padding
	var max_x: float = _play_bounds.position.x + _play_bounds.size.x - layout_size.x
	var max_y: float = _play_bounds.position.y + _play_bounds.size.y - layout_size.y
	var clamped_x: float = clamp(centered_x, _play_bounds.position.x, max(_play_bounds.position.x, max_x))
	var clamped_y: float = clamp(desired_y, _play_bounds.position.y, max(_play_bounds.position.y, max_y))
	_layout_origin = Vector2(clamped_x, clamped_y)

func _grid_total_size(block_size: Vector2, spacing: Vector2) -> Vector2:
	if _config == null:
		return Vector2.ZERO
	var cols: int = max(0, _config.cols)
	var rows: int = max(0, _config.rows)
	if cols == 0 or rows == 0:
		return Vector2.ZERO
	return Vector2(
		(float(cols) * block_size.x) + (float(cols - 1) * spacing.x),
		(float(rows) * block_size.y) + (float(rows - 1) * spacing.y)
	)
