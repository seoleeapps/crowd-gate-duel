class_name RewardedAdPort
extends RefCounted
## 보상형 광고 포트. 결과 화면 이후 1자리에서만 쓴다(DEC-007).
##
## 이 기본 구현은 목이다. 실제 광고 없이 곧바로 끝까지 본 것으로 처리한다.
## AdMob·AppsInToss 광고 연결 시 마켓별로 상속해 `_show` 를 바꾼다.

## rewarded: 끝까지 봐서 보상을 받을 자격이 생겼는지. 닫거나 실패하면 false.
signal finished(rewarded: bool)


func is_available() -> bool:
	return true


func show() -> void:
	_show()


func _show() -> void:
	finished.emit.call_deferred(true)
