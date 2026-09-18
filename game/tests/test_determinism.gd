class_name TestDeterminism
extends RefCounted
## AC-003 결정론. 같은 시드와 같은 선택열은 언제나 같은 결과를 낸다.
## 이 성질이 깨지면 상대 기록 재생(AC-005)과 결과 카드 재현이 동시에 무너진다.


static func run() -> TestBase:
	var t: TestBase = TestBase.new("determinism")

	_test_course_reproducible(t)
	_test_seed_dispersion(t)
	_test_play_reproducible(t)
	_test_replay_matches_live(t)
	return t


static func _test_course_reproducible(t: TestBase) -> void:
	var a: Course = CourseGenerator.generate("2026-09-18|3", 3)
	var b: Course = CourseGenerator.generate("2026-09-18|3", 3)
	t.check_eq(a.structure_hash(), b.structure_hash(), "같은 시드는 같은 코스")
	t.check_eq(a.segment_count(), b.segment_count(), "구간 수 일치")

	var other: Course = CourseGenerator.generate("2026-09-19|3", 3)
	t.check(a.structure_hash() != other.structure_hash(), "다른 시드는 다른 코스")


static func _test_seed_dispersion(t: TestBase) -> void:
	# 외부 시드를 해싱하지 않으면 날짜처럼 닮은 시드가 닮은 코스를 만든다(DEC-006).
	# 하루씩만 다른 시드 30개가 모두 서로 다른 구조를 내는지 본다.
	var seen: Dictionary = {}
	var collisions: int = 0
	for day: int in range(1, 31):
		var course: Course = CourseGenerator.generate("2026-09-%02d|2" % day, 2)
		var key: String = course.structure_hash()
		if seen.has(key):
			collisions += 1
		seen[key] = true
	t.check_eq(collisions, 0, "인접 시드 30건에서 구조 충돌 0건")


static func _test_play_reproducible(t: TestBase) -> void:
	var course: Course = CourseGenerator.generate("determinism-play", 4)
	var picks_a: Array[int] = []
	var picks_b: Array[int] = []
	for i: int in range(course.segment_count()):
		picks_a.append(i % 3)
		picks_b.append((i + 1) % 3)

	var first: Dictionary = DuelEngine.play(course, picks_a, picks_b)
	var second: Dictionary = DuelEngine.play(course, picks_a, picks_b)
	t.check_eq(int(first["a"]), int(second["a"]), "같은 선택열 재실행 A 일치")
	t.check_eq(int(first["b"]), int(second["b"]), "같은 선택열 재실행 B 일치")
	t.check_eq(int(first["result"]), int(second["result"]), "결과 일치")
	t.check_eq(int(first["splits"]), int(second["splits"]), "겹침 횟수 일치")


static func _test_replay_matches_live(t: TestBase) -> void:
	# 전략 대국으로 얻은 선택열을 기록처럼 다시 재생했을 때 원본과 일치해야 한다(AC-005 의 기반).
	var mismatches: int = 0
	for i: int in range(40):
		var course: Course = CourseGenerator.generate("replay-%d" % i, 3)
		var live: Dictionary = CourseValidator.simulate(
			course, Strategies.Kind.MAX_EXPECTED, Strategies.Kind.MIN_CONTEST, i + 1
		)
		var picks_a: Array[int] = live["picks_a"]
		var picks_b: Array[int] = live["picks_b"]
		var replayed: Dictionary = DuelEngine.play(course, picks_a, picks_b)
		if int(replayed["a"]) != int(live["a"]) or int(replayed["b"]) != int(live["b"]):
			mismatches += 1
	t.check_eq(mismatches, 0, "40판 재생 결과가 원본과 100% 일치")
