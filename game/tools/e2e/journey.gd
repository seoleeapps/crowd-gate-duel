extends SceneTree
## 실제 시작 장면과 화면 좌표 입력으로 검수한다. 사용자 저장은 열지 않는다.
const FakeInterstitial = preload("res://tools/e2e/fakes/fake_interstitial.gd")
const Driver = preload("res://tools/e2e/e2e_driver.gd")
var e2e: RefCounted
var main: Control
var app: Node
var out: String
var fake_ads: InterstitialAdPort

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
	app.respect_platform_focus = false
	app.in_foreground = true
	# CPU 렌더링과 PNG 저장에 걸린 시간이 자동 선택을 일으키지 않도록 시계만 고정한다.
	app.commit_clock = func(_delta: float) -> float: return 16.0
	app.seed_clock = func() -> int: return 20261021
	app.progress = ProgressStore.new(path)
	app.progress.read()
	app.progress.set_setting("sound", false)
	app.progress.set_setting("music", false)
	app.progress.set_setting("vibration", false)
	app.share.directory = path.get_base_dir().path_join("share")
	var locale: String = args[args.find("--locale") + 1] if args.has("--locale") else "ko"
	app.progress.set_setting("locale", locale)
	app.apply_settings()
	fake_ads = FakeInterstitial.new(self, app.progress)
	app.ads = fake_ads
	app.ad_breaks = InterstitialGate.new(fake_ads)
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
	_check_layout(duel)
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
	await create_timer(0.25).timeout
	_check_layout(duel)
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
	_check_layout(home)
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
	fake_ads.store = app.progress
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
	e2e.expect_equal("first normal result tries ad once", fake_ads.shows, 1)
	e2e.step("isolated focus remains foreground", app.in_foreground)
	e2e.step("reward is on disk before ad", fake_ads.persisted_before_show)
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
	_check_layout(profile)
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
	fake_ads.privacy_required = true
	fake_ads.consent_changed.emit()
	await e2e.frames(3)
	await _tap_text(settings, "SET_PRIVACY_OPTIONS")
	e2e.expect_equal("privacy choices use platform boundary", fake_ads.privacy_opens, 1)
	var feathers: int = app.progress.feathers()
	await _tap_text(settings, "SET_TUTORIAL")
	duel = await _screen(DuelScreen)
	await _tutorial_until(duel, 6)
	result = await _screen(ResultScreen)
	e2e.expect_equal("replay cannot duplicate reward", app.progress.feathers(), feathers)
	e2e.expect_equal("replayed tutorial never displays ad", fake_ads.shows, 1)
	await _tap_text(result, "HOME")
	await e2e.unmount(main)
	app.progress = ProgressStore.new(path)
	app.progress.read()
	fake_ads.store = app.progress
	await _mount()
	e2e.step("completed restart reaches home", await _screen(HomeScreen) != null)
	e2e.expect_equal("result persists restart", _games(), 1)
	e2e.step("desktop share is local boundary", app.share is SharePort)
	e2e.end()
	await e2e.unmount(main)
	e2e.begin("special-gates-and-progress-recovery", ["duel", "progress", "settings", "ads"])
	# Precondition: an established band-5 player, persisted before the actual main scene is mounted.
	app.progress.data["band"] = 5
	app.progress.data["wins"] = 80
	app.progress.data["feathers"] = 300
	app.progress.write()
	await _mount()
	home = await _screen(HomeScreen)
	await _tap_text(home, "PLAY")
	duel = await _screen(DuelScreen)
	await _play_normal(duel)
	result = await _screen(ResultScreen)
	e2e.step("steal lesson acknowledged", app.progress.lesson_seen(Gate.Kind.STEAL))
	e2e.step("shield lesson acknowledged", app.progress.lesson_seen(Gate.Kind.SHIELD))
	e2e.step("higher difficulty remains unlocked", app.progress.band() == 5)
	await _tap_text(result, "HOME")
	home = await _screen(HomeScreen)
	await _tap_text(home, "HOME_PROFILE")
	profile = await _screen(ProfileScreen)
	var before_purchase: int = app.progress.feathers()
	var target_card: CosmeticCard
	for card: CosmeticCard in profile._cards:
		if card.item_id == "palette_amber":
			target_card = card
	await e2e.tap(target_card)
	await e2e.frames(3)
	await _tap_text(profile, "CANCEL")
	e2e.expect_equal("cancel unlock keeps balance", app.progress.feathers(), before_purchase)
	await e2e.tap(target_card)
	await e2e.frames(3)
	await e2e.shot("unlock-confirm")
	await _tap_text(profile, "UNLOCK")
	e2e.expect_equal("unlock spends feathers once", app.progress.feathers(), before_purchase - Cosmetics.PRICE_PALETTE)
	e2e.expect_equal("purchased palette equipped", app.progress.equipped(Cosmetics.Slot.PALETTE), "palette_amber")
	await _back(profile)
	await _screen(HomeScreen)
	# Corrupt only the dedicated run's primary file, then let normal atomic read recover its backup.
	await e2e.unmount(main)
	var saved_feathers: int = int(AtomicFileStore.read(path + AtomicFileStore.BACKUP_SUFFIX)["data"].get("feathers", -1))
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string("broken-test-save")
	file.close()
	app.progress = ProgressStore.new(path)
	app.progress.read()
	e2e.expect_equal("damaged primary falls back to backup", app.progress.loaded_from, "backup")
	e2e.expect_equal("backup reward balance restored", app.progress.feathers(), saved_feathers)
	await _mount()
	e2e.step("recovery still enters application", await e2e.wait_for(func() -> bool:
		return main._current is HomeScreen or main._current is DuelScreen, 3000))
	e2e.end()
	app.feedback.stop_all()
	await e2e.unmount(main)
	var status: int = e2e.finish({"sourceSha": OS.get_environment("GITHUB_SHA"), "locale": locale,
		"focus": "fixed-foreground", "commitClock": "16ms-per-frame", "audio": "Dummy"})
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
			if duel.session.segment_index >= 4:
				await create_timer(0.3).timeout
				_check_layout(duel)
				await e2e.shot("quiz-preview-%d" % duel.session.segment_index)
			var index: int = Onboarding.ANSWERS[duel.session.segment_index]
			e2e.step("tap tutorial gate", await e2e.tap(duel.band.cells[index]))
		await process_frame
	e2e.step("tutorial input completes", false)

func _play_normal(duel: DuelScreen) -> void:
	for i: int in range(18000):
		if not is_instance_valid(duel) or duel.session.is_finished():
			return
		if duel._captions._waiting:
			var remaining: int = duel.session.remaining_ms
			await create_timer(0.3).timeout
			e2e.expect_equal("special example pauses countdown", duel.session.remaining_ms, remaining)
			_check_layout(duel)
			await e2e.shot("lesson-%s" % ("shield" if app.progress.lesson_seen(Gate.Kind.STEAL) else "steal"))
			await e2e.tap(duel._captions)
		elif duel._waiting_commit:
			_check_layout(duel)
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

func _check_layout(screen: Control) -> void:
	var bounds: Rect2 = screen.get_global_rect().grow(1)
	for node: Node in screen.find_children("*", "BaseButton", true, false):
		var button: BaseButton = node
		if button.is_visible_in_tree() and button.size != Vector2.ZERO:
			e2e.step("touch target at least 48dp", button.size.x >= 48 * Palette.DP - 1 and button.size.y >= 48 * Palette.DP - 1)
	if screen is DuelScreen:
		var duel: DuelScreen = screen
		for chip: CountChip in [duel.world.me_chip, duel.world.opp_chip]:
			e2e.step("crowd chip fits stage", bounds.encloses(chip.get_global_rect()), "stage=%s chip=%s" % [bounds, chip.get_global_rect()])
		e2e.step("crowd chips do not overlap", not duel.world.me_chip.get_global_rect().intersects(duel.world.opp_chip.get_global_rect()))
		if duel._captions.visible:
			var card: Rect2 = duel._captions._card.get_global_rect()
			e2e.step("caption fits stage", bounds.encloses(card))
			e2e.step("caption leaves both crowd values visible", not card.intersects(duel.world.me_chip.get_global_rect()) and not card.intersects(duel.world.opp_chip.get_global_rect()))
	elif screen is HomeScreen:
		for button: Node in screen.find_children("*", "Button", true, false):
			if button != screen._start:
				e2e.step("home buttons do not overlap play", not button.get_global_rect().intersects(screen._start.get_global_rect()))
	elif screen is ProfileScreen:
		for card: CosmeticCard in screen._cards:
			e2e.step("cosmetic column fits width", card.get_global_rect().position.x >= bounds.position.x and card.get_global_rect().end.x <= bounds.end.x)
