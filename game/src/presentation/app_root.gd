extends Control
## 부트 화면. 아직 대국 화면이 없는 단계의 자리표시자이며 3주차에 SCR-002 로 대체된다.
##
## 빈 씬을 두지 않고 도메인 자체 점검을 돌리는 이유는 두 가지다. 첫째, 엔진이 메인 씬을
## 요구하므로 컴파일 게이트(`godot --headless --quit`)가 통과하려면 하나는 있어야 한다.
## 둘째, 실행하자마자 규칙·생성기·검증기가 살아 있는지 눈으로 확인할 수 있다.

const BOOT_SEED: String = "boot-check"

@onready var status_label: Label = $Status


func _ready() -> void:
	var lines: PackedStringArray = []
	lines.append("갈림길 군중 대전 — 도메인 자체 점검")
	lines.append("")

	var report: Dictionary = CourseValidator.generate_valid(BOOT_SEED, 3)
	if not bool(report["ok"]):
		lines.append("코스 생성 실패: %s" % ", ".join(report["failures"]))
		_render(lines)
		return

	var course: Course = report["course"]
	lines.append("코스 시드 %s / 대역 %d / 구간 %d (재시도 %d회)" % [
		course.seed_text, course.band, course.segment_count(), int(report["attempts"])
	])

	var stats: Dictionary = CourseValidator.validate(course)["stats"]
	lines.append("읽기 보상 %d%% · 선택 의미 %d%% · 역전 구간 %d%%" % [
		int(stats.get("read_reward", 0)),
		int(stats.get("skill_gap", 0)),
		int(stats.get("flip_ratio", 0)),
	])
	lines.append("")

	var duel: Dictionary = CourseValidator.simulate(
		course, Strategies.Kind.LEADER_AWARE, Strategies.Kind.MAX_EXPECTED, 1
	)
	var replay: Dictionary = DuelEngine.play(course, duel["picks_a"], duel["picks_b"])
	var reproduced: bool = int(replay["a"]) == int(duel["a"]) and int(replay["b"]) == int(duel["b"])

	lines.append("표본 대국 (순위 인식 대 기대값 최대)")
	for step: Dictionary in replay["trace"]:
		lines.append("  구간 %d  %s  %d : %d" % [
			int(step["segment"]) + 1,
			"겹침" if bool(step["split"]) else "    ",
			int(step["a"]),
			int(step["b"]),
		])
	lines.append("")
	lines.append("재생 일치: %s" % ("예" if reproduced else "아니오"))
	_render(lines)


func _render(lines: PackedStringArray) -> void:
	var text: String = "\n".join(lines)
	if status_label != null:
		status_label.text = text
	print(text)
