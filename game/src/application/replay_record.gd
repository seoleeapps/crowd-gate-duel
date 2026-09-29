class_name ReplayRecord
extends RefCounted
## 상대 기록 1건. 원격 문서 `replays/{userId}` 의 내용과 같다(06 데이터 계약).
##
## **결과 수치를 담지 않는다(DEC-009).** 최종 군중 수와 승패는 재생할 때 규칙이 다시 계산한다.
## 결과를 담으면 조작 경로가 생기고, 규칙 버전이 바뀌었을 때 원본과 재생이 어긋난다.

## 재생 규칙 버전. 판정 규칙이 바뀌면 올리고, 구 버전 기록은 그 버전의 규칙으로 재생한다(DEC-010).
const SCHEMA_VERSION: int = 1
const MAX_DISPLAY_NAME: int = 24

var schema_version: int = SCHEMA_VERSION
var display_name: String = ""
var band: int = 1
## 코스를 실제로 만든 시드. 재시드된 경우 접미사까지 포함하므로 그대로 생성하면 같은 코스가 나온다.
var course_seed: String = ""
var picks: Array[int] = []
var created_at: int = 0  ## 유닉스 초
## 확약 시간 연장(접근성, DEC-008)을 켜고 둔 기록인지. 대역 매칭에 반영한다. 판정에는 영향이 없다.
var commit_extended: bool = false


static func make(
	display_name_in: String, band_in: int, course_seed_in: String, picks_in: Array[int], created_at_in: int,
	commit_extended_in: bool = false
) -> ReplayRecord:
	var record: ReplayRecord = ReplayRecord.new()
	record.display_name = display_name_in.left(MAX_DISPLAY_NAME)
	record.band = band_in
	record.course_seed = course_seed_in
	record.picks = picks_in.duplicate()
	record.created_at = created_at_in
	record.commit_extended = commit_extended_in
	return record


func to_dict() -> Dictionary:
	return {
		"schemaVersion": schema_version,
		"displayName": display_name,
		"band": band,
		"courseSeed": course_seed,
		"picks": picks.duplicate(),
		"createdAt": created_at,
		"commitExtended": commit_extended,
	}


## 원격에서 온 문서는 신뢰하지 않는다. 형식이 하나라도 어긋나면 null 을 돌려주고 호출자는 봇으로 대체한다.
## 이 클라이언트가 모르는 규칙 버전도 재생할 수 없으므로 거부한다.
static func from_dict(data: Dictionary) -> ReplayRecord:
	if data.is_empty():
		return null
	if int(data.get("schemaVersion", 0)) != SCHEMA_VERSION:
		return null
	var seed_value: Variant = data.get("courseSeed", "")
	var picks_value: Variant = data.get("picks", [])
	if typeof(seed_value) != TYPE_STRING or str(seed_value).is_empty():
		return null
	if typeof(picks_value) != TYPE_ARRAY:
		return null
	var band_value: int = int(data.get("band", 0))
	if band_value < 1 or band_value > CourseGenerator.BANDS.size():
		return null

	var typed_picks: Array[int] = []
	for raw: Variant in picks_value:
		if typeof(raw) != TYPE_INT and typeof(raw) != TYPE_FLOAT:
			return null
		var pick: int = int(raw)
		if pick < 0 or pick > 2:
			return null
		typed_picks.append(pick)

	return ReplayRecord.make(
		str(data.get("displayName", "")),
		band_value,
		str(seed_value),
		typed_picks,
		int(data.get("createdAt", 0)),
		bool(data.get("commitExtended", false))
	)


## 이 기록을 재생할 코스. 시드와 대역만으로 결정론적으로 다시 만든다.
func build_course() -> Course:
	return CourseGenerator.generate(course_seed, band)


## 선택 수가 코스 구간 수와 맞아야 재생할 수 있다.
func is_playable() -> bool:
	return picks.size() == build_course().segment_count()
