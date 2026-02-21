extends Node2D
class_name BallController

signal block_hit(previous_tier: int, new_tier: int, destroyed: bool, hit_position: Vector2, tint: Color)
signal paddle_hit
signal lost

@onready var visual: ColorRect = $Visual
@onready var glow: ColorRect = $Glow

var _config: GameplayConfig
var _play_bounds: Rect2
var _paddle: PaddleController
var _block_grid: BlockGrid
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _scale: float = 1.0

var velocity: Vector2 = Vector2.ZERO
var _current_speed: float = 0.0
var _speed_timer: float = 0.0
var _radius: float = 12.0
var _base_speed_scaled: float = 0.0
var _max_speed_cap_scaled: float = 0.0
var _active: bool = false
var _combo_intensity: float = 0.0

func _ready() -> void:
	_rng.randomize()

func configure(config: GameplayConfig, play_bounds: Rect2, paddle: PaddleController, block_grid: BlockGrid, play_scale: float = 1.0) -> void:
	_config = config
	_play_bounds = play_bounds
	_paddle = paddle
	_block_grid = block_grid
	_scale = max(0.3, play_scale)
	_radius = _config.ball_radius * _scale
	_base_speed_scaled = _config.base_ball_speed * _scale
	_max_speed_cap_scaled = _config.max_speed_cap * _scale
	_update_visual_size()
	_setup_visual_materials()

func set_play_bounds(play_bounds: Rect2) -> void:
	_play_bounds = play_bounds

func reset_ball(spawn_at: Vector2) -> void:
	if _config == null:
		return
	global_position = spawn_at
	_current_speed = _base_speed_scaled
	_speed_timer = 0.0
	var x_dir: float = -1.0 if _rng.randi() % 2 == 0 else 1.0
	var launch_angle_rad: float = deg_to_rad(_config.launch_angle_degrees)
	velocity = Vector2(sin(launch_angle_rad) * x_dir, -cos(launch_angle_rad)).normalized() * _current_speed
	_active = true

func stop_ball() -> void:
	_active = false
	velocity = Vector2.ZERO

func set_combo_intensity(amount: float) -> void:
	_combo_intensity = clamp(amount, 0.0, 1.0)
	var glow_alpha: float = lerp(0.24, 0.52, _combo_intensity)
	glow.color = Color(0.82, 0.93, 1.0, glow_alpha)

func _physics_process(delta: float) -> void:
	if not _active or _config == null:
		return
	_tick_speed(delta)
	var travel: Vector2 = velocity * delta
	var min_step: float = max(1.0, _radius * _config.physics_substep_radius_factor)
	var max_steps: int = max(1, _config.physics_max_substeps)
	var step_count: int = clampi(int(ceil(travel.length() / min_step)), 1, max_steps)
	var step_delta: float = delta / float(step_count)
	for _i in range(step_count):
		_simulate_step(step_delta)
		if not _active:
			break

func _simulate_step(step_delta: float) -> void:
	var next_position: Vector2 = global_position + (velocity * step_delta)
	var left: float = _play_bounds.position.x + _radius
	var right: float = _play_bounds.position.x + _play_bounds.size.x - _radius
	var top: float = _play_bounds.position.y + _radius
	var bottom: float = _play_bounds.position.y + _play_bounds.size.y + _radius

	if next_position.x <= left:
		next_position.x = left
		velocity.x = abs(velocity.x)
	elif next_position.x >= right:
		next_position.x = right
		velocity.x = -abs(velocity.x)

	if next_position.y <= top:
		next_position.y = top
		velocity.y = abs(velocity.y)

	if _paddle != null and velocity.y > 0.0:
		var paddle_rect: Rect2 = _paddle.get_collision_rect()
		var paddle_hit_data: Dictionary = _circle_rect_hit(next_position, _radius, paddle_rect)
		if bool(paddle_hit_data.get("hit", false)):
			next_position += Vector2.UP * float(paddle_hit_data.get("push_out", 1.0))
			var offset_ratio: float = clamp(
				(next_position.x - paddle_rect.get_center().x) / max(1.0, paddle_rect.size.x * 0.5),
				-1.0,
				1.0
			)
			var range_rad: float = deg_to_rad(_config.paddle_bounce_range_degrees)
			var angle: float = offset_ratio * range_rad
			var direction: Vector2 = Vector2(sin(angle), -cos(angle)).normalized()
			direction = _enforce_min_reflection(direction)
			velocity = direction * _current_speed
			emit_signal("paddle_hit")

	if _block_grid != null:
		var block_hit_data: Dictionary = _block_grid.find_collision(next_position, _radius)
		if bool(block_hit_data.get("hit", false)):
			var normal: Vector2 = block_hit_data.get("normal", Vector2.UP)
			var push_out: float = float(block_hit_data.get("push_out", 1.0))
			next_position += normal * push_out
			velocity = velocity.bounce(normal)
			if velocity.length_squared() <= 0.0001:
				velocity = Vector2(0.0, -1.0) * _current_speed
			else:
				velocity = velocity.normalized() * _current_speed
			var block: Block = block_hit_data.get("block") as Block
			var hit_point: Vector2 = block_hit_data.get("point", next_position)
			var result: Dictionary = _block_grid.apply_block_hit(block, hit_point)
			var previous_tier: int = int(result.get("previous_tier", 1))
			var new_tier: int = int(result.get("new_tier", 0))
			var destroyed: bool = bool(result.get("destroyed", false))
			var tint: Color = _config.tier_color(previous_tier if destroyed else max(1, new_tier))
			emit_signal("block_hit", previous_tier, new_tier, destroyed, hit_point, tint)

	global_position = next_position

	if global_position.y >= bottom:
		_active = false
		emit_signal("lost")

func _tick_speed(delta: float) -> void:
	var interval: float = max(_config.speed_interval_min_seconds, _config.speed_increase_interval_seconds)
	_speed_timer += delta
	while _speed_timer >= interval:
		_speed_timer -= interval
		_current_speed = min(_current_speed * (1.0 + _config.speed_increase_percent), _max_speed_cap_scaled)
		if velocity.length_squared() > 0.0001:
			velocity = velocity.normalized() * _current_speed

func _enforce_min_reflection(direction: Vector2) -> Vector2:
	var min_vertical: float = sin(deg_to_rad(_config.min_reflection_angle_degrees))
	var dir: Vector2 = direction.normalized()
	var y_sign: float = -1.0 if dir.y <= 0.0 else 1.0
	if abs(dir.y) < min_vertical:
		dir.y = y_sign * min_vertical
		dir.x = sign(dir.x) * sqrt(max(0.0, 1.0 - (dir.y * dir.y)))
	if dir.length_squared() <= 0.0001:
		return Vector2(0.0, -1.0)
	return dir.normalized()

func _circle_rect_hit(center: Vector2, radius: float, rect: Rect2) -> Dictionary:
	var closest: Vector2 = Vector2(
		clamp(center.x, rect.position.x, rect.position.x + rect.size.x),
		clamp(center.y, rect.position.y, rect.position.y + rect.size.y)
	)
	var delta: Vector2 = center - closest
	var dist_sq: float = delta.length_squared()
	if dist_sq > radius * radius:
		return {"hit": false}
	var push_out: float = radius - sqrt(max(0.0, dist_sq))
	return {
		"hit": true,
		"push_out": max(_config.collision_push_out_min, push_out),
	}

func _update_visual_size() -> void:
	var diameter: float = _radius * 2.0
	visual.size = Vector2(diameter, diameter)
	visual.position = -visual.size * 0.5
	visual.pivot_offset = visual.size * 0.5
	glow.size = Vector2(diameter + (22.0 * _scale), diameter + (22.0 * _scale))
	glow.position = -glow.size * 0.5
	glow.pivot_offset = glow.size * 0.5

func _setup_visual_materials() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/TileGlass.gdshader")
	mat.set_shader_parameter("tint_color", Color(0.96, 0.99, 1.0, 0.98))
	mat.set_shader_parameter("blur_radius", 2.0)
	mat.set_shader_parameter("border", 0.18)
	mat.set_shader_parameter("corner_radius", 0.5)
	mat.set_shader_parameter("edge_color", Color(1.0, 1.0, 1.0, 0.78))
	visual.material = mat
	visual.color = Color(0.96, 0.99, 1.0, 0.98)
	glow.color = Color(0.82, 0.93, 1.0, 0.24)
