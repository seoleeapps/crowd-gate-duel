class_name Strategies
extends RefCounted
## 밸런스 검증용 고정 전략 6종.
##
## 이 전략들은 상품 기능이 아니라 **생성기 검증 도구**다. 어떤 전략도 다른 전략들을 상대로
## 평균 승률 60% 를 넘지 못해야 코스가 통과한다(AC-004). 하나라도 넘으면 그 코스에는
## 자명한 정답이 있다는 뜻이고, 그러면 상대를 읽을 이유가 사라져 게임이 성립하지 않는다.

enum Kind {
	ALWAYS_MULTIPLY,  ## 늘 불리기를 고른다
	ALWAYS_ADD,  ## 늘 모으기를 고른다
	MAX_EXPECTED,  ## 내 기대 이득이 가장 큰 칸
	MIN_CONTEST,  ## 기대 이득이 가장 작은 칸. 겹침을 피하려는 극단
	RANDOM,  ## 균등 무작위
	MIRROR,  ## 상대 기준 최선을 고른다. 겹침을 감수하고 따라가는 극단
	LEADER_AWARE,  ## 순위를 보고 겹침을 노리거나 피한다. 사람의 합리적 플레이에 가장 가깝다
}


## 순위를 보지 않는 전략들. 코스 검증(C1)은 이 집합만 대상으로 한다.
## 순위를 읽는 전략이 이들을 이기는 것은 결함이 아니라 설계 의도다.
static func rank_blind() -> Array[Kind]:
	return [
		Kind.ALWAYS_MULTIPLY,
		Kind.ALWAYS_ADD,
		Kind.MAX_EXPECTED,
		Kind.MIN_CONTEST,
		Kind.RANDOM,
		Kind.MIRROR,
	]


static func all() -> Array[Kind]:
	return [
		Kind.ALWAYS_MULTIPLY,
		Kind.ALWAYS_ADD,
		Kind.MAX_EXPECTED,
		Kind.MIN_CONTEST,
		Kind.RANDOM,
		Kind.MIRROR,
		Kind.LEADER_AWARE,
	]


static func display_name(kind: Kind) -> String:
	match kind:
		Kind.ALWAYS_MULTIPLY:
			return "항상 불리기"
		Kind.ALWAYS_ADD:
			return "항상 모으기"
		Kind.MAX_EXPECTED:
			return "기대값 최대"
		Kind.MIN_CONTEST:
			return "경합 회피"
		Kind.RANDOM:
			return "무작위"
		Kind.MIRROR:
			return "상대 추종"
		Kind.LEADER_AWARE:
			return "순위 인식"
	return "알수없음"


## 한 칸을 골랐을 때 기대되는 순이득. 상대의 선택을 모르므로 근사값이며 전략 판단에만 쓴다.
## 방패는 상대가 빼앗기를 고를 때만 값이 생기므로 3칸 중 1칸이라 보고 1/3 로 깎는다.
static func expected_gain(gate: Gate, crowd_me: int, crowd_opp: int) -> int:
	match gate.kind:
		Gate.Kind.MULTIPLY:
			return crowd_me * (gate.value - 100) / 100
		Gate.Kind.ADD:
			return gate.value
		Gate.Kind.STEAL:
			return crowd_opp * gate.value / 100
		Gate.Kind.SHIELD:
			return crowd_me * gate.value / 100 / 3
	return 0


static func pick(
	kind: Kind, gates: Array[Gate], crowd_me: int, crowd_opp: int, rng: Pcg32
) -> int:
	match kind:
		Kind.ALWAYS_MULTIPLY:
			return _first_of_kind(gates, Gate.Kind.MULTIPLY, crowd_me, crowd_opp)
		Kind.ALWAYS_ADD:
			return _first_of_kind(gates, Gate.Kind.ADD, crowd_me, crowd_opp)
		Kind.MAX_EXPECTED:
			return _extreme(gates, crowd_me, crowd_opp, true)
		Kind.MIN_CONTEST:
			return _extreme(gates, crowd_me, crowd_opp, false)
		Kind.RANDOM:
			return rng.next_below(gates.size())
		Kind.MIRROR:
			# 상대 입장에서 가장 좋은 칸. 내 이득이 아니라 상대의 이득 기준이다.
			return _extreme(gates, crowd_opp, crowd_me, true)
		Kind.LEADER_AWARE:
			return _leader_aware(gates, crowd_me, crowd_opp)
	return 0


## 뒤처져 있으면 상대가 고를 칸을 노려 우선권으로 가로챈다.
## 앞서 있으면 그 칸을 피해 내 기준 차선을 온전히 먹는다.
static func _leader_aware(gates: Array[Gate], crowd_me: int, crowd_opp: int) -> int:
	var opp_best: int = _extreme(gates, crowd_opp, crowd_me, true)
	if crowd_me < crowd_opp:
		return opp_best
	if crowd_me == crowd_opp:
		return _extreme(gates, crowd_me, crowd_opp, true)
	var best: int = -1
	var best_gain: int = -0x7FFFFFFF
	for i: int in range(gates.size()):
		if i == opp_best:
			continue
		var gain: int = expected_gain(gates[i], crowd_me, crowd_opp)
		if gain > best_gain:
			best_gain = gain
			best = i
	return best if best >= 0 else opp_best


static func _first_of_kind(
	gates: Array[Gate], want: Gate.Kind, crowd_me: int, crowd_opp: int
) -> int:
	var best: int = -1
	var best_gain: int = -0x7FFFFFFF
	for i: int in range(gates.size()):
		if gates[i].kind == want:
			var gain: int = expected_gain(gates[i], crowd_me, crowd_opp)
			if gain > best_gain:
				best_gain = gain
				best = i
	if best >= 0:
		return best
	# 원하는 종류가 없으면 기대값 최대로 물러선다.
	return _extreme(gates, crowd_me, crowd_opp, true)


## 동점이면 낮은 인덱스를 고른다. 결정론을 위해 타이브레이크를 고정한다.
static func _extreme(gates: Array[Gate], crowd_me: int, crowd_opp: int, want_max: bool) -> int:
	var best: int = 0
	var best_gain: int = expected_gain(gates[0], crowd_me, crowd_opp)
	for i: int in range(1, gates.size()):
		var gain: int = expected_gain(gates[i], crowd_me, crowd_opp)
		if (want_max and gain > best_gain) or ((not want_max) and gain < best_gain):
			best_gain = gain
			best = i
	return best
