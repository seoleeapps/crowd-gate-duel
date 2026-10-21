class_name AndroidInterstitialAdPort
extends InterstitialAdPort
## Android SDK와 게임 사이의 상태 경계. 오래된 요청과 중복 콜백을 무시한다.

var _bridge: Object
var _load_token: int = 0
var _show_token: int = 0
var _loading: bool = false
var _unit: String = ""

func initialize() -> void:
	if not Engine.has_singleton("CrowdGatePlatform"):
		return
	_bridge = Engine.get_singleton("CrowdGatePlatform")
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://config/android.json"))
	_unit = config["interstitial_test_id"] if OS.is_debug_build() else config["interstitial_id"]
	_bridge.connect("consent_updated", _on_consent)
	_bridge.connect("interstitial_loaded", _on_loaded)
	_bridge.connect("interstitial_load_failed", _on_load_failed)
	_bridge.connect("interstitial_closed", _on_closed)
	_bridge.connect("interstitial_show_failed", _on_show_failed)
	_bridge.call("initialize")

func preload_ad() -> void:
	if _bridge == null or not can_request or _unit.is_empty() or ready or _loading or showing:
		return
	_load_token += 1
	_loading = true
	_bridge.call("loadInterstitial", _unit, _load_token)

func show() -> bool:
	if _bridge == null or not ready or not can_request or showing:
		return false
	ready = false
	showing = true
	_show_token += 1
	_bridge.call("showInterstitial", _show_token)
	return true

func show_privacy_options() -> void:
	if _bridge != null and privacy_required and not showing:
		# 이전 동의로 준비한 광고를 무효화하고 새 동의 상태 이후 다시 준비한다.
		ready = false
		_loading = false
		_load_token += 1
		can_request = false
		_bridge.call("showPrivacyOptions")

func _on_consent(allowed: bool, required: bool) -> void:
	can_request = allowed
	privacy_required = required
	if not allowed:
		ready = false
		_loading = false
		_load_token += 1
	consent_changed.emit()
	preload_ad()

func _on_loaded(token: int) -> void:
	if token != _load_token or not can_request:
		return
	_loading = false
	ready = true
	loaded.emit()

func _on_load_failed(token: int, _code: int) -> void:
	if token != _load_token:
		return
	_loading = false
	ready = false

func _on_closed(token: int) -> void:
	if token != _show_token or not showing:
		return
	showing = false
	closed.emit()

func _on_show_failed(token: int, _code: int) -> void:
	if token != _show_token or not showing:
		return
	showing = false
	failed.emit()
