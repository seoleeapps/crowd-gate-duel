class_name Onboarding
extends RefCounted
## 온보딩 대국(SCR-004). 5구간 고정 코스와 미리 정한 연습 상대의 선택, 구간별 자막.
##
## 한 구간에 한 가지만 겪게 한다(DEC-017). 겹침 규칙은 두 방향을 모두 겪어야 이해된다.
##   1구간: 손이 +4 를 가리킨다. 누르면 무리가 불어난다. 상대는 x1.5 로 18, 나는 16
##   2구간: 서로 다른 칸. 각자 자기 칸을 가져간다. 22 대 27
##   3구간: 같은 칸, 내가 뒤처짐. 내가 x2 를 온전히 가져가 44 대 27 (멈춤·강조, AC-001)
##   4구간: 같은 칸, 내가 앞섬. 뒤처진 상대가 +20 을 가져가 44 대 47 (멈춤·강조)
##   5구간: 자유 선택. 나는 뒤처져 있다. 상대가 고르는 x1.5 를 같이 골라야만 이긴다
##          (x1.5 → 66 대 47 승, +24 → 68 대 70 패, 빼앗기 → 53 대 61 패)
## 시간이 다 되면 가장 왼쪽 칸이 자동 선택되므로 안내 칸과 5구간의 이기는 칸을 가장 왼쪽에 둔다.

const COMMIT_MS: int = 4000
const OPPONENT_PICKS: Array[int] = [1, 1, 0, 0, 0]
## 구간별로 손이 가리키는 칸. -1 이면 자유 선택이다.
const GUIDED: Array[int] = [0, 0, 0, 0, -1]
## 구간별 자막. before 는 고르기 전, after 는 해소 뒤에 보인다. focus 면 해소를 느리게 보여 주고
## 겹친 칸을 강조한 뒤 탭하거나 잠시 기다려야 넘어간다. icon 은 자막 옆 표식이다.
const CAPTIONS: Array[Dictionary] = [
	{"before": "ONB_PICK", "after": "", "focus": false, "icon": ""},
	{"before": "", "after": "ONB_DIFFERENT", "focus": false, "icon": ""},
	{"before": "", "after": "ONB_YIELD_ME", "focus": true, "icon": "yield"},
	{"before": "", "after": "ONB_BLOCKED", "focus": true, "icon": "blocked"},
	{"before": "ONB_AIM", "after": "", "focus": false, "icon": ""},
]


static func course() -> Course:
	var course: Course = Course.new()
	course.seed_text = "onboarding-v2"
	course.band = 1
	course.segments = [
		[Gate.make(Gate.Kind.ADD, 4), Gate.make(Gate.Kind.MULTIPLY, 150)] as Array[Gate],
		[Gate.make(Gate.Kind.ADD, 6), Gate.make(Gate.Kind.MULTIPLY, 150)] as Array[Gate],
		[Gate.make(Gate.Kind.MULTIPLY, 200), Gate.make(Gate.Kind.ADD, 10)] as Array[Gate],
		[Gate.make(Gate.Kind.ADD, 20), Gate.make(Gate.Kind.MULTIPLY, 150)] as Array[Gate],
		[
			Gate.make(Gate.Kind.MULTIPLY, 150),
			Gate.make(Gate.Kind.ADD, 24),
			Gate.make(Gate.Kind.STEAL, 20),
		] as Array[Gate],
	]
	return course


static func session() -> DuelSession:
	return DuelSession.new(course(), Opponent.tutorial(OPPONENT_PICKS), COMMIT_MS)


static func guided_pick(segment_index: int) -> int:
	return GUIDED[segment_index] if segment_index < GUIDED.size() else -1


static func caption(segment_index: int) -> Dictionary:
	return CAPTIONS[segment_index] if segment_index < CAPTIONS.size() else {}
