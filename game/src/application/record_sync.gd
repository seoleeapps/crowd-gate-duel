class_name RecordSync
extends RefCounted
## 끝난 판의 내 기록을 원격 문서로 올리고, 진행 초기화 때는 원격 문서를 지운다.
##
## 먼저 로컬에 업로드 대기 1건으로 저장하고 나서 올린다. 연결이 없으면 대기 기록이 남아 있다가
## 다음 연결 때 1건으로 올라간다(AC-007). 대기 중에 판을 더 해도 가장 최근 기록 1건만 남는다.
## 지우기도 같은 방식이다. 대기 표시를 저장해 두고 연결되면 지운다. 올리는 중이던 기록이 있으면
## 그 응답을 받은 뒤에 지워, 늦게 도착한 업로드가 지운 문서를 되살리지 않게 한다.

var _port: RemoteRecordPort
var _store: ProgressStore
var _uploading: bool = false
var _clearing: bool = false
var _in_flight: Dictionary = {}


func _init(port: RemoteRecordPort, store: ProgressStore) -> void:
	_port = port
	_store = store
	_port.upload_finished.connect(_on_upload_finished)
	_port.clear_finished.connect(_on_clear_finished)


func submit(record: ReplayRecord) -> void:
	_store.set_pending_upload(record.to_dict())
	_store.write()
	flush()


## 진행 초기화: 올릴 기록을 버리고 원격 문서 지우기를 대기에 올린다.
func clear_remote() -> void:
	_store.set_pending_upload({})
	_store.set_pending_clear(true)
	_store.write()
	flush()


## 대기 중인 지우기·업로드를 처리한다. 앱 시작과 연결 복구 때도 호출한다.
func flush() -> void:
	if _uploading or _clearing or not _port.is_online():
		return
	if _store.pending_clear():
		_clearing = true
		_port.request_clear()
		return
	if _store.pending_upload().is_empty():
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


func _on_clear_finished(ok: bool) -> void:
	if not _clearing:
		return
	_clearing = false
	if ok:
		_store.set_pending_clear(false)
		_store.write()
		flush()
