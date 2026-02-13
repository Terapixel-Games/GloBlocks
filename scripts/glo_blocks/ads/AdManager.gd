extends Node

signal rewarded_closed

const MONETIZATION_CONFIG_PATH: String = "res://resources/glo_blocks/config/MonetizationConfig.tres"

var _config: MonetizationConfig
var _provider: Object
var _run_counter: int = 0
var _rewarded_uses_this_run: int = 0
var _pending_rewarded_callback: Callable = Callable()
var _resolved_app_id: String = ""
var _resolved_interstitial_id: String = ""
var _resolved_rewarded_id: String = ""

func _ready() -> void:
	_config = load(MONETIZATION_CONFIG_PATH) as MonetizationConfig
	if _config == null:
		push_warning("AdManager: missing MonetizationConfig; ads disabled.")
		return
	_resolve_ad_ids()
	_initialize_provider()
	preload_ads()

func preload_ads() -> void:
	if not _ads_enabled():
		return
	_provider.call("load_interstitial", _resolved_interstitial_id)
	_provider.call("load_rewarded", _resolved_rewarded_id)

func on_run_started() -> void:
	_run_counter += 1
	_rewarded_uses_this_run = 0

func on_run_finished() -> void:
	if not _ads_enabled():
		return
	var cadence: int = max(1, _config.interstitial_every_n_runs)
	if _run_counter % cadence == 0:
		show_interstitial_if_ready()

func show_interstitial_if_ready() -> bool:
	if not _ads_enabled():
		return false
	var shown: bool = bool(_provider.call("show_interstitial", _resolved_interstitial_id))
	if not shown:
		_provider.call("load_interstitial", _resolved_interstitial_id)
	return shown

func show_rewarded_if_ready(on_rewarded: Callable) -> bool:
	if not _ads_enabled():
		return false
	if _rewarded_uses_this_run >= max(0, _config.rewarded_continue_limit_per_run):
		return false
	_pending_rewarded_callback = on_rewarded
	var shown: bool = bool(_provider.call("show_rewarded", _resolved_rewarded_id))
	if not shown:
		_provider.call("load_rewarded", _resolved_rewarded_id)
		_pending_rewarded_callback = Callable()
	return shown

func _ads_enabled() -> bool:
	if _config == null:
		return false
	if not _config.ad_enabled:
		return false
	if _provider == null:
		return false
	return not _resolved_interstitial_id.is_empty() and not _resolved_rewarded_id.is_empty()

func _initialize_provider() -> void:
	var use_mock: bool = true
	if _config != null and _config.ad_enabled and Engine.has_singleton("AdmobPlugin"):
		use_mock = false
	if use_mock:
		_provider = MockAdProvider.new()
	else:
		var admob := AdmobProvider.new()
		_provider = admob
		add_child(admob)
	_provider.call("configure", _resolved_app_id, _resolved_interstitial_id, _resolved_rewarded_id)
	_bind_provider_signals()

func _bind_provider_signals() -> void:
	if _provider == null:
		return
	if not _provider.is_connected("interstitial_closed", Callable(self, "_on_interstitial_closed")):
		_provider.connect("interstitial_closed", Callable(self, "_on_interstitial_closed"))
	if not _provider.is_connected("rewarded_earned", Callable(self, "_on_rewarded_earned")):
		_provider.connect("rewarded_earned", Callable(self, "_on_rewarded_earned"))
	if not _provider.is_connected("rewarded_closed", Callable(self, "_on_rewarded_closed")):
		_provider.connect("rewarded_closed", Callable(self, "_on_rewarded_closed"))

func _on_interstitial_closed() -> void:
	if _provider == null:
		return
	_provider.call("load_interstitial", _resolved_interstitial_id)

func _on_rewarded_earned() -> void:
	_rewarded_uses_this_run += 1
	if _pending_rewarded_callback.is_valid():
		_pending_rewarded_callback.call()

func _on_rewarded_closed() -> void:
	if _provider != null:
		_provider.call("load_rewarded", _resolved_rewarded_id)
	_pending_rewarded_callback = Callable()
	emit_signal("rewarded_closed")

func _resolve_ad_ids() -> void:
	if _config == null:
		return
	_resolved_app_id = _config.app_id
	_resolved_interstitial_id = _config.interstitial_unit_id
	_resolved_rewarded_id = _config.rewarded_unit_id
	var local_path: String = _config.local_override_path
	if local_path.is_empty():
		return
	if not FileAccess.file_exists(local_path):
		return
	var file := FileAccess.open(local_path, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		var override_data: Dictionary = parsed
		_resolved_app_id = str(override_data.get("app_id", _resolved_app_id))
		_resolved_interstitial_id = str(override_data.get("interstitial_unit_id", _resolved_interstitial_id))
		_resolved_rewarded_id = str(override_data.get("rewarded_unit_id", _resolved_rewarded_id))
