class_name CourseValidator
extends RefCounted
## 생성된 코스가 대전으로 성립하는지 검사한다. 하나라도 실패하면 생성기가 재시드한다.
##
## 가장 중요한 조건은 C1 이다. **상대의 순위를 읽는 전략이 그냥 가장 센 칸을 집는 전략을
## 이겨야 한다.** 이 게임의 코어가 "상대를 읽는다" 이므로, 읽기가 보상받지 않으면 제품이
## 성립하지 않는다.
##
## 초기에는 "어떤 고정 전략도 평균 승률 60% 를 넘지 않는다"를 기준으로 삼았으나 이는
## 달성 불가능한 요구였다. 겹치지 않는 한 큰 칸이 유리한데 서로 다른 고정 전략은 잘 겹치지
## 않으므로, 좋은 전략이 나쁜 전략을 크게 이기는 것은 결함이 아니라 정상이다. 그래서 기준을
## "전략 간 균등"이 아니라 "읽기의 보상"과 "선택의 의미"로 바꿨다.

## 순위 인식이 탐욕을 상대로 최소한 대등해야 한다. 압도까지 요구하지 않는 이유는
## 순위가 바뀌면 유인도 뒤집혀 두 전략이 서로 주고받으며 균형점에 수렴하기 때문이다.
## 실측에서 이 값은 50% 부근에 모였는데, 이는 읽기가 무의미하다는 뜻이 아니라
## 밸런스가 잡혀 있다는 뜻이다. 그래서 "지지 않는다"를 기준으로 삼는다.
const MIN_READ_REWARD: int = 48
const MIN_SKILL_GAP: int = 55  ## 탐욕이 무작위를 상대로 내야 하는 최소 승률(%)
## 우선권 규칙이 실제로 발동하는지 직접 본다. 겹침이 없으면 이 게임의 코어 규칙이
## 한 번도 쓰이지 않은 채 판이 끝난다는 뜻이다.
const MIN_SPLIT_PER_DUEL_X100: int = 60
const MAX_STRATEGY_WINRATE: int = 60  ## 참고 지표. 합격 판정에는 쓰지 않는다
const MAX_DRAW_RATE: int = 8  ## 퍼센트
const MAX_EXPECTED_RATIO: int = 3  ## 성장 칸 기대값 최대/최소 비
const MIN_FLIP_RATIO: int = 30  ## 우열 역전 가능 구간 비율(퍼센트)
const ROUNDS_PER_PAIR: int = 4

## 역전 판단 폭. 전환점이 그 구간의 예상 군중 대비 이 배율 범위에 들면 역전 가능으로 본다.
## 예상 군중은 구간마다 커지므로 고정 범위가 아니라 구간별로 계산한다.
const FLIP_LOW_PCT: int = 40
const FLIP_HIGH_PCT: int = 250


## 반환: { "ok": bool, "failures": Array[String], "stats": Dictionary }
static func validate(course: Course) -> Dictionary:
	var failures: Array[String] = []
	var stats: Dictionary = {}

	if not _check_shape(course, failures):
		return {"ok": false, "failures": failures, "stats": stats}

	# C1 읽기의 보상: 순위를 읽는 쪽이 그냥 센 칸을 집는 쪽을 이겨야 한다.
	var read_reward: int = head_to_head(
		course, Strategies.Kind.LEADER_AWARE, Strategies.Kind.MAX_EXPECTED
	)
	stats["read_reward"] = read_reward
	if read_reward < MIN_READ_REWARD:
		failures.append("C1 읽기 보상 부족: 순위 인식이 탐욕 상대 승률 %d%%" % read_reward)

	# C1b 선택의 의미: 생각하고 고르는 쪽이 아무렇게나 고르는 쪽을 이겨야 한다.
	var skill_gap: int = head_to_head(
		course, Strategies.Kind.MAX_EXPECTED, Strategies.Kind.RANDOM
	)
	stats["skill_gap"] = skill_gap
	if skill_gap < MIN_SKILL_GAP:
		failures.append("C1b 선택 의미 부족: 탐욕이 무작위 상대 승률 %d%%" % skill_gap)

	# C6 우선권 발동: 겹침이 아예 없으면 코어 규칙이 쓰이지 않은 것이다.
	var split_x100: int = split_rate_x100(course)
	stats["split_x100"] = split_x100
	if split_x100 < MIN_SPLIT_PER_DUEL_X100:
		failures.append("C6 겹침 부족: 판당 평균 %d.%02d회" % [split_x100 / 100, split_x100 % 100])

	var matrix: Dictionary = strategy_matrix(course)
	stats["winrate"] = matrix["winrate"]
	stats["draw_rate"] = matrix["draw_rate"]

	var draw_rate: int = int(matrix["draw_rate"])
	if draw_rate >= MAX_DRAW_RATE:
		failures.append("C2 무승부율 %d%%" % draw_rate)

	var ratio_fail: int = _check_expected_ratio(course)
	if ratio_fail >= 0:
		failures.append("C3 구간 %d 의 성장 칸 기대값 비가 %d배를 넘는다" % [ratio_fail, MAX_EXPECTED_RATIO])

	var flip_ratio: int = flip_segment_ratio(course)
	stats["flip_ratio"] = flip_ratio
	if flip_ratio < MIN_FLIP_RATIO:
		failures.append("C5 우열 역전 가능 구간 %d%%" % flip_ratio)

	return {"ok": failures.is_empty(), "failures": failures, "stats": stats}


static func _check_shape(course: Course, failures: Array[String]) -> bool:
	if course.segment_count() <= 0:
		failures.append("C4 구간이 없다")
		return false
	for i: int in range(course.segment_count()):
		var gates: Array[Gate] = course.gates_at(i)
		if gates.size() != 3:
			failures.append("C4 구간 %d 의 칸이 %d개다" % [i, gates.size()])
			return false
		var steals: int = 0
		var shields: int = 0
		for gate: Gate in gates:
			if gate.kind == Gate.Kind.STEAL:
				steals += 1
			elif gate.kind == Gate.Kind.SHIELD:
				shields += 1
		if steals > 1:
			failures.append("C4 구간 %d 에 빼앗기가 2칸 이상이다" % i)
			return false
		if shields > 1:
			failures.append("C4 구간 %d 에 방패가 2칸 이상이다" % i)
			return false
		if shields > 0 and steals == 0:
			failures.append("C4 구간 %d 에 막을 빼앗기 없이 방패만 있다" % i)
			return false
	return true


## 전략들을 서로 붙여 승률 행렬을 만든다.
## 기본 대상은 순위를 보지 않는 전략들이다. 순위를 읽는 전략이 이들을 이기는 것은
## 결함이 아니라 설계 의도이므로 코스 합격 판정에 넣지 않는다.
## 반환: { "winrate": Array[int](전략별 평균 승률 %), "draw_rate": int, "pairs": Array, "kinds": Array }
static func strategy_matrix(course: Course, kinds_in: Array = []) -> Dictionary:
	var kinds: Array = Strategies.rank_blind() if kinds_in.is_empty() else kinds_in
	var wins: Array[int] = []
	var games: Array[int] = []
	for _i: int in range(kinds.size()):
		wins.append(0)
		games.append(0)

	var draws: int = 0
	var total: int = 0
	var pairs: Array = []

	for a: int in range(kinds.size()):
		for b: int in range(kinds.size()):
			if a == b:
				continue
			# 무작위가 끼지 않은 쌍은 결정론이라 몇 번을 돌려도 같은 결과가 나온다.
			# 한 번만 돌려 검증 비용을 5배 가까이 줄인다.
			var is_random_pair: bool = (
				kinds[a] == Strategies.Kind.RANDOM or kinds[b] == Strategies.Kind.RANDOM
			)
			var rounds: int = ROUNDS_PER_PAIR if is_random_pair else 1
			var a_score: int = 0
			for r: int in range(rounds):
				var outcome: int = simulate(course, kinds[a], kinds[b], r + 1)["result"]
				total += 1
				games[a] += 1
				if outcome == DuelEngine.RESULT_A_WIN:
					wins[a] += 2
					a_score += 2
				elif outcome == DuelEngine.RESULT_DRAW:
					wins[a] += 1
					a_score += 1
					draws += 1
			pairs.append({"a": a, "b": b, "score": a_score, "rounds": rounds})

	var winrate: Array[int] = []
	for i: int in range(kinds.size()):
		# 승 2점 무 1점이므로 만점은 경기수 x 2 다.
		winrate.append(0 if games[i] == 0 else wins[i] * 100 / (games[i] * 2))

	return {
		"winrate": winrate,
		"draw_rate": 0 if total == 0 else draws * 100 / total,
		"pairs": pairs,
		"kinds": kinds,
	}


## 대표 전략 조합에서 한 판당 겹침이 평균 몇 번 일어나는지 본다(x100 정수).
static func split_rate_x100(course: Course) -> int:
	var pairs: Array = [
		[Strategies.Kind.LEADER_AWARE, Strategies.Kind.MAX_EXPECTED],
		[Strategies.Kind.MAX_EXPECTED, Strategies.Kind.ALWAYS_ADD],
		[Strategies.Kind.ALWAYS_MULTIPLY, Strategies.Kind.MAX_EXPECTED],
		[Strategies.Kind.LEADER_AWARE, Strategies.Kind.MIRROR],
	]
	var splits: int = 0
	var duels: int = 0
	for pair: Array in pairs:
		var run: Dictionary = simulate(course, pair[0], pair[1], 1)
		var picks_a: Array[int] = run["picks_a"]
		var picks_b: Array[int] = run["picks_b"]
		for i: int in range(picks_a.size()):
			if picks_a[i] == picks_b[i]:
				splits += 1
		duels += 1
	return 0 if duels == 0 else splits * 100 / duels


## 두 전략을 맞대결시켜 첫 번째 전략의 승률(%)을 낸다.
## 자리 편향을 없애려고 A/B 를 바꿔가며 양방향으로 돌린다. 무승부는 0.5승으로 센다.
static func head_to_head(
	course: Course, kind_a: Strategies.Kind, kind_b: Strategies.Kind, rounds: int = ROUNDS_PER_PAIR
) -> int:
	var score: int = 0
	var games: int = 0
	for r: int in range(rounds):
		var forward: int = int(simulate(course, kind_a, kind_b, r + 1)["result"])
		games += 1
		if forward == DuelEngine.RESULT_A_WIN:
			score += 2
		elif forward == DuelEngine.RESULT_DRAW:
			score += 1

		var reverse: int = int(simulate(course, kind_b, kind_a, r + 1)["result"])
		games += 1
		if reverse == DuelEngine.RESULT_B_WIN:
			score += 2
		elif reverse == DuelEngine.RESULT_DRAW:
			score += 1
	return 0 if games == 0 else score * 100 / (games * 2)


## 두 전략을 붙여 한 판을 돌린다. 결정론이므로 같은 인자는 같은 결과를 낸다.
static func simulate(course: Course, kind_a: Strategies.Kind, kind_b: Strategies.Kind, salt: int) -> Dictionary:
	var rng_a: Pcg32 = Pcg32.seeded(CourseGenerator.hash_seed(course.seed_text) + salt, 11)
	var rng_b: Pcg32 = Pcg32.seeded(CourseGenerator.hash_seed(course.seed_text) + salt, 22)
	var crowd_a: int = course.start_crowd_a
	var crowd_b: int = course.start_crowd_b
	var picks_a: Array[int] = []
	var picks_b: Array[int] = []

	for i: int in range(course.segment_count()):
		var gates: Array[Gate] = course.gates_at(i)
		var pa: int = Strategies.pick(kind_a, gates, crowd_a, crowd_b, rng_a)
		var pb: int = Strategies.pick(kind_b, gates, crowd_b, crowd_a, rng_b)
		picks_a.append(pa)
		picks_b.append(pb)
		var step: Dictionary = DuelEngine.resolve_segment(crowd_a, crowd_b, gates, pa, pb)
		crowd_a = int(step["a"])
		crowd_b = int(step["b"])

	var result: int = DuelEngine.RESULT_DRAW
	if crowd_a > crowd_b:
		result = DuelEngine.RESULT_A_WIN
	elif crowd_b > crowd_a:
		result = DuelEngine.RESULT_B_WIN

	return {"a": crowd_a, "b": crowd_b, "result": result, "picks_a": picks_a, "picks_b": picks_b}


## 기대값 비가 한계를 넘는 첫 구간 인덱스. 없으면 -1.
static func _check_expected_ratio(course: Course) -> int:
	for i: int in range(course.segment_count()):
		var gates: Array[Gate] = course.gates_at(i)
		var lo: int = 0x7FFFFFFF
		var hi: int = 0
		var scale: int = CourseGenerator.expected_crowd_at(i)
		for gate: Gate in gates:
			if not gate.is_growth():
				continue
			var gain: int = Strategies.expected_gain(gate, scale, scale)
			lo = mini(lo, gain)
			hi = maxi(hi, gain)
		if hi <= 0 or lo == 0x7FFFFFFF or lo <= 0:
			continue
		if hi > lo * MAX_EXPECTED_RATIO:
			return i
	return -1


## 불리기와 모으기의 우열이 뒤집히는 구간 비율(퍼센트).
## 전환점 crowd* = add * 100 / (multiply - 100) 이 한 판의 군중 범위 안에 들면 역전 가능이다.
static func flip_segment_ratio(course: Course) -> int:
	var total: int = course.segment_count()
	if total == 0:
		return 0
	var flips: int = 0
	for i: int in range(total):
		var gates: Array[Gate] = course.gates_at(i)
		var scale: int = CourseGenerator.expected_crowd_at(i)
		var low: int = scale * FLIP_LOW_PCT / 100
		var high: int = scale * FLIP_HIGH_PCT / 100
		var has_flip: bool = false
		for mul: Gate in gates:
			if mul.kind != Gate.Kind.MULTIPLY or mul.value <= 100:
				continue
			for add: Gate in gates:
				if add.kind != Gate.Kind.ADD:
					continue
				var pivot: int = add.value * 100 / (mul.value - 100)
				if pivot >= low and pivot <= high:
					has_flip = true
		if has_flip:
			flips += 1
	return flips * 100 / total


## 검증을 통과할 때까지 재시드하며 코스를 만든다.
## 반환: { "course": Course, "attempts": int, "ok": bool, "failures": Array[String] }
static func generate_valid(seed_text: String, band: int, max_attempts: int = 40) -> Dictionary:
	var last: Dictionary = {}
	for attempt: int in range(max_attempts):
		var salted: String = seed_text if attempt == 0 else "%s#%d" % [seed_text, attempt]
		var course: Course = CourseGenerator.generate(salted, band)
		var report: Dictionary = validate(course)
		last = report
		if bool(report["ok"]):
			return {
				"course": course,
				"attempts": attempt + 1,
				"ok": true,
				"failures": [] as Array[String],
			}
	return {
		"course": null,
		"attempts": max_attempts,
		"ok": false,
		"failures": last.get("failures", [] as Array[String]),
	}
