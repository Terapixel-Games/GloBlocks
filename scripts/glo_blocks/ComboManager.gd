extends Node
class_name ComboManager

signal combo_changed(combo: int, multiplier: float)

var _config: GameplayConfig
var combo: int = 0
var multiplier: float = 1.0

func configure(config: GameplayConfig) -> void:
	_config = config
	reset()

func reset() -> void:
	combo = 0
	multiplier = 1.0
	emit_signal("combo_changed", combo, multiplier)

func register_block_hit() -> void:
	if _config == null:
		return
	combo = min(combo + 1, max(1, _config.combo_cap))
	multiplier = _config.combo_multiplier_for(combo)
	emit_signal("combo_changed", combo, multiplier)

func register_paddle_hit() -> void:
	if _config == null:
		return
	if not _config.combo_reset_on_paddle_hit:
		return
	if combo == 0:
		return
	combo = 0
	multiplier = 1.0
	emit_signal("combo_changed", combo, multiplier)
