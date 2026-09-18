extends SceneTree
## 코스 생성기 대량 검증 (AC-002).
##   godot --headless --path game --script res://tools/validate_courses.gd -- --seeds 10000
##
## 헤드리스 테스트는 회귀만 잡는 표본으로 돌고, 전수 검증은 이 진입점이 담당한다.

const DEFAULT_SEEDS: int = 10000


func _initialize() -> void:
	var seeds: int = DEFAULT_SEEDS
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for i: int in range(args.size()):
		if args[i] == "--seeds" and i + 1 < args.size():
			seeds = maxi(1, int(args[i + 1]))

	print("[validate] 시드 %d건 검증 시작" % seeds)
	var start_ms: int = Time.get_ticks_msec()

	var failed: int = 0
	var total_attempts: int = 0
	var worst_attempts: int = 0
	var reason_counts: Dictionary = {}
	var read_sum: int = 0
	var skill_sum: int = 0
	var flip_sum: int = 0
	var ok_count: int = 0

	for i: int in range(seeds):
		var band: int = 1 + i % 5
		var report: Dictionary = CourseValidator.generate_valid("bulk-%d" % i, band)
		total_attempts += int(report["attempts"])
		worst_attempts = maxi(worst_attempts, int(report["attempts"]))
		if not bool(report["ok"]):
			failed += 1
			for reason: String in report["failures"]:
				var key: String = reason.substr(0, 3)
				reason_counts[key] = int(reason_counts.get(key, 0)) + 1
			continue
		ok_count += 1
		var stats: Dictionary = CourseValidator.validate(report["course"])["stats"]
		read_sum += int(stats.get("read_reward", 0))
		skill_sum += int(stats.get("skill_gap", 0))
		flip_sum += int(stats.get("flip_ratio", 0))

	var elapsed_ms: int = Time.get_ticks_msec() - start_ms
	print("[validate] 통과 %d / %d" % [ok_count, seeds])
	print("[validate] 실패 %d건" % failed)
	if not reason_counts.is_empty():
		print("[validate] 실패 사유: %s" % str(reason_counts))
	print("[validate] 평균 재시도 %.2f회, 최악 %d회" % [float(total_attempts) / seeds, worst_attempts])
	if ok_count > 0:
		print("[validate] 평균 읽기 보상 %d%%, 선택 의미 %d%%, 역전 구간 %d%%" % [
			read_sum / ok_count, skill_sum / ok_count, flip_sum / ok_count
		])
	print("[validate] 소요 %.1fs (코스당 %.1fms)" % [elapsed_ms / 1000.0, float(elapsed_ms) / seeds])

	if failed > 0:
		print("[validate] FAILED")
		quit(1)
	else:
		print("[validate] ALL GREEN")
		quit(0)
