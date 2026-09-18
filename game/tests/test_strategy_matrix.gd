class_name TestStrategyMatrix
extends RefCounted
## AC-004 전략 균형.
##
## 검사하는 것은 "모든 전략이 비슷한가" 가 아니라 **읽기가 보상받는가** 다.
## 이 게임의 코어가 상대 읽기이므로, 순위를 읽는 쪽이 그냥 가장 센 칸을 집는 쪽을 이겨야 한다.
## 동시에 생각하고 고르는 쪽이 아무렇게나 고르는 쪽을 이겨야 선택에 의미가 생긴다.

const SAMPLE_COURSES: int = 20


static func run() -> TestBase:
	var t: TestBase = TestBase.new("strategy_matrix")

	_test_read_is_rewarded(t)
	_test_detects_degenerate(t)
	return t


static func _test_read_is_rewarded(t: TestBase) -> void:
	var read_fail: int = 0
	var skill_fail: int = 0
	var generate_fail: int = 0
	var worst_read: int = 100
	var worst_skill: int = 100

	for i: int in range(SAMPLE_COURSES):
		var report: Dictionary = CourseValidator.generate_valid("matrix-%d" % i, 1 + i % 5)
		if not bool(report["ok"]):
			generate_fail += 1
			continue
		var course: Course = report["course"]

		var read_reward: int = CourseValidator.head_to_head(
			course, Strategies.Kind.LEADER_AWARE, Strategies.Kind.MAX_EXPECTED
		)
		worst_read = mini(worst_read, read_reward)
		if read_reward < CourseValidator.MIN_READ_REWARD:
			read_fail += 1

		var skill_gap: int = CourseValidator.head_to_head(
			course, Strategies.Kind.MAX_EXPECTED, Strategies.Kind.RANDOM
		)
		worst_skill = mini(worst_skill, skill_gap)
		if skill_gap < CourseValidator.MIN_SKILL_GAP:
			skill_fail += 1

	t.check_eq(generate_fail, 0, "코스 %d개가 모두 검증을 통과해 생성된다" % SAMPLE_COURSES)
	t.check_eq(read_fail, 0, "읽기 보상 미달 0건 (최저 %d%%)" % worst_read)
	t.check_eq(skill_fail, 0, "선택 의미 미달 0건 (최저 %d%%)" % worst_skill)


static func _test_detects_degenerate(t: TestBase) -> void:
	# 검증기가 실제로 나쁜 코스를 걸러내는지 확인한다. 통과만 확인하면 검사기가
	# 무조건 통과시키고 있어도 알 수 없다.
	var degenerate: Course = Course.new()
	degenerate.seed_text = "degenerate"
	degenerate.band = 3
	degenerate.start_crowd_a = 12
	degenerate.start_crowd_b = 12
	degenerate.segments = []
	for _i: int in range(7):
		# 한 칸이 압도적으로 좋아 자명한 정답이 되는 구간
		var gates: Array[Gate] = [
			Gate.make(Gate.Kind.ADD, 1),
			Gate.make(Gate.Kind.ADD, 2),
			Gate.make(Gate.Kind.MULTIPLY, 260),
		]
		degenerate.segments.append(gates)

	var report: Dictionary = CourseValidator.validate(degenerate)
	t.check(not bool(report["ok"]), "자명한 정답이 있는 코스는 검증에서 걸린다")
	t.check(not (report["failures"] as Array).is_empty(), "실패 사유가 기록된다")

	# 칸이 전부 똑같으면 고를 이유가 없다. 읽기도 보상받지 않으므로 걸러져야 한다.
	var flat: Course = Course.new()
	flat.seed_text = "flat"
	flat.band = 3
	flat.start_crowd_a = 12
	flat.start_crowd_b = 12
	flat.segments = []
	for _i: int in range(7):
		var same: Array[Gate] = [
			Gate.make(Gate.Kind.ADD, 10),
			Gate.make(Gate.Kind.ADD, 10),
			Gate.make(Gate.Kind.ADD, 10),
		]
		flat.segments.append(same)
	var flat_report: Dictionary = CourseValidator.validate(flat)
	t.check(not bool(flat_report["ok"]), "선택지가 전부 같은 코스는 검증에서 걸린다")
