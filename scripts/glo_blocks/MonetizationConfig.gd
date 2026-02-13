extends Resource
class_name MonetizationConfig

@export var ad_enabled: bool = false
@export var interstitial_every_n_runs: int = 3
@export var rewarded_continue_limit_per_run: int = 0
@export var rewarded_score_multiplier: float = 1.0

# Keep IDs empty in tracked resources. Load from local override JSON.
@export var app_id: String = ""
@export var interstitial_unit_id: String = ""
@export var rewarded_unit_id: String = ""
@export var local_override_path: String = "res://configs/ads/AdUnits.local.json"
