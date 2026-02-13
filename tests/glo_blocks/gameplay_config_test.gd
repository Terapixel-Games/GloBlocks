extends GdUnitTestSuite

var _config: GameplayConfig

func before_test() -> void:
	_config = GameplayConfig.new()

func test_combo_multiplier_for_zero_returns_one() -> void:
	assert_float(_config.combo_multiplier_for(0)).is_equal(1.0)

func test_combo_multiplier_uses_curve_values() -> void:
	_config.combo_multiplier_curve = PackedFloat32Array([1.0, 1.5, 2.0, 3.0])
	assert_float(_config.combo_multiplier_for(1)).is_equal(1.0)
	assert_float(_config.combo_multiplier_for(3)).is_equal(2.0)

func test_combo_multiplier_clamps_to_last_curve_value() -> void:
	_config.combo_multiplier_curve = PackedFloat32Array([1.0, 1.6, 2.4])
	assert_float(_config.combo_multiplier_for(999)).is_equal(2.4)
