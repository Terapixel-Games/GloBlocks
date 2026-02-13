extends IAdProvider
class_name MockAdProvider

var interstitial_ready: bool = true
var rewarded_ready: bool = true

func configure(_app_id: String, _interstitial_id: String, _rewarded_id: String) -> void:
	interstitial_ready = true
	rewarded_ready = true

func load_interstitial(_ad_unit_id: String) -> void:
	interstitial_ready = true
	emit_signal("interstitial_loaded")

func load_rewarded(_ad_unit_id: String) -> void:
	rewarded_ready = true
	emit_signal("rewarded_loaded")

func show_interstitial(_ad_unit_id: String) -> bool:
	if not interstitial_ready:
		return false
	interstitial_ready = false
	call_deferred("_emit_interstitial_closed")
	return true

func show_rewarded(_ad_unit_id: String) -> bool:
	if not rewarded_ready:
		return false
	rewarded_ready = false
	call_deferred("_emit_rewarded_earned")
	call_deferred("_emit_rewarded_closed")
	return true

func is_interstitial_ready() -> bool:
	return interstitial_ready

func is_rewarded_ready() -> bool:
	return rewarded_ready

func _emit_interstitial_closed() -> void:
	emit_signal("interstitial_closed")

func _emit_rewarded_earned() -> void:
	emit_signal("rewarded_earned")

func _emit_rewarded_closed() -> void:
	emit_signal("rewarded_closed")
