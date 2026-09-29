extends SceneTree
## 앱 흐름 스모크. 실제 화면 전환 루트를 띄우고 탭을 흉내 내 첫 세션을 끝까지 지나간다.
##   첫 실행 → 온보딩 대국 → 결과 → 홈 → 대국 → 결과 → 홈
##   godot --headless --path game --script res://tools/smoke_flow.gd -- --progress-path user://smoke/progress.json
## 사용자 저장을 건드리지 않도록 반드시 --progress-path 로 별도 경로를 쓴다. 시작할 때 그 경로를 비운다.
##
## 확인: 온보딩 완료와 보상, 판 결과 반영, 판당 원격 읽기·쓰기 상한(AC-006), 봇 배지 상대,
## 진행 중 판 저장이 판이 끝나면 비워지는지, 핵심 분석 이벤트 발행.

const TIME_SCALE: float = 6.0
const STEP_LIMIT_FRAMES: int = 20000
const WATCHDOG_SECONDS: float = 180.0

var _failures: PackedStringArray = []


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var index: int = args.find("--progress-path")
	if index < 0 or not args[index + 1].begins_with("user://smoke/"):
		push_error("--progress-path user://smoke/... 가 필요합니다")
		quit(2)
		return
	AtomicFileStore.remove(args[index + 1])
	Engine.time_scale = TIME_SCALE
	# 스크립트 오류로 코루틴이 멈추면 끝나지 않으므로 실제 시간 기준 감시 타이머를 둔다.
	create_timer(WATCHDOG_SECONDS, true, false, true).timeout.connect(func() -> void:
		print("[smoke] FAIL 감시 시간 초과")
		quit(1)
	)
	_run.call_deferred()


func _run() -> void:
	var app: Node = root.get_node("App")
	app.progress.read()
	change_scene_to_file("res://src/presentation/app_root.tscn")

	var onboarding: DuelScreen = await _wait_for(DuelScreen)
	_check(onboarding != null and onboarding.tutorial, "첫 실행은 온보딩 대국")
	await _play(onboarding)
	var first_result: ResultScreen = await _wait_for(ResultScreen)
	_check(first_result != null and first_result.tutorial, "온보딩 뒤 결과 화면")
	_check(app.progress.onboarding_done(), "온보딩 완료 저장")
	_check_eq(app.progress.feathers(), ProgressStore.FEATHERS_ONBOARDING, "온보딩 보상 깃털")
	_check_eq(app.progress.wins() + int(app.progress.data["losses"]), 0, "온보딩은 전적에 넣지 않는다")
	first_result.home_pressed.emit()

	var home: HomeScreen = await _wait_for(HomeScreen)
	_check(home != null, "결과 → 홈")
	var reads_before: int = app.remote.read_count
	home.start_pressed.emit()
	var duel: DuelScreen = await _wait_for(DuelScreen)
	_check(duel != null and not duel.tutorial, "홈 → 대국")
	_check(duel.session.opponent.is_bot(), "기록 풀이 비어 있으면 봇 상대")
	_check_eq(duel.world.opp_chip._badge_text.text, TranslationServer.translate("CHIP_BOT"), "봇 배지 표시")
	await _play(duel)
	var result: ResultScreen = await _wait_for(ResultScreen)
	_check(result != null and not result.tutorial, "대국 → 결과")
	var games: int = app.progress.wins() + int(app.progress.data["losses"]) + int(app.progress.data["draws"])
	_check_eq(games, 1, "판 결과 1건 반영")
	_check(app.progress.in_progress().is_empty(), "끝난 판은 진행 중 저장에서 비워진다")
	_check(app.remote.read_count - reads_before <= 1, "판당 원격 읽기 1건 이하")
	_check_eq(app.remote.write_count, 1, "판당 원격 쓰기 1건")
	_check(app.progress.pending_upload().is_empty(), "기록 업로드 완료")

	var names: PackedStringArray = []
	for event: Dictionary in app.analytics.recent:
		names.append(str(event["name"]))
	for expected: String in ["tutorial_begin", "onboarding_split_seen", "tutorial_complete", "home_view",
			"duel_start_tap", "opponent_resolved", "level_start", "gate_commit", "level_end", "result_view"]:
		_check(names.has(expected), "분석 이벤트 %s" % expected)

	result.home_pressed.emit()
	_check(await _wait_for(HomeScreen) != null, "결과 → 홈 복귀")

	if _failures.is_empty():
		print("[smoke] ALL GREEN")
		quit(0)
	else:
		for failure: String in _failures:
			print("[smoke] FAIL %s" % failure)
		quit(1)


## 확약을 기다렸다가 누른다. 온보딩은 안내 칸, 일반 대국은 가운데 칸을 누른다.
func _play(screen: DuelScreen) -> void:
	for frame: int in range(STEP_LIMIT_FRAMES):
		if not is_instance_valid(screen) or screen.session.is_finished():
			return
		if screen._waiting_commit:
			var guided: int = Onboarding.guided_pick(screen.session.segment_index) if screen.tutorial else 1
			screen._on_picked(maxi(guided, 0) if screen.tutorial else guided)
		await process_frame


func _wait_for(type: Variant) -> Variant:
	for frame: int in range(STEP_LIMIT_FRAMES):
		var scene: Node = current_scene
		if scene != null:
			for child: Node in scene.get_children():
				if is_instance_of(child, type) and not child.is_queued_for_deletion():
					return child
		await process_frame
	_failures.append("화면 대기 시간 초과: %s" % str(type))
	return null


func _check(condition: bool, label: String) -> void:
	if not condition:
		_failures.append(label)


func _check_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		_failures.append("%s (expected=%s actual=%s)" % [label, str(expected), str(actual)])
