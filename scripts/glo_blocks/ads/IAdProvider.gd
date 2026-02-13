extends RefCounted
class_name IAdProvider

signal interstitial_loaded
signal interstitial_closed
signal rewarded_loaded
signal rewarded_earned
signal rewarded_closed

func configure(_app_id: String, _interstitial_id: String, _rewarded_id: String) -> void:
	pass

func load_interstitial(_ad_unit_id: String) -> void:
	pass

func load_rewarded(_ad_unit_id: String) -> void:
	pass

func show_interstitial(_ad_unit_id: String) -> bool:
	return false

func show_rewarded(_ad_unit_id: String) -> bool:
	return false

func is_interstitial_ready() -> bool:
	return false

func is_rewarded_ready() -> bool:
	return false
