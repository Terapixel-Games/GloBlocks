extends Node2D

const SHARD_PARTICLES_SCENE := preload("res://fx/ShardParticles.tscn")

@export var gameplay_config: GameplayConfig = preload("res://resources/glo_blocks/config/GameplayConfig.tres")
@export var pattern_config: PatternConfig = preload("res://resources/glo_blocks/config/PatternConfig.tres")

@onready var background: GloBackgroundController = $BackgroundController
@onready var playfield_rig: Node2D = $PlayfieldRig
@onready var playfield: Node2D = $PlayfieldRig/Playfield
@onready var block_grid: BlockGrid = $PlayfieldRig/Playfield/BlockGrid
@onready var paddle: PaddleController = $PlayfieldRig/Playfield/Paddle
@onready var ball: BallController = $PlayfieldRig/Playfield/Ball
@onready var fx_layer: Node2D = $PlayfieldRig/Playfield/FX
@onready var playfield_glow: ColorRect = $PlayfieldRig/Playfield/PlayfieldGlow
@onready var playfield_frame: ColorRect = $PlayfieldRig/Playfield/PlayfieldFrame
@onready var combo_glow: ColorRect = $PlayfieldRig/Playfield/ComboGlow

@onready var score_value: Label = $HUD/TopRow/ScoreBox/Value
@onready var best_value: Label = $HUD/TopRow/BestBox/Value
@onready var game_over_overlay: GameOverOverlay = $GameOverOverlay

var _combo_manager: ComboManager
var _score_manager: ScoreManager
var _play_bounds: Rect2 = Rect2()
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _run_active: bool = false
var _hit_freeze_active: bool = false
var _shake_time_left: float = 0.0
var _shake_strength: float = 0.0
var _hit_freeze_timer: Timer

func _ready() -> void:
	_rng.randomize()
	_setup_runtime_managers()
	_setup_hit_freeze_timer()
	_connect_signals()
	Typography.style_glo_blocks_hud(self)
	Typography.style_glo_blocks_overlay(self)
	_start_run()

func _process(delta: float) -> void:
	_update_screen_shake(delta)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_restore_time_scale()

func _exit_tree() -> void:
	_restore_time_scale()

func _setup_runtime_managers() -> void:
	_combo_manager = ComboManager.new()
	_score_manager = ScoreManager.new()
	add_child(_combo_manager)
	add_child(_score_manager)
	_combo_manager.configure(gameplay_config)
	_score_manager.configure(gameplay_config)

func _setup_hit_freeze_timer() -> void:
	_hit_freeze_timer = Timer.new()
	_hit_freeze_timer.one_shot = true
	_hit_freeze_timer.ignore_time_scale = true
	add_child(_hit_freeze_timer)
	_hit_freeze_timer.timeout.connect(_on_hit_freeze_timeout)

func _connect_signals() -> void:
	ball.connect("block_hit", Callable(self, "_on_ball_block_hit"))
	ball.connect("paddle_hit", Callable(self, "_on_ball_paddle_hit"))
	ball.connect("lost", Callable(self, "_on_ball_lost"))
	_combo_manager.connect("combo_changed", Callable(self, "_on_combo_changed"))
	_score_manager.connect("score_changed", Callable(self, "_on_score_changed"))
	_score_manager.connect("best_changed", Callable(self, "_on_best_changed"))
	game_over_overlay.connect("retry_requested", Callable(self, "_on_retry_requested"))
	get_viewport().size_changed.connect(_on_viewport_resized)
	_on_score_changed(_score_manager.score)
	_on_best_changed(_score_manager.best)

func _on_viewport_resized() -> void:
	Typography.style_glo_blocks_hud(self)
	Typography.style_glo_blocks_overlay(self)
	if not _run_active:
		_layout_scene(false)
		return
	_start_run()

func _start_run() -> void:
	_restore_time_scale()
	_run_active = true
	_shake_time_left = 0.0
	playfield_rig.position = Vector2.ZERO
	game_over_overlay.hide_overlay()
	_score_manager.reset_run()
	_combo_manager.reset()
	_layout_scene(true)
	_spawn_ball()
	AdManager.on_run_started()

func _layout_scene(rebuild_grid: bool) -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var width: float = max(gameplay_config.playfield_min_width, viewport_size.x - (gameplay_config.playfield_margin_x * 2.0))
	var height: float = max(gameplay_config.playfield_min_height, viewport_size.y - gameplay_config.playfield_top - gameplay_config.playfield_bottom_margin)
	_play_bounds = Rect2(
		Vector2(gameplay_config.playfield_margin_x, gameplay_config.playfield_top),
		Vector2(width, height)
	)

	block_grid.configure(gameplay_config, pattern_config, _play_bounds)
	if rebuild_grid:
		block_grid.rebuild_grid()

	paddle.configure(gameplay_config, _play_bounds)
	paddle.set_paddle_y(_play_bounds.position.y + _play_bounds.size.y - gameplay_config.paddle_y_offset)
	paddle.force_centered(_play_bounds.get_center().x)

	ball.configure(gameplay_config, _play_bounds, paddle, block_grid)

	var grid_rect: Rect2 = block_grid.get_grid_rect()
	_apply_playfield_decor(grid_rect)

func _spawn_ball() -> void:
	var spawn_position: Vector2 = paddle.global_position + Vector2(0.0, -gameplay_config.ball_spawn_offset)
	ball.reset_ball(spawn_position)

func _apply_playfield_decor(grid_rect: Rect2) -> void:
	var glow_padding: float = gameplay_config.playfield_glow_padding
	var frame_padding: float = gameplay_config.playfield_frame_padding
	var combo_padding: float = gameplay_config.combo_glow_padding
	playfield_glow.position = grid_rect.position - Vector2(glow_padding, glow_padding)
	playfield_glow.size = grid_rect.size + Vector2(glow_padding * 2.0, glow_padding * 2.0)
	playfield_glow.color = Color(0.48, 0.74, 1.0, 0.08)

	playfield_frame.position = grid_rect.position - Vector2(frame_padding, frame_padding)
	playfield_frame.size = grid_rect.size + Vector2(frame_padding * 2.0, frame_padding * 2.0)
	playfield_frame.color = Color(0.18, 0.28, 0.52, 0.22)

	combo_glow.position = grid_rect.position - Vector2(combo_padding, combo_padding)
	combo_glow.size = grid_rect.size + Vector2(combo_padding * 2.0, combo_padding * 2.0)
	combo_glow.color = Color(0.68, 0.84, 1.0, 0.0)

func _on_ball_block_hit(previous_tier: int, _new_tier: int, destroyed: bool, hit_position: Vector2, tint: Color) -> void:
	if not _run_active:
		return
	_combo_manager.register_block_hit()
	_score_manager.add_points_for_tier(previous_tier, _combo_manager.multiplier)
	if destroyed:
		_spawn_shards(hit_position, tint)
	_request_screen_shake(gameplay_config.screen_shake_strength)
	_trigger_hit_freeze()
	if block_grid.block_count() == 0:
		block_grid.rebuild_grid()
		_apply_playfield_decor(block_grid.get_grid_rect())

func _on_ball_paddle_hit() -> void:
	if not _run_active:
		return
	_combo_manager.register_paddle_hit()

func _on_ball_lost() -> void:
	_end_run()

func _on_retry_requested() -> void:
	_start_run()

func _end_run() -> void:
	if not _run_active:
		return
	_run_active = false
	ball.stop_ball()
	_restore_time_scale()
	_score_manager.finalize_run()
	game_over_overlay.show_results(_score_manager.score, _score_manager.best)
	AdManager.on_run_finished()

func _on_score_changed(score: int) -> void:
	score_value.text = str(score)

func _on_best_changed(best: int) -> void:
	best_value.text = str(best)

func _on_combo_changed(combo: int, multiplier: float) -> void:
	var cap_value: float = float(max(1, gameplay_config.combo_cap))
	var combo_norm: float = clamp(float(combo) / cap_value, 0.0, 1.0)
	var max_curve_mult: float = 1.0
	if not gameplay_config.combo_multiplier_curve.is_empty():
		max_curve_mult = max(1.0, float(gameplay_config.combo_multiplier_curve[gameplay_config.combo_multiplier_curve.size() - 1]))
	var mult_norm: float = clamp((multiplier - 1.0) / max(0.001, max_curve_mult - 1.0), 0.0, 1.0)
	var intensity: float = clamp((combo_norm * 0.65) + (mult_norm * 0.35), 0.0, 1.0)
	background.set_combo_intensity(intensity)
	ball.set_combo_intensity(intensity)
	combo_glow.color.a = lerp(0.0, gameplay_config.combo_glow_max_alpha, intensity)

func _spawn_shards(at: Vector2, tint: Color) -> void:
	var shards := SHARD_PARTICLES_SCENE.instantiate() as ShardParticles
	fx_layer.add_child(shards)
	shards.global_position = at
	shards.burst(tint)

func _trigger_hit_freeze() -> void:
	if _hit_freeze_active:
		return
	if gameplay_config.hit_freeze_duration <= 0.0:
		return
	_hit_freeze_active = true
	Engine.time_scale = clamp(gameplay_config.hit_freeze_time_scale, 0.01, 1.0)
	_hit_freeze_timer.start(gameplay_config.hit_freeze_duration)

func _on_hit_freeze_timeout() -> void:
	_restore_time_scale()

func _restore_time_scale() -> void:
	Engine.time_scale = 1.0
	_hit_freeze_active = false

func _request_screen_shake(strength: float) -> void:
	_shake_strength = max(_shake_strength, strength)
	_shake_time_left = max(_shake_time_left, gameplay_config.screen_shake_duration)

func _update_screen_shake(delta: float) -> void:
	if _shake_time_left <= 0.0:
		if playfield_rig.position != Vector2.ZERO:
			playfield_rig.position = Vector2.ZERO
		return
	_shake_time_left = max(0.0, _shake_time_left - delta)
	var t: float = _shake_time_left / max(0.001, gameplay_config.screen_shake_duration)
	var amp: float = _shake_strength * t
	playfield_rig.position = Vector2(_rng.randf_range(-amp, amp), _rng.randf_range(-amp, amp))
	if _shake_time_left <= 0.0:
		_shake_strength = 0.0
