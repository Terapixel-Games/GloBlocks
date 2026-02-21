extends Node2D
class_name PaddleController

@onready var visual: ColorRect = $Visual
@onready var glow: ColorRect = $Glow

var _config: GameplayConfig
var _play_bounds: Rect2
var _target_x: float = 0.0
var _drag_active: bool = false
var _touch_index: int = -1
var _scale: float = 1.0
var _paddle_width: float = 0.0
var _paddle_height: float = 0.0
var _half_width: float = 0.0

func _ready() -> void:
	_setup_visual_materials()

func configure(config: GameplayConfig, play_bounds: Rect2, play_scale: float = 1.0) -> void:
	_config = config
	_play_bounds = play_bounds
	_scale = max(0.3, play_scale)
	_paddle_width = _config.paddle_width * _scale
	_paddle_height = _config.paddle_height * _scale
	_half_width = _paddle_width * 0.5
	_target_x = global_position.x
	_update_visual_size()
	global_position.x = _clamp_x(global_position.x)

func set_play_bounds(play_bounds: Rect2) -> void:
	_play_bounds = play_bounds
	global_position.x = _clamp_x(global_position.x)

func set_paddle_y(y_pos: float) -> void:
	global_position.y = y_pos

func force_centered(x_pos: float) -> void:
	_target_x = _clamp_x(x_pos)
	global_position.x = _target_x

func _input(event: InputEvent) -> void:
	if _config == null:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_drag_active = true
			_touch_index = event.index
			_target_x = _clamp_x(event.position.x)
		elif event.index == _touch_index:
			_drag_active = false
			_touch_index = -1
	elif event is InputEventScreenDrag:
		if _drag_active and event.index == _touch_index:
			_target_x = _clamp_x(event.position.x)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_drag_active = event.pressed
		if event.pressed:
			_target_x = _clamp_x(event.position.x)
	elif event is InputEventMouseMotion and _drag_active and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_target_x = _clamp_x(event.position.x)

func _process(delta: float) -> void:
	if _config == null:
		return
	var blend: float = 1.0 - exp(-_config.paddle_smoothing * delta)
	global_position.x = lerp(global_position.x, _target_x, blend)
	global_position.x = _clamp_x(global_position.x)

func get_collision_rect() -> Rect2:
	return Rect2(
		Vector2(global_position.x - _half_width, global_position.y - (_paddle_height * 0.5)),
		Vector2(_paddle_width, _paddle_height)
	)

func _clamp_x(value: float) -> float:
	var min_x: float = _play_bounds.position.x + _half_width
	var max_x: float = _play_bounds.position.x + _play_bounds.size.x - _half_width
	return clamp(value, min_x, max_x)

func _update_visual_size() -> void:
	if _config == null:
		return
	visual.size = Vector2(_paddle_width, _paddle_height)
	visual.position = Vector2(-_paddle_width * 0.5, -_paddle_height * 0.5)
	visual.pivot_offset = visual.size * 0.5
	glow.size = Vector2(_paddle_width + (28.0 * _scale), _paddle_height + (24.0 * _scale))
	glow.position = Vector2(-glow.size.x * 0.5, -glow.size.y * 0.5)
	glow.pivot_offset = glow.size * 0.5

func _setup_visual_materials() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/TileGlass.gdshader")
	mat.set_shader_parameter("tint_color", Color(0.78, 0.89, 1.0, 0.92))
	mat.set_shader_parameter("blur_radius", 2.0)
	mat.set_shader_parameter("border", 0.08)
	mat.set_shader_parameter("corner_radius", 0.38)
	mat.set_shader_parameter("edge_color", Color(0.98, 0.99, 1.0, 0.58))
	visual.material = mat
	visual.color = Color(0.78, 0.89, 1.0, 0.92)
	glow.color = Color(0.48, 0.76, 1.0, 0.24)
