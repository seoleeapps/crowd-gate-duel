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

	result.home_pressed.emit()
	var back_home: HomeScreen = await _wait_for(HomeScreen)
	_check(back_home != null, "결과 → 홈 복귀")

	back_home.profile_pressed.emit()
	var profile: ProfileScreen = await _wait_for(ProfileScreen)
	_check(profile != null, "홈 → 꾸미기")
	_check(app.progress.is_unlocked(Cosmetics.ONBOARDING_REWARD), "온보딩 보상 깃발 해금")
	profile.back_pressed.emit()
	var home_again: HomeScreen = await _wait_for(HomeScreen)
	home_again.settings_pressed.emit()
	var settings: SettingsScreen = await _wait_for(SettingsScreen)
	_check(settings != null, "홈 → 설정")
	app.progress.set_setting("sound", false)
	settings.settings_changed.emit("sound")
	_check(not app.feedback.sound_on, "설정 변경이 소리에 반영")
	settings.back_pressed.emit()
	_check(await _wait_for(HomeScreen) != null, "설정 → 홈")

	var names: PackedStringArray = []
	for event: Dictionary in app.analytics.recent:
		names.append(str(event["name"]))
	for expected: String in ["tutorial_begin", "onboarding_split_seen", "tutorial_complete", "home_view",
			"duel_start_tap", "opponent_resolved", "level_start", "segment_present", "gate_commit", "gate_reveal",
			"gate_yield", "level_end", "result_view", "cosmetic_view", "settings_view"]:
		_check(names.has(expected), "분석 이벤트 %s" % expected)

	# 재생 객체는 오디오 스레드가 한 번 돈 뒤에 풀린다. 끄고 잠시 기다려야 종료 시 누수로 잡히지 않는다.
	app.feedback.stop_all()
	await create_timer(0.3, true, false, true).timeout

	if _failures.is_empty():
		print("[smoke] ALL GREEN")
		quit(0)
	else:
		for failure: String in _failures:
			print("[smoke] FAIL %s" % failure)
		quit(1)


## 확약을 기다렸다가 누른다. 온보딩은 안내 칸, 일반 대국은 가운데 칸을 누른다.
func _play(screen: DuelScreen) -> void:
	var checked_band: bool = false
	for frame: int in range(STEP_LIMIT_FRAMES):
		if not is_instance_valid(screen) or screen.session.is_finished():
			return
		if screen._waiting_commit:
			if not checked_band:
				# 게이트 띠는 구간이 제시된 뒤에 생기므로 확약 대기 때 한 번 더 검사한다.
				_check_touch_targets(screen)
				checked_band = screen.band.cells.size() > 0
			var guided: int = Onboarding.guided_pick(screen.session.segment_index) if screen.tutorial else 1
			screen._on_picked(maxi(guided, 0) if screen.tutorial else guided)
		await process_frame


func _wait_for(type: Variant) -> Variant:
	for frame: int in range(STEP_LIMIT_FRAMES):
		var scene: Node = current_scene
		if scene != null:
			for child: Node in scene.find_children("*", "", true, false):
				if is_instance_of(child, type) and not child.is_queued_for_deletion():
					await process_frame
					_check_touch_targets(child)
					return child
		await process_frame
	_failures.append("화면 대기 시간 초과: %s" % str(type))
	return null


## 03 접근성: 모든 상호작용 요소 48dp 이상, 게이트 칸은 높이 96dp 이상(SRC-008).
func _check_touch_targets(screen: Node) -> void:
	var min_px: float = 48.0 * Palette.DP - 0.5
	for node: Node in screen.find_children("*", "BaseButton", true, false):
		var button: BaseButton = node as BaseButton
		if not button.is_visible_in_tree() or button.size == Vector2.ZERO:
			continue
		if button.size.x < min_px or button.size.y < min_px:
			_failures.append("터치 대상 48dp 미만: %s %s (%s)" % [screen.get_class(), button.name, str(button.size / Palette.DP)])
		if button is GateCell and button.size.y < 96.0 * Palette.DP - 0.5:
			_failures.append("게이트 칸 96dp 미만: %s" % str(button.size / Palette.DP))


func _check(condition: bool, label: String) -> void:
	if not condition:
		_failures.append(label)


func _check_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		_failures.append("%s (expected=%s actual=%s)" % [label, str(expected), str(actual)])
