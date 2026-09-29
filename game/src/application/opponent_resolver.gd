class_name OpponentResolver
extends RefCounted
## 다음 판의 코스와 상대를 정한다.
##
## 상대 기록은 판을 시작하기 전에 미리 1건 받아 둔다(`prefetch`). 판을 시작할 때 기록이 도착해
## 있으면 그 기록의 코스와 선택으로 대국하고, 없으면 기다리지 않고 결정론 봇으로 넘어간다.
## 대전 게임에서 대기 화면은 이탈 지점이기 때문이다(03 상태 매트릭스, 06 성능 예산).
##
## 늦게 도착한 기록은 버리지 않고 다음 판에 쓴다. 이미 읽기 1건을 치렀으므로
## 다음 판에서 다시 요청하지 않아 판당 읽기 1건이 유지된다(AC-006).

var _port: RemoteRecordPort
var _ready_record: ReplayRecord = null
var _pending: bool = false


func _init(port: RemoteRecordPort) -> void:
	_port = port
	_port.fetch_finished.connect(_on_fetch_finished)


## 받아 둔 기록이 없고 요청 중도 아니며 연결돼 있을 때만 1건 요청한다.
## commit_extended 는 확약 시간 연장 여부다. 같은 조건으로 둔 기록끼리 맞붙인다(DEC-008).
func prefetch(band: int, commit_extended: bool = false) -> void:
	if _ready_record != null or _pending or not _port.is_online():
		return
	_pending = true
	_port.request_fetch(band, commit_extended)


func is_pending() -> bool:
	return _pending


## 판을 시작한다. 기록이 있으면 기록 상대, 없으면 봇 상대와 새 코스를 돌려준다.
## fallback_seed 는 봇 대국 코스의 시드다. 호출자가 대역과 시각 등으로 만든다.
## 반환: { "course": Course, "opponent": Opponent }
func take_setup(band: int, fallback_seed: String, commit_extended: bool = false) -> Dictionary:
	var record: ReplayRecord = _ready_record
	_ready_record = null
	# 늦게 온 기록은 받을 때와 대역·설정이 달라졌을 수 있다(그 사이 승리로 대역 해금, 연장 설정 변경).
	# 조건이 다른 기록은 코스 구간 수나 확약 시간이 달라 쓰지 않는다.
	if record != null and record.band == band and record.commit_extended == commit_extended:
		return {"course": record.build_course(), "opponent": Opponent.from_record(record)}

	var report: Dictionary = CourseValidator.generate_valid(fallback_seed, band)
	# 생성기는 AC-002 에서 시드 10,000건 재시드 후 통과율 100% 로 검증돼 있다.
	assert(bool(report["ok"]), "코스 생성 실패: %s" % fallback_seed)
	return {"course": report["course"], "opponent": Opponent.bot(band)}


func _on_fetch_finished(data: Dictionary) -> void:
	_pending = false
	var record: ReplayRecord = ReplayRecord.from_dict(data)
	if record != null and record.is_playable():
		_ready_record = record
