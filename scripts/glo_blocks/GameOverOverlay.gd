extends Control
class_name GameOverOverlay

signal retry_requested

@onready var score_label: Label = $Panel/VBox/Score
@onready var best_label: Label = $Panel/VBox/Best

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP

func show_results(score: int, best: int) -> void:
	score_label.text = str(score)
	best_label.text = "Best %d" % best
	visible = true

func hide_overlay() -> void:
	visible = false

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		emit_signal("retry_requested")
	elif event is InputEventScreenTouch and event.pressed:
		get_viewport().set_input_as_handled()
		emit_signal("retry_requested")
