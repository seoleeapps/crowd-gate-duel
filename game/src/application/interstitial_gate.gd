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
var _cooldown_path: String

## 저장 경로를 쓰면 clock은 재시작에도 이어지는 Unix 밀리초여야 한다.
func _init(port: InterstitialAdPort, clock: Callable = Time.get_ticks_msec, cooldown_path: String = "") -> void:
	_port = port
	_clock = clock
	_cooldown_path = cooldown_path
	var profile: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://config/monetization.json"))
	_cooldown_ms = int(profile["interstitial"]["cooldown_after_close_ms"])
	_last_close_ms = -_cooldown_ms
	if not _cooldown_path.is_empty():
		var saved: Dictionary = AtomicFileStore.read(_cooldown_path)["data"]
		_last_close_ms = int(saved.get("last_close_ms", -_cooldown_ms))
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
	if not _cooldown_path.is_empty():
		AtomicFileStore.write(_cooldown_path, {"last_close_ms": _last_close_ms})
	finished.emit()
	_port.preload_ad()

func _fail() -> void:
	if not _active:
		return
	_active = false
	finished.emit()
	_port.preload_ad()
