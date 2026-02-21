extends GdUnitTestSuite

func test_square_layout_centers_play_bounds() -> void:
	var layout: Dictionary = PlayLayoutSystem.compute_layout(
		Vector2(1000.0, 600.0),
		PlayLayoutSystem.Mode.SQUARE_CENTERED,
		Vector2(100.0, 100.0),
		40.0,
		Vector2(100.0, 100.0)
	)
	var bounds: Rect2 = layout.get("play_bounds", Rect2())
	assert_float(bounds.position.x).is_equal(240.0)
	assert_float(bounds.position.y).is_equal(40.0)
	assert_float(bounds.size.x).is_equal(520.0)
	assert_float(bounds.size.y).is_equal(520.0)
	assert_float(float(layout.get("play_scale", 0.0))).is_equal(5.2)
	assert_bool(bool(layout.get("is_landscape", false))).is_true()

func test_square_layout_respects_min_size_when_view_is_tiny() -> void:
	var layout: Dictionary = PlayLayoutSystem.compute_layout(
		Vector2(320.0, 480.0),
		PlayLayoutSystem.Mode.SQUARE_CENTERED,
		Vector2(100.0, 100.0),
		40.0,
		Vector2(420.0, 420.0)
	)
	var bounds: Rect2 = layout.get("play_bounds", Rect2())
	assert_float(bounds.size.x).is_equal(400.0)
	assert_float(bounds.size.y).is_equal(400.0)
	assert_bool(bool(layout.get("is_landscape", true))).is_false()

func test_rotating_layout_swaps_axis_in_landscape() -> void:
	var layout: Dictionary = PlayLayoutSystem.compute_layout(
		Vector2(1920.0, 1080.0),
		PlayLayoutSystem.Mode.ROTATE_TO_LANDSCAPE,
		Vector2(720.0, 1280.0),
		0.0,
		Vector2(0.0, 0.0)
	)
	var bounds: Rect2 = layout.get("play_bounds", Rect2())
	assert_float(float(layout.get("rig_rotation", 0.0))).is_equal(PI * 0.5)
	assert_float(float(layout.get("play_scale", 0.0))).is_equal(1.5)
	assert_float(bounds.size.x).is_equal(1920.0)
	assert_float(bounds.size.y).is_equal(1080.0)
	assert_bool(bool(layout.get("is_landscape", false))).is_true()
