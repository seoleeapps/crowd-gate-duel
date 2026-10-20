class_name InterstitialGate
extends RefCounted
## 판 결과의 준비 상태를 딱 한 번 확인한다. 늦은 로드는 다음 판까지 보류한다.

signal finished

var _port: InterstitialAdPort
var _clock: Callable
var _attempted: Dictionary = {}
var _active: bool = false
var _last_close_ms: int = -45000
var _cooldown_ms: int

func _init(port: InterstitialAdPort, clock: Callable = Time.get_ticks_msec) -> void:
	_port = port
	_clock = clock
	var profile: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://config/monetization.json"))
	_cooldown_ms = int(profile["interstitial"]["cooldown_after_close_ms"])
	_last_close_ms = -_cooldown_ms
	_port.closed.connect(_finish)
	_port.failed.connect(_fail)

func try_result(duel_id: String, tutorial: bool, prepared_at_result: bool = true) -> bool:
	if tutorial or _attempted.has(duel_id):
		return false
	_attempted[duel_id] = true
	if not prepared_at_result or _active or not _port.can_request or not _port.ready:
		return false
	if int(_clock.call()) - _last_close_ms < _cooldown_ms:
		return false
	_active = true
	if not _port.show():
		_active = false
		return false
	return true

func _finish() -> void:
	if not _active:
		return
	_active = false
	_last_close_ms = int(_clock.call())
	finished.emit()
	_port.preload_ad()

func _fail() -> void:
	if not _active:
		return
	_active = false
	finished.emit()
	_port.preload_ad()
