extends SceneTree
## 전략 승률 행렬 출력 (AC-004 참고 지표).
##   godot --headless --path game --script res://tools/strategy_matrix.gd -- --courses 40
##
## 합격 판정은 읽기 보상(C1)과 선택 의미(C1b)가 한다. 이 행렬은 밸런스 회귀를 눈으로
## 확인하기 위한 참고 자료다.

const DEFAULT_COURSES: int = 40


func _initialize() -> void:
	var courses: int = DEFAULT_COURSES
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for i: int in range(args.size()):
		if args[i] == "--courses" and i + 1 < args.size():
			courses = maxi(1, int(args[i + 1]))

	var kinds: Array = Strategies.all()
	var totals: Array[int] = []
	for _k: int in range(kinds.size()):
		totals.append(0)

	var read_min: int = 100
	var skill_min: int = 100
	var counted: int = 0

	for i: int in range(courses):
		var report: Dictionary = CourseValidator.generate_valid("matrix-bulk-%d" % i, 1 + i % 5)
		if not bool(report["ok"]):
			continue
		var course: Course = report["course"]
		counted += 1
		var matrix: Dictionary = CourseValidator.strategy_matrix(course, kinds)
		var rates: Array = matrix["winrate"]
		for k: int in range(rates.size()):
			totals[k] += int(rates[k])
		read_min = mini(read_min, CourseValidator.head_to_head(
			course, Strategies.Kind.LEADER_AWARE, Strategies.Kind.MAX_EXPECTED
		))
		skill_min = mini(skill_min, CourseValidator.head_to_head(
			course, Strategies.Kind.MAX_EXPECTED, Strategies.Kind.RANDOM
		))

	print("[matrix] 코스 %d개 평균 승률" % counted)
	for k: int in range(kinds.size()):
		var avg: int = 0 if counted == 0 else totals[k] / counted
		print("  %-10s %3d%%" % [Strategies.display_name(kinds[k]), avg])
	print("[matrix] 읽기 보상 최저 %d%% (기준 %d%%)" % [read_min, CourseValidator.MIN_READ_REWARD])
	print("[matrix] 선택 의미 최저 %d%% (기준 %d%%)" % [skill_min, CourseValidator.MIN_SKILL_GAP])
	quit(0)
