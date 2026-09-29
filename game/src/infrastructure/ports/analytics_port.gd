class_name AnalyticsPort
extends RefCounted
## 분석 이벤트 포트. 이벤트 이름과 파라미터는 06 분석 이벤트 분류를 따른다.
##
## 이 기본 구현은 목(mock)이다. 실제 전송 없이 최근 이벤트를 메모리에 남기고 디버그 빌드에서만
## 로그로 찍는다. Firebase Analytics 연결 시 이 클래스를 상속해 `_send` 를 바꾼다.

const KEEP: int = 200

var recent: Array[Dictionary] = []


func log_event(event_name: String, params: Dictionary = {}) -> void:
	recent.append({"name": event_name, "params": params})
	if recent.size() > KEEP:
		recent.pop_front()
	_send(event_name, params)


func _send(event_name: String, params: Dictionary) -> void:
	if OS.is_debug_build():
		print("[analytics] %s %s" % [event_name, JSON.stringify(params)])
