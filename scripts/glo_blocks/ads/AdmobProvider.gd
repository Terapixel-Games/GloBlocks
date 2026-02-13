extends Node
class_name AdmobProvider

signal interstitial_loaded
signal interstitial_closed
signal rewarded_loaded
signal rewarded_earned
signal rewarded_closed

var _ready_interstitial: bool = false
var _ready_rewarded: bool = false

func configure(_app_id: String, _interstitial_id: String, _rewarded_id: String) -> void:
	# Integration point: wire your SDK plugin here.
	_ready_interstitial = false
	_ready_rewarded = false

func load_interstitial(_ad_unit_id: String) -> void:
	# Placeholder path keeps behavior predictable when SDK is unavailable.
	_ready_interstitial = false

func load_rewarded(_ad_unit_id: String) -> void:
	_ready_rewarded = false

func show_interstitial(_ad_unit_id: String) -> bool:
	if not _ready_interstitial:
		return false
	_ready_interstitial = false
	emit_signal("interstitial_closed")
	return true

func show_rewarded(_ad_unit_id: String) -> bool:
	if not _ready_rewarded:
		return false
	_ready_rewarded = false
	emit_signal("rewarded_earned")
	emit_signal("rewarded_closed")
	return true

func is_interstitial_ready() -> bool:
	return _ready_interstitial

func is_rewarded_ready() -> bool:
	return _ready_rewarded
