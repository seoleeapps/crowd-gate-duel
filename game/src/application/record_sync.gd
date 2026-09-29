class_name RecordSync
extends RefCounted
## 끝난 판의 내 기록을 원격 문서로 올린다.
##
## 먼저 로컬에 업로드 대기 1건으로 저장하고 나서 올린다. 연결이 없으면 대기 기록이 남아 있다가
## 다음 연결 때 1건으로 올라간다(AC-007). 대기 중에 판을 더 해도 가장 최근 기록 1건만 남는다.

var _port: RemoteRecordPort
var _store: ProgressStore
var _uploading: bool = false
var _in_flight: Dictionary = {}


func _init(port: RemoteRecordPort, store: ProgressStore) -> void:
	_port = port
	_store = store
	_port.upload_finished.connect(_on_upload_finished)


func submit(record: ReplayRecord) -> void:
	_store.set_pending_upload(record.to_dict())
	_store.write()
	flush()


## 대기 기록이 있고 연결돼 있으면 올린다. 앱 시작과 연결 복구 때도 호출한다.
func flush() -> void:
	if _uploading or _store.pending_upload().is_empty() or not _port.is_online():
		return
	_uploading = true
	_in_flight = _store.pending_upload()
	_port.request_upload(_in_flight)


func _on_upload_finished(ok: bool) -> void:
	# 포트를 함께 쓰는 다른 호출자의 업로드 완료는 내 일이 아니다.
	if not _uploading:
		return
	_uploading = false
	# 올리는 사이에 새 판이 끝났으면 대기 기록은 그 새 기록이다. 지우지 않고 이어서 올린다.
	if ok and _store.pending_upload() == _in_flight:
		_store.set_pending_upload({})
		_store.write()
	_in_flight = {}
	if ok:
		flush()
