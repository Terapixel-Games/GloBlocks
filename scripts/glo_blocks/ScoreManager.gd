extends Node
class_name ScoreManager

signal score_changed(score: int)
signal best_changed(best: int)

var _config: GameplayConfig
var score: int = 0
var best: int = 0

func configure(config: GameplayConfig) -> void:
	_config = config
	best = SaveStore.get_int(_config.high_score_save_key, 0)
	emit_signal("best_changed", best)
	reset_run()

func reset_run() -> void:
	score = 0
	emit_signal("score_changed", score)

func add_points_for_tier(tier: int, multiplier: float) -> int:
	if _config == null:
		return 0
	var points: int = int(round(_config.tier_points(tier) * multiplier))
	score += points
	emit_signal("score_changed", score)
	return points

func finalize_run() -> void:
	if _config == null:
		return
	if score <= best:
		return
	best = score
	SaveStore.set_int(_config.high_score_save_key, best)
	emit_signal("best_changed", best)
