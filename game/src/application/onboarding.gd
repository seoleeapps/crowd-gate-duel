class_name Onboarding
extends RefCounted
## 온보딩 대국(SCR-004). 3구간 고정 코스와 미리 정한 연습 상대의 선택.
##
## 설계 목표는 "같은 길을 고르면 뒤처진 쪽이 먼저 지나간다"를 문장이 아니라 사건으로 겪게 하는 것이다.
##   1구간: 2칸. 손이 모으기 +4 를 가리키고 그 칸만 누를 수 있다. 상대는 불리기 x1.5 로 18 이 되어
##          나는 16 으로 뒤처진다. 누르면 무리가 불어난다는 인과만 배운다
##   2구간: 손이 불리기 x2 를 가리킨다. 상대도 같은 칸을 고른다. 뒤처진 내가 온전히 가져가
##          32 대 18 이 된다. 온보딩의 핵심 순간이다(AC-001)
##   3구간: 3칸 자유 선택. 이번엔 내가 앞서 있다. 상대가 노리는 모으기 +16 을 같이 고르면
##          뒤처진 상대가 먼저 지나가 34 대 32 로 역전된다. 나머지 칸을 고르면 이긴다
## 시간이 다 되면 가장 왼쪽 칸이 자동 선택되므로 안내 칸은 늘 가장 왼쪽에 둔다.

const COMMIT_MS: int = 4000
const OPPONENT_PICKS: Array[int] = [1, 0, 1]
## 구간별로 손이 가리키는 칸. -1 이면 자유 선택이다.
const GUIDED: Array[int] = [0, 0, -1]


static func course() -> Course:
	var course: Course = Course.new()
	course.seed_text = "onboarding-v1"
	course.band = 1
	course.segments = [
		[Gate.make(Gate.Kind.ADD, 4), Gate.make(Gate.Kind.MULTIPLY, 150)] as Array[Gate],
		[
			Gate.make(Gate.Kind.MULTIPLY, 200),
			Gate.make(Gate.Kind.ADD, 10),
			Gate.make(Gate.Kind.STEAL, 15),
		] as Array[Gate],
		[
			Gate.make(Gate.Kind.MULTIPLY, 150),
			Gate.make(Gate.Kind.ADD, 16),
			Gate.make(Gate.Kind.STEAL, 20),
		] as Array[Gate],
	]
	return course


static func session() -> DuelSession:
	return DuelSession.new(course(), Opponent.tutorial(OPPONENT_PICKS), COMMIT_MS)


static func guided_pick(segment_index: int) -> int:
	return GUIDED[segment_index] if segment_index < GUIDED.size() else -1
