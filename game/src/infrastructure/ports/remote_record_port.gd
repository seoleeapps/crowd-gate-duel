class_name RemoteRecordPort
extends RefCounted
## 원격 기록 문서 포트. 사람당 문서 1건(`replays/{userId}`)을 읽고 덮어쓴다(DEC-004).
##
## 판당 원격 연산은 읽기 1건과 쓰기 1건이 전부다(AC-006). 요청 수를 여기서 계측해
## 테스트와 개발 빌드가 상한을 확인한다.
##
## 결과는 신호로 돌려준다. 실제 구현(Firestore)은 네트워크 왕복이 있어 비동기이기 때문이다.
## 실패는 빈 사전 또는 false 로 알린다. 호출자는 실패를 기다리지 않고 봇으로 넘어간다.

signal fetch_finished(data: Dictionary)
signal upload_finished(ok: bool)

var read_count: int = 0
var write_count: int = 0


func is_online() -> bool:
	return false


## 대역·확약 연장 조건에 맞는 남의 기록 1건을 요청한다. 목록을 받아 고르지 않는다.
func request_fetch(band: int, commit_extended: bool) -> void:
	read_count += 1
	_fetch(band, commit_extended)


## 내 기록 문서를 덮어쓴다.
func request_upload(data: Dictionary) -> void:
	write_count += 1
	_upload(data)


## 진행 초기화 때 내 기록 문서를 비운다(02 저장과 리셋 계약).
func request_clear() -> void:
	write_count += 1
	_clear()


func _fetch(_band: int, _commit_extended: bool) -> void:
	fetch_finished.emit({})


func _clear() -> void:
	pass


func _upload(_data: Dictionary) -> void:
	upload_finished.emit(false)
