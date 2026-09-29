class_name LocalRemoteRecordPort
extends RemoteRecordPort
## 프로토타입용 원격 기록 목(mock). 네트워크 없이 메모리 안에서 문서 저장소를 흉내 낸다.
##
## 기록 풀은 비어 있는 상태로 시작한다. 사람이 남긴 기록이 없는데 가짜 기록에 사람 이름을
## 붙이면 봇을 사람으로 위장하는 것이 되기 때문이다(DEC-003). 그래서 프로토타입의 일반 대국은
## 전부 봇 배지가 붙은 봇 대국이 되고, 기록 경로는 테스트가 풀을 채워 검증한다.

var online: bool = true
## false 면 응답을 쥐고 있다가 `deliver()` 때 돌려준다. 느린 네트워크를 흉내 낸다.
var respond_immediately: bool = true
var pool: Array[Dictionary] = []
## 내 문서. 판마다 새 문서를 만들지 않고 이 1건을 덮어쓴다.
var my_document: Dictionary = {}

var _held_fetch: Array[Dictionary] = []


func is_online() -> bool:
	return online


func deliver() -> void:
	for data: Dictionary in _held_fetch:
		fetch_finished.emit(data)
	_held_fetch.clear()


func _fetch(band: int) -> void:
	var found: Dictionary = {}
	if online:
		for data: Dictionary in pool:
			if int(data.get("band", 0)) == band:
				found = data
				break
	if respond_immediately:
		fetch_finished.emit(found)
	else:
		_held_fetch.append(found)


func _upload(data: Dictionary) -> void:
	if not online:
		upload_finished.emit(false)
		return
	my_document = data.duplicate(true)
	upload_finished.emit(true)
