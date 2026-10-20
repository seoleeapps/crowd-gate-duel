extends SceneTree
## 실제 시작 장면과 화면 좌표 입력으로 검수한다. 사용자 저장은 열지 않는다.
const Driver = preload("res://tools/e2e/e2e_driver.gd")
var e2e: RefCounted
var main: Control
var app: Node
var out: String

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var path: String = args[args.find("--progress-path") + 1] if args.has("--progress-path") else ""
	if not path.begins_with("user://e2e/"):
		push_error("--progress-path user://e2e/... required")
		quit(2)
		return
	AtomicFileStore.remove(path)
	app = root.get_node("App")
	app.progress = ProgressStore.new(path)
	app.progress.read()
	app.progress.set_setting("sound", false)
	app.progress.set_setting("music", false)
	app.progress.set_setting("vibration", false)
	app.share.directory = path.get_base_dir().path_join("share")
	var locale: String = args[args.find("--locale") + 1] if args.has("--locale") else "ko"
	app.progress.set_setting("locale", locale)
	app.apply_settings()
	out = args[args.find("--out") + 1] if args.has("--out") else "../build/e2e"
	var dimensions: PackedStringArray = (args[args.find("--size") + 1] if args.has("--size") else "1080x2340").split("x")
	e2e = Driver.new(self, Vector2i(int(dimensions[0]), int(dimensions[1])), out, args.has("--capture"))
	Engine.time_scale = 6.0
	create_timer(150.0, true, false, true).timeout.connect(func() -> void: quit(1))

	e2e.begin("mandatory-tutorial", ["tutorial", "progress"])
	await _mount()
	var duel: DuelScreen = await _screen(DuelScreen)
	await e2e.wait_for(func() -> bool: return duel._waiting_commit, 3000)
	await create_timer(6.0).timeout
	e2e.expect_equal("idle never commits", duel.session.picks_me.size(), 0)
	e2e.step("idle never completes", not app.progress.onboarding_done())
	await e2e.shot("01-tutorial-pick")
	await _tutorial_until(duel, 2)
	await e2e.unmount(main)
	app.progress = ProgressStore.new(path)
	app.progress.read()
	e2e.expect_equal("tutorial checkpoint survives restart", app.progress.tutorial_step(), 2)
	await _mount()
	duel = await _screen(DuelScreen)
	await _tutorial_until(duel, 4)
	await e2e.wait_for(func() -> bool: return duel._waiting_commit, 3000)
	e2e.step("quiz wrong input", await e2e.tap(duel.band.cells[1]))
	await e2e.wait_for(func() -> bool: return duel._captions._waiting, 3000)
	await e2e.shot("02-quiz-mistake")
	e2e.expect_equal("wrong answer keeps checkpoint", app.progress.tutorial_step(), 4)
	await e2e.tap(duel._captions)
	await _tutorial_until(duel, 6)
	var result: ResultScreen = await _screen(ResultScreen)
	e2e.step("tutorial complete", app.progress.onboarding_done())
	e2e.expect_equal("completion feathers once", app.progress.feathers(), 30)
	e2e.expect_equal("tutorial is not ranked", _games(), 0)
	await e2e.shot("03-tutorial-result")
	await _tap_text(result, "HOME")
	e2e.end()

	e2e.begin("normal-bot-and-restore", ["duel", "progress", "ads"])
	var home: HomeScreen = await _screen(HomeScreen)
	await e2e.shot("04-home")
	await _tap_text(home, "PLAY")
	duel = await _screen(DuelScreen)
	e2e.step("normal opponent is labeled bot", duel.session.opponent.is_bot())
	await e2e.wait_for(func() -> bool: return duel._waiting_commit, 3000)
	await _dismiss_lesson(duel)
	await e2e.tap(duel.band.cells[0])
	await e2e.wait_for(func() -> bool: return duel._waiting_commit or duel._captions._waiting, 3000)
	await _dismiss_lesson(duel)
	var picks: int = duel.session.picks_me.size()
	var seed_text: String = duel.session.course.seed_text
	await e2e.unmount(main)
	app.progress = ProgressStore.new(path)
	app.progress.read()
	await _mount()
	duel = await _screen(DuelScreen)
	e2e.expect_equal("normal picks restored", duel.session.picks_me.size(), picks)
	e2e.expect_equal("same course restored", duel.session.course.seed_text, seed_text)
	await _play_normal(duel)
	result = await _screen(ResultScreen)
	e2e.expect_equal("normal result counted once", _games(), 1)
	e2e.step("finished save cleared", app.progress.in_progress().is_empty())
	await e2e.shot("05-normal-result")
	await _tap_text(result, "SHARE")
	e2e.step("share finishes without blocking result", await e2e.wait_for(func() -> bool: return not main._sharing, 3000))
	e2e.expect_equal("share feedback matches actual renderer", result.toast.text,
		TranslationServer.translate("SHARE_FAILED" if DisplayServer.get_name() == "headless" else "SHARE_SAVED"))
	await _tap_text(result, "HOME")
	e2e.end()

	e2e.begin("cosmetics-settings-and-replay", ["cosmetics", "settings", "tutorial", "progress", "share"])
	home = await _screen(HomeScreen)
	await _tap_text(home, "HOME_PROFILE")
	var profile: ProfileScreen = await _screen(ProfileScreen)
	e2e.step("tutorial cosmetic unlocked", app.progress.is_unlocked(Cosmetics.ONBOARDING_REWARD))
	await e2e.shot("06-cosmetics")
	for card: CosmeticCard in profile._cards:
		if card.item_id == Cosmetics.ONBOARDING_REWARD:
			e2e.step("equip earned cosmetic", await e2e.tap(card))
			e2e.expect_equal("equipped flag saved", app.progress.equipped(Cosmetics.Slot.FLAG), Cosmetics.ONBOARDING_REWARD)
	await _back(profile)
	home = await _screen(HomeScreen)
	await _tap_text(home, "HOME_SETTINGS")
	var settings: SettingsScreen = await _screen(SettingsScreen)
	await e2e.shot("07-settings")
	await _tap_text(settings, "SET_SOUND")
	e2e.step("sound setting updates runtime", app.feedback.sound_on)
	await _tap_text(settings, "SET_SOUND")
	var feathers: int = app.progress.feathers()
	await _tap_text(settings, "SET_TUTORIAL")
	duel = await _screen(DuelScreen)
	await _tutorial_until(duel, 6)
	result = await _screen(ResultScreen)
	e2e.expect_equal("replay cannot duplicate reward", app.progress.feathers(), feathers)
	await _tap_text(result, "HOME")
	await e2e.unmount(main)
	app.progress = ProgressStore.new(path)
	app.progress.read()
	await _mount()
	e2e.step("completed restart reaches home", await _screen(HomeScreen) != null)
	e2e.expect_equal("result persists restart", _games(), 1)
	e2e.step("desktop share is local boundary", app.share is SharePort)
	e2e.end()
	app.feedback.stop_all()
	await e2e.unmount(main)
	var status: int = e2e.finish({"sourceSha": OS.get_environment("GITHUB_SHA"), "locale": locale})
	print("[e2e] ALL GREEN" if status == 0 else "[e2e] FAILED")
	quit(status)

func _mount() -> void:
	main = load("res://src/presentation/app_root.tscn").instantiate()
	await e2e.mount(main)

func _screen(type: Variant) -> Variant:
	for i: int in range(6000):
		if main != null and is_instance_valid(main._current) and is_instance_of(main._current, type):
			await e2e.frames(3)
			if main._current is DuelScreen:
				main._current.pause_when_backgrounded = false
			return main._current
		await process_frame
	e2e.step("screen timeout", false, str(type))
	quit(1)
	return null

func _tutorial_until(duel: DuelScreen, target: int) -> void:
	for i: int in range(15000):
		if not is_instance_valid(duel) or duel.session.is_finished():
			return
		if duel._captions._waiting:
			await e2e.tap(duel._captions)
		elif duel._waiting_commit:
			if duel.session.segment_index >= target:
				return
			var index: int = Onboarding.ANSWERS[duel.session.segment_index]
			e2e.step("tap tutorial gate", await e2e.tap(duel.band.cells[index]))
		await process_frame
	e2e.step("tutorial input completes", false)

func _play_normal(duel: DuelScreen) -> void:
	for i: int in range(18000):
		if not is_instance_valid(duel) or duel.session.is_finished():
			return
		if duel._captions._waiting:
			await e2e.tap(duel._captions)
		elif duel._waiting_commit:
			await e2e.shot("normal-gate-%d" % duel.session.segment_index)
			e2e.step("tap normal gate", await e2e.tap(duel.band.cells[1]))
		await process_frame
	e2e.step("normal input completes", false)

func _dismiss_lesson(duel: DuelScreen) -> void:
	if duel._captions._waiting:
		await e2e.shot("special-gate-lesson")
		await e2e.tap(duel._captions)
		await e2e.wait_for(func() -> bool: return duel._waiting_commit, 3000)

func _tap_text(screen: Control, key: String) -> void:
	for node: Node in screen.find_children("*", "BaseButton", true, false):
		if node.text == TranslationServer.translate(key):
			await e2e.wait_for(func() -> bool: return not node.disabled, 3000)
			e2e.step("tap " + key, await e2e.tap(node))
			return
	e2e.step("button found " + key, false)

func _back(screen: Control) -> void:
	for node: Node in screen.find_children("*", "BaseButton", true, false):
		if node.accessibility_name == TranslationServer.translate("BACK") or node.text == "‹" or node.text == "←":
			e2e.step("tap back", await e2e.tap(node))
			return
	e2e.step("back button exists", false)

func _games() -> int:
	return app.progress.wins() + int(app.progress.data["losses"]) + int(app.progress.data["draws"])
