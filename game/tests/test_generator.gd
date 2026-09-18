class_name TestGenerator
extends RefCounted
## AC-002 생성기 건전성. 검증기를 통과한 코스만 대국에 나간다.
##
## 프로토타입 단계에서는 시드 120건으로 돌린다. 10,000건 전수 검증은 헤드리스 테스트가
## 아니라 별도 진입점(scripts/validate_courses.sh)에서 돌린다. 여기서는 회귀를 잡는 것이 목적이다.

const SAMPLE_SEEDS: int = 120


static func run() -> TestBase:
	var t: TestBase = TestBase.new("generator")

	_test_shape(t)
	_test_band_table(t)
	_test_valid_generation(t)
	return t


static func _test_shape(t: TestBase) -> void:
	var bad_shape: int = 0
	var lone_shield: int = 0
	var multi_special: int = 0

	for i: int in range(SAMPLE_SEEDS):
		var course: Course = CourseGenerator.generate("shape-%d" % i, 1 + i % 5)
		for s: int in range(course.segment_count()):
			var gates: Array[Gate] = course.gates_at(s)
			if gates.size() != 3:
				bad_shape += 1
			var steals: int = 0
			var shields: int = 0
			for gate: Gate in gates:
				if gate.kind == Gate.Kind.STEAL:
					steals += 1
				elif gate.kind == Gate.Kind.SHIELD:
					shields += 1
			if shields > 0 and steals == 0:
				lone_shield += 1
			if steals > 1 or shields > 1:
				multi_special += 1

	t.check_eq(bad_shape, 0, "모든 구간이 3칸")
	t.check_eq(lone_shield, 0, "막을 빼앗기 없는 방패 구간 0건")
	t.check_eq(multi_special, 0, "구간당 빼앗기·방패는 각각 최대 1칸")


static func _test_band_table(t: TestBase) -> void:
	var expected_segments: Array[int] = [5, 6, 7, 8, 9]
	for band: int in range(1, 6):
		var course: Course = CourseGenerator.generate("band-%d" % band, band)
		t.check_eq(course.segment_count(), expected_segments[band - 1], "대역 %d 구간 수" % band)
		t.check_eq(course.band, band, "대역 %d 기록" % band)
		t.check_eq(course.start_crowd_a, course.start_crowd_b, "대역 %d 시작 군중 대칭" % band)

	# 대역 1 은 특수 게이트가 없어야 한다. 순서 규칙만 배우는 구간이기 때문이다.
	var specials: int = 0
	for i: int in range(60):
		var course1: Course = CourseGenerator.generate("band1-%d" % i, 1)
		for s: int in range(course1.segment_count()):
			for gate: Gate in course1.gates_at(s):
				if gate.kind == Gate.Kind.STEAL or gate.kind == Gate.Kind.SHIELD:
					specials += 1
	t.check_eq(specials, 0, "대역 1 에는 특수 게이트가 없다")


static func _test_valid_generation(t: TestBase) -> void:
	var failed: int = 0
	var total_attempts: int = 0
	var worst_attempts: int = 0
	var first_failure: String = ""

	for i: int in range(SAMPLE_SEEDS):
		var band: int = 1 + i % 5
		var report: Dictionary = CourseValidator.generate_valid("gen-%d" % i, band)
		total_attempts += int(report["attempts"])
		worst_attempts = maxi(worst_attempts, int(report["attempts"]))
		if not bool(report["ok"]):
			failed += 1
			if first_failure.is_empty():
				var reasons: Array = report["failures"]
				first_failure = "gen-%d(band %d): %s" % [i, band, ", ".join(reasons)]

	t.check_eq(failed, 0, "시드 %d건 최종 통과율 100%% (첫 실패: %s)" % [SAMPLE_SEEDS, first_failure])
	# 재시드가 과하면 생성 비용 예산(50ms)을 넘긴다. 평균 시도 수를 함께 지킨다.
	var avg_x100: int = total_attempts * 100 / SAMPLE_SEEDS
	t.check(avg_x100 <= 400, "평균 재시도 4회 이하 (실측 %d.%02d회)" % [avg_x100 / 100, avg_x100 % 100])
	t.check(worst_attempts < 40, "최악 시도 수가 상한 미만 (실측 %d회)" % worst_attempts)
