class_name DuelSession
extends RefCounted
## 한 판의 진행을 조정한다. 02-gdd.md 의 상태 머신을 따른다.
##
##   준비 → 구간제시 → 확약대기 → 동시공개·해소 → (남은 구간) → 구간제시
##                                            → (구간 없음) → 종료
##
## 나는 언제나 판정기의 A 쪽이고 상대는 B 쪽이다. 판정은 `DuelEngine.resolve_segment` 만 쓴다.
## 대국과 기록 재생이 같은 판정 코드를 지나야 AC-005 가 성립하기 때문이다.
##
## 시간은 스스로 재지 않고 `tick()` 으로 주입받는다. 화면은 프레임마다 경과 시간을 넘기고,
## 테스트는 원하는 만큼 시간을 흘려 확약 만료와 일시정지를 결정론적으로 검증한다.
## 해소 연출 시간은 화면이 소유한다. 화면은 연출이 끝나면 `present_next()` 를 부른다.

enum Phase { READY, COMMIT_WAIT, RESOLVED, FINISHED }

const SNAPSHOT_VERSION: int = 1

var course: Course
var opponent: Opponent
var commit_ms: int = 0
var phase: Phase = Phase.READY
var segment_index: int = -1
var remaining_ms: int = 0
var paused: bool = false
var crowd_me: int = 0
var crowd_opp: int = 0
var picks_me: Array[int] = []
var picks_opp: Array[int] = []
## 구간마다 해소 결과 1건. 화면 연출과 결과 화면의 되짚기가 이것을 읽는다.
var trace: Array[Dictionary] = []

var _rng: Pcg32


func _init(course_in: Course, opponent_in: Opponent, commit_ms_in: int) -> void:
	course = course_in
	opponent = opponent_in
	commit_ms = commit_ms_in
	crowd_me = course.start_crowd_a
	crowd_opp = course.start_crowd_b
	# 봇의 무작위 판단도 코스 시드에서 나온다. 같은 판을 다시 돌리면 같은 선택이 나와야 한다.
	_rng = Pcg32.seeded(CourseGenerator.hash_seed(course.seed_text), 0x5EED)


## 다음 구간을 제시하고 확약 대기에 들어간다. 남은 구간이 없으면 종료로 넘어가고 false 를 돌려준다.
func present_next() -> bool:
	assert(phase == Phase.READY or phase == Phase.RESOLVED)
	if segment_index + 1 >= course.segment_count():
		phase = Phase.FINISHED
		return false
	segment_index += 1
	remaining_ms = commit_ms
	phase = Phase.COMMIT_WAIT
	return true


func current_gates() -> Array[Gate]:
	return course.gates_at(segment_index)


## 경과 시간을 흘린다. 확약 시간이 끝나면 가장 왼쪽 칸이 자동 확약되고 해소 결과를 돌려준다.
## 그 외에는 빈 사전을 돌려준다.
func tick(delta_ms: int) -> Dictionary:
	if phase != Phase.COMMIT_WAIT or paused:
		return {}
	remaining_ms = maxi(0, remaining_ms - delta_ms)
	if remaining_ms > 0:
		return {}
	return _commit(DuelEngine.auto_pick(current_gates()), true)


## 한 칸을 확약한다. 확약은 되돌릴 수 없고 곧바로 동시 공개와 해소가 일어난다.
func commit(pick: int) -> Dictionary:
	if phase != Phase.COMMIT_WAIT or paused:
		return {}
	if pick < 0 or pick >= current_gates().size():
		return {}
	return _commit(pick, false)


## 확약 대기 중에만 멈춘다. 앱이 백그라운드로 가면 호출되고, 복귀하면 남은 시간부터 재개한다.
func pause() -> void:
	paused = true


func resume() -> void:
	paused = false


func is_finished() -> bool:
	return phase == Phase.FINISHED


func result() -> int:
	if crowd_me > crowd_opp:
		return DuelEngine.RESULT_A_WIN
	if crowd_opp > crowd_me:
		return DuelEngine.RESULT_B_WIN
	return DuelEngine.RESULT_DRAW


## 이 판을 남의 상대가 될 기록으로 만든다. 선택 시퀀스만 담는다(DEC-009).
func to_record(display_name: String, created_at: int) -> ReplayRecord:
	assert(is_finished())
	return ReplayRecord.make(display_name, course.band, course.seed_text, picks_me, created_at)


## 진행 중 판 저장용 스냅샷. 결과 수치 대신 내 선택만 담고 복원 때 판정을 다시 돌린다.
func to_dict() -> Dictionary:
	return {
		"version": SNAPSHOT_VERSION,
		"course": course.to_dict(),
		"opponent": opponent.to_dict(),
		"commit_ms": commit_ms,
		"picks_me": picks_me.duplicate(),
		"phase": int(phase),
		"remaining_ms": remaining_ms,
	}


static func from_dict(data: Dictionary) -> DuelSession:
	if int(data.get("version", 0)) != SNAPSHOT_VERSION:
		return null
	var opponent: Opponent = Opponent.from_dict(data["opponent"])
	if opponent == null:
		return null
	var session: DuelSession = DuelSession.new(
		Course.from_dict(data["course"]), opponent, int(data["commit_ms"])
	)
	var saved_picks: Array = data["picks_me"]
	if saved_picks.size() > session.course.segment_count():
		return null
	for raw: Variant in saved_picks:
		session.present_next()
		session.commit(int(raw))
	if int(data["phase"]) == Phase.COMMIT_WAIT and session.present_next():
		session.remaining_ms = clampi(int(data["remaining_ms"]), 1, session.commit_ms)
	return session


func _commit(pick_me: int, auto: bool) -> Dictionary:
	var gates: Array[Gate] = current_gates()
	var pick_opp: int = opponent.pick_at(segment_index, gates, crowd_opp, crowd_me, _rng)
	var step: Dictionary = DuelEngine.resolve_segment(crowd_me, crowd_opp, gates, pick_me, pick_opp)
	var entry: Dictionary = {
		"segment": segment_index,
		"pick_me": pick_me,
		"pick_opp": pick_opp,
		"before_me": crowd_me,
		"before_opp": crowd_opp,
		"me": int(step["a"]),
		"opp": int(step["b"]),
		"split": bool(step["split"]),
		"events": step["events"],
		"auto": auto,
	}
	crowd_me = int(step["a"])
	crowd_opp = int(step["b"])
	picks_me.append(pick_me)
	picks_opp.append(pick_opp)
	trace.append(entry)
	phase = Phase.RESOLVED
	return entry
