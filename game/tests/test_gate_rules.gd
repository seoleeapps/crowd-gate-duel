class_name TestGateRules
extends RefCounted
## 게이트 4종과 해소 순서의 규칙 정확성. 02-gdd.md 의 계약을 그대로 검사한다.


static func run() -> TestBase:
	var t: TestBase = TestBase.new("gate_rules")

	_test_growth(t)
	_test_split(t)
	_test_steal_and_shield(t)
	_test_flip_point(t)
	_test_floor(t)
	return t


static func _test_growth(t: TestBase) -> void:
	var mul: Gate = Gate.make(Gate.Kind.MULTIPLY, 200)
	t.check_eq(mul.growth_gain(20, false), 20, "x2.0 은 군중 20에서 +20")
	t.check_eq(mul.growth_gain(20, true), 10, "반감이면 증가분의 절반")

	var add: Gate = Gate.make(Gate.Kind.ADD, 20)
	t.check_eq(add.growth_gain(20, false), 20, "모으기는 군중 수와 무관")
	t.check_eq(add.growth_gain(20, true), 10, "모으기 반감")

	t.check_eq(Gate.make(Gate.Kind.STEAL, 20).growth_gain(50, false), 0, "빼앗기는 성장이 아니다")
	t.check_eq(Gate.make(Gate.Kind.SHIELD, 10).growth_gain(50, false), 0, "방패는 성장이 아니다")


static func _test_split(t: TestBase) -> void:
	var gates: Array[Gate] = [
		Gate.make(Gate.Kind.MULTIPLY, 200),
		Gate.make(Gate.Kind.ADD, 20),
		Gate.make(Gate.Kind.ADD, 14),
	]

	# 같은 칸을 고르면 뒤처진 쪽이 먼저 지나간다. 앞선 쪽은 아무것도 얻지 못한다.
	# 이 비대칭이 없으면 겹쳐도 격차가 그대로라 "늘 가장 센 칸"이 지배 전략이 된다.
	var behind_a: Dictionary = DuelEngine.resolve_segment(20, 40, gates, 0, 0)
	t.check(bool(behind_a["split"]), "같은 칸은 split 이다")
	t.check_eq(int(behind_a["a"]), 40, "뒤처진 A 가 x2.0 을 온전히 가져간다")
	t.check_eq(int(behind_a["b"]), 40, "앞선 B 는 아무것도 얻지 못한다")

	var behind_b: Dictionary = DuelEngine.resolve_segment(50, 30, gates, 1, 1)
	t.check_eq(int(behind_b["a"]), 50, "앞선 A 는 제자리")
	t.check_eq(int(behind_b["b"]), 50, "뒤처진 B 가 +20 을 온전히 가져간다")

	# 동수일 때만 반씩 나눈다. 우선권을 줄 기준이 없기 때문이다.
	var even: Dictionary = DuelEngine.resolve_segment(20, 20, gates, 0, 0)
	t.check_eq(int(even["a"]), 30, "동수면 A 는 증가분의 절반")
	t.check_eq(int(even["b"]), 30, "동수면 B 도 증가분의 절반")

	# 겹침이 격차를 실제로 좁히는지 본다. 이것이 추격 장치의 핵심이다.
	t.check(
		int(behind_a["b"]) - int(behind_a["a"]) < 40 - 20,
		"겹치면 격차가 줄어든다"
	)

	var diff: Dictionary = DuelEngine.resolve_segment(20, 40, gates, 0, 1)
	t.check(not bool(diff["split"]), "다른 칸은 split 이 아니다")
	t.check_eq(int(diff["a"]), 40, "A 는 x2.0 을 온전히 받는다")
	t.check_eq(int(diff["b"]), 60, "B 는 +20 을 온전히 받는다")

	# 양쪽 방패는 막을 빼앗기가 없어 아무 일도 일어나지 않는다.
	var shield_gates: Array[Gate] = [
		Gate.make(Gate.Kind.SHIELD, 10),
		Gate.make(Gate.Kind.STEAL, 20),
		Gate.make(Gate.Kind.ADD, 12),
	]
	var idle: Dictionary = DuelEngine.resolve_segment(30, 50, shield_gates, 0, 0)
	t.check_eq(int(idle["a"]), 30, "양쪽 방패는 A 변화 없음")
	t.check_eq(int(idle["b"]), 50, "양쪽 방패는 B 변화 없음")


static func _test_steal_and_shield(t: TestBase) -> void:
	var gates: Array[Gate] = [
		Gate.make(Gate.Kind.STEAL, 20),
		Gate.make(Gate.Kind.SHIELD, 10),
		Gate.make(Gate.Kind.ADD, 15),
	]

	# 빼앗기 대 성장: 상대에게서 가져온다.
	var steal: Dictionary = DuelEngine.resolve_segment(30, 50, gates, 0, 2)
	t.check_eq(int(steal["a"]), 40, "A 는 B 의 20% 인 10 을 가져온다")
	t.check_eq(int(steal["b"]), 55, "B 는 10 을 잃고 +15 를 받는다")

	# 빼앗기 대 방패: 무효화되고 방패 쪽이 반격한다.
	var blocked: Dictionary = DuelEngine.resolve_segment(30, 50, gates, 0, 1)
	t.check_eq(int(blocked["a"]), 27, "A 는 반격으로 자기 10% 인 3 을 잃는다")
	t.check_eq(int(blocked["b"]), 53, "B 는 반격으로 3 을 얻는다")

	# 방패 대 성장: 막을 것이 없으므로 방패가 손해다. 순환 우위(성장 > 방패)의 근거다.
	var wasted: Dictionary = DuelEngine.resolve_segment(30, 50, gates, 1, 2)
	t.check_eq(int(wasted["a"]), 30, "방패만 고른 A 는 제자리")
	t.check_eq(int(wasted["b"]), 65, "성장한 B 는 +15")

	# 같은 칸 빼앗기: 뒤처진 쪽이 온전히 빼앗는다. A 가 B 의 20% 인 10 을 가져간다.
	var mutual: Dictionary = DuelEngine.resolve_segment(30, 50, gates, 0, 0)
	t.check_eq(int(mutual["a"]), 40, "뒤처진 A 가 10 을 빼앗는다")
	t.check_eq(int(mutual["b"]), 40, "앞선 B 는 10 을 잃는다")

	# 동수 빼앗기는 서로 절반 비율이라 상쇄된다.
	var even_steal: Dictionary = DuelEngine.resolve_segment(40, 40, gates, 0, 0)
	t.check_eq(int(even_steal["a"]), 40, "동수 빼앗기는 A 상쇄")
	t.check_eq(int(even_steal["b"]), 40, "동수 빼앗기는 B 상쇄")


static func _test_flip_point(t: TestBase) -> void:
	# 불리기와 모으기의 우열이 군중 수에 따라 뒤집힌다. 이 게임의 2차 판단 장치다.
	var mul: Gate = Gate.make(Gate.Kind.MULTIPLY, 200)
	var add: Gate = Gate.make(Gate.Kind.ADD, 20)
	t.check(add.growth_gain(10, false) > mul.growth_gain(10, false), "군중 10에서는 모으기가 크다")
	t.check(mul.growth_gain(30, false) > add.growth_gain(30, false), "군중 30에서는 불리기가 크다")
	t.check_eq(mul.growth_gain(20, false), add.growth_gain(20, false), "군중 20이 전환점이다")


static func _test_floor(t: TestBase) -> void:
	# 군중 1 처럼 극단적으로 낮은 상태에서도 판정이 깨지지 않고 하한이 지켜진다.
	# 현재 수치 범위에서는 한 구간 최대 손실이 25% 라 실제로 0 이 되지는 않지만,
	# 규칙을 넓힐 때를 대비해 하한을 계약으로 둔다.
	var gates: Array[Gate] = [
		Gate.make(Gate.Kind.STEAL, 25),
		Gate.make(Gate.Kind.ADD, 10),
		Gate.make(Gate.Kind.MULTIPLY, 180),
	]
	for pick_a: int in range(3):
		for pick_b: int in range(3):
			var low: Dictionary = DuelEngine.resolve_segment(1, 1, gates, pick_a, pick_b)
			t.check(
				int(low["a"]) >= DuelEngine.MIN_CROWD and int(low["b"]) >= DuelEngine.MIN_CROWD,
				"군중 1 에서 (%d,%d) 조합이 하한을 지킨다" % [pick_a, pick_b]
			)
