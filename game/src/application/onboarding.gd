class_name Onboarding
extends RefCounted
## 직접 선택하는 필수 체험. 성공한 단계만 저장하고 오답은 같은 문제를 다시 푼다.

const VERSION: int = 3
const COMMIT_MS: int = 0
const OPPONENT_PICKS: Array[int] = [1, 1, 0, 0, 0, 0]
const ANSWERS: Array[int] = [0, 0, 0, 0, 0, 1]
const GUIDED: Array[int] = [0, 0, 0, 0, -1, -1]
const CAPTIONS: Array[Dictionary] = [
	{"before": "ONB_PICK", "after": "ONB_GREW", "icon": ""},
	{"before": "ONB_TWO", "after": "ONB_DIFFERENT", "icon": ""},
	{"before": "ONB_BEHIND", "after": "ONB_YIELD_ME", "icon": "yield"},
	{"before": "ONB_AHEAD", "after": "ONB_BLOCKED", "icon": "blocked"},
	{"before": "ONB_CHECK_BEHIND", "after": "ONB_CHECK_OK", "icon": "yield"},
	{"before": "ONB_CHECK_AHEAD", "after": "ONB_CHECK_OK", "icon": "blocked"},
]

static func course() -> Course:
	var value: Course = Course.new()
	value.seed_text = "onboarding-v3"
	value.band = 1
	value.segments = [
		[Gate.make(Gate.Kind.ADD, 4), Gate.make(Gate.Kind.MULTIPLY, 150)] as Array[Gate],
		[Gate.make(Gate.Kind.ADD, 6), Gate.make(Gate.Kind.MULTIPLY, 150)] as Array[Gate],
		[Gate.make(Gate.Kind.MULTIPLY, 200), Gate.make(Gate.Kind.ADD, 10)] as Array[Gate],
		[Gate.make(Gate.Kind.ADD, 20), Gate.make(Gate.Kind.MULTIPLY, 150)] as Array[Gate],
		[Gate.make(Gate.Kind.MULTIPLY, 150), Gate.make(Gate.Kind.ADD, 24)] as Array[Gate],
		[Gate.make(Gate.Kind.ADD, 20), Gate.make(Gate.Kind.MULTIPLY, 150)] as Array[Gate],
	]
	return value

static func session(completed_steps: int = 0) -> DuelSession:
	var value: DuelSession = DuelSession.new(course(), Opponent.tutorial(OPPONENT_PICKS), COMMIT_MS)
	for i: int in range(clampi(completed_steps, 0, ANSWERS.size())):
		value.present_next()
		value.commit(ANSWERS[i])
	return value

static func guided_pick(index: int) -> int:
	return GUIDED[index] if index >= 0 and index < GUIDED.size() else -1

static func caption(index: int) -> Dictionary:
	return CAPTIONS[index] if index >= 0 and index < CAPTIONS.size() else {}

static func accepted(step: Dictionary) -> bool:
	return not bool(step["auto"]) and int(step["pick_me"]) == ANSWERS[int(step["segment"])]

static func retry(value: DuelSession) -> void:
	assert(value.opponent.is_tutorial() and value.phase == DuelSession.Phase.RESOLVED)
	var last: Dictionary = value.trace.pop_back()
	value.crowd_me = int(last["before_me"])
	value.crowd_opp = int(last["before_opp"])
	value.picks_me.pop_back()
	value.picks_opp.pop_back()
	value.segment_index -= 1
	value.phase = DuelSession.Phase.READY if value.segment_index < 0 else DuelSession.Phase.RESOLVED
