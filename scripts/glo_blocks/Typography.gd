extends Node

const REFERENCE_HEIGHT: float = 2532.0
const GLOBAL_TEXT_SCALE: float = 2.12
const MIN_SCALE_FACTOR: float = 0.90
const MAX_SCALE_FACTOR: float = 2.30
const PRIMARY_TEXT: Color = Color8(242, 244, 255, 255)
const SECONDARY_TEXT: Color = Color8(242, 244, 255, 166)
const SHADOW_TEXT: Color = Color(0.02, 0.04, 0.12, 0.82)

const SIZE_HUD_CAPTION: float = 18.0
const SIZE_HUD_VALUE: float = 56.0
const SIZE_OVERLAY_TITLE: float = 64.0
const SIZE_OVERLAY_SCORE: float = 84.0
const SIZE_OVERLAY_BODY: float = 30.0

const WEIGHT_REGULAR: int = 400
const WEIGHT_MEDIUM: int = 500
const WEIGHT_SEMIBOLD: int = 600
const WEIGHT_BOLD: int = 700

var _base_font: FontFile = preload("res://assets/fonts/SpaceGrotesk.ttf")
var _font_cache: Dictionary = {}

func scale_factor() -> float:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return 1.0
	var h: float = tree.root.get_visible_rect().size.y
	if h <= 0.0:
		return 1.0
	return clamp(h / REFERENCE_HEIGHT, MIN_SCALE_FACTOR, MAX_SCALE_FACTOR)

func px(reference_size: float) -> int:
	return int(round(reference_size * scale_factor() * GLOBAL_TEXT_SCALE))

func _font_for_weight(weight: int) -> Font:
	if _font_cache.has(weight):
		return _font_cache[weight]
	var variation := FontVariation.new()
	variation.base_font = _base_font
	variation.variation_opentype = {"wght": weight}
	_font_cache[weight] = variation
	return variation

func style_label(label: Label, reference_size: float, weight: int, secondary: bool = false) -> void:
	if label == null:
		return
	label.add_theme_font_override("font", _font_for_weight(weight))
	label.add_theme_font_size_override("font_size", px(reference_size))
	label.add_theme_color_override("font_color", SECONDARY_TEXT if secondary else PRIMARY_TEXT)
	label.add_theme_color_override("font_outline_color", SHADOW_TEXT)
	label.add_theme_constant_override("outline_size", max(1, int(round(2.0 * scale_factor()))))

func style_glo_blocks_hud(scene: Node) -> void:
	style_label(scene.get_node_or_null("HUD/TopRow/ScoreBox/Caption"), SIZE_HUD_CAPTION, WEIGHT_MEDIUM, true)
	style_label(scene.get_node_or_null("HUD/TopRow/ScoreBox/Value"), SIZE_HUD_VALUE, WEIGHT_SEMIBOLD)
	style_label(scene.get_node_or_null("HUD/TopRow/BestBox/Caption"), SIZE_HUD_CAPTION, WEIGHT_MEDIUM, true)
	style_label(scene.get_node_or_null("HUD/TopRow/BestBox/Value"), SIZE_HUD_VALUE, WEIGHT_SEMIBOLD)

func style_glo_blocks_overlay(scene: Node) -> void:
	style_label(scene.get_node_or_null("GameOverOverlay/Panel/VBox/Title"), SIZE_OVERLAY_TITLE, WEIGHT_BOLD)
	style_label(scene.get_node_or_null("GameOverOverlay/Panel/VBox/Score"), SIZE_OVERLAY_SCORE, WEIGHT_BOLD)
	style_label(scene.get_node_or_null("GameOverOverlay/Panel/VBox/Best"), SIZE_OVERLAY_BODY, WEIGHT_MEDIUM, true)
	style_label(scene.get_node_or_null("GameOverOverlay/Panel/VBox/Retry"), SIZE_OVERLAY_BODY, WEIGHT_MEDIUM, true)
