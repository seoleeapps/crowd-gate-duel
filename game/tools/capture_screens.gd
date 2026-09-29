extends SceneTree
## 실행 화면 캡처. 실제 렌더러로 화면을 그려 PNG 로 남긴다(game-ui-design 실행 검수).
##   godot --path game --script res://tools/capture_screens.gd -- --out <dir> [--locale ko] [--size 1080x2340] [--only a,b]
## 헤드리스(더미 렌더러)에서는 화면이 그려지지 않으므로 창을 띄워 실행한다.
##
## 대국 장면은 고정 픽스처다. A-1 시안과 같은 순간(4/7 구간, 나 44 대 상대 31, 확약 2.1초,
## 게이트 x1.6 · +28 · 빼앗기 20%)을 실제 판정으로 만들어 같은 상태끼리 비교한다.

const FIXTURE_PICKS_ME: Array[int] = [0, 0, 1]
const FIXTURE_PICKS_OPP: Array[int] = [1, 1, 0, 0, 0, 0, 0]

var _out: String = ""
var _size: Vector2i = Vector2i(1080, 2340)
var _viewport: SubViewport
var _only: PackedStringArray = []


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var locale: String = "ko"
	for i: int in range(args.size() - 1):
		match args[i]:
			"--out":
				_out = args[i + 1]
			"--locale":
				locale = args[i + 1]
			"--only":
				_only = args[i + 1].split(",")
			"--size":
				var parts: PackedStringArray = args[i + 1].split("x")
				_size = Vector2i(int(parts[0]), int(parts[1]))
	if _out.is_empty():
		push_error("--out 이 필요합니다")
		quit(2)
		return
	# 스크립트 오류로 코루틴이 멈춰도 창이 남지 않게 실제 시간 기준으로 끝낸다.
	create_timer(120.0, true, false, true).timeout.connect(func() -> void:
		print("[capture] FAIL 감시 시간 초과")
		quit(1)
	)
	DirAccess.make_dir_recursive_absolute(_out)
	TranslationServer.set_locale(locale)
	_run.call_deferred()


func _run() -> void:
	_viewport = SubViewport.new()
	_viewport.size = _size
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_viewport)

	if _wants("duel-commit"):
		await _capture_duel("duel-commit", _fixture_session(false), 1.2 + 0.35 + 0.9)
	if _wants("duel-bot"):
		await _capture_duel("duel-bot", _fixture_session(true), 1.2 + 0.35 + 0.9)
	if _wants("duel-tie"):
		await _capture_duel("duel-tie", _tie_session(), 0.6)
	if _wants("onboarding-hand"):
		await _capture_onboarding("onboarding-hand", 0.72 + 0.35 + 0.5, 0)
	if _wants("onboarding-yield"):
		await _capture_onboarding("onboarding-yield", 0.0, 1)
	if _wants("result"):
		await _capture_result()
	if _wants("home"):
		await _capture_home()
	print("[capture] ALL DONE")
	quit(0)


func _wants(name: String) -> bool:
	return _only.is_empty() or _only.has(name)


## 시안과 같은 순간을 만드는 코스. 앞 3구간을 실제 판정으로 지나 44 대 31 이 된다.
static func fixture_course(band: int) -> Course:
	var course: Course = Course.new()
	course.seed_text = "capture-fixture"
	course.band = band
	course.segments = [
		[Gate.make(Gate.Kind.ADD, 8), Gate.make(Gate.Kind.MULTIPLY, 150), Gate.make(Gate.Kind.STEAL, 15)] as Array[Gate],
		[Gate.make(Gate.Kind.ADD, 24), Gate.make(Gate.Kind.MULTIPLY, 150), Gate.make(Gate.Kind.STEAL, 20)] as Array[Gate],
		[Gate.make(Gate.Kind.ADD, 4), Gate.make(Gate.Kind.SHIELD, 10), Gate.make(Gate.Kind.MULTIPLY, 150)] as Array[Gate],
		[Gate.make(Gate.Kind.MULTIPLY, 160), Gate.make(Gate.Kind.ADD, 28), Gate.make(Gate.Kind.STEAL, 20)] as Array[Gate],
		[Gate.make(Gate.Kind.MULTIPLY, 150), Gate.make(Gate.Kind.ADD, 40), Gate.make(Gate.Kind.STEAL, 20)] as Array[Gate],
		[Gate.make(Gate.Kind.MULTIPLY, 140), Gate.make(Gate.Kind.ADD, 50), Gate.make(Gate.Kind.STEAL, 20)] as Array[Gate],
		[Gate.make(Gate.Kind.MULTIPLY, 140), Gate.make(Gate.Kind.ADD, 60), Gate.make(Gate.Kind.STEAL, 20)] as Array[Gate],
	]
	return course


func _fixture_session(bot: bool) -> DuelSession:
	var course: Course = fixture_course(3)
	var opponent: Opponent = Opponent.bot(3)
	if not bot:
		opponent = Opponent.from_record(ReplayRecord.make("", 3, course.seed_text, FIXTURE_PICKS_OPP, 0))
	# 봇은 판단으로 고르므로 앞 구간 궤적이 달라진다. 봇 장면은 배지와 깃발 확인용이다.
	var session: DuelSession = DuelSession.new(course, opponent, 3000)
	for pick: int in FIXTURE_PICKS_ME:
		session.present_next()
		session.commit(pick)
	return session


func _tie_session() -> DuelSession:
	return DuelSession.new(fixture_course(3), Opponent.bot(3), 3000)


func _capture_duel(name: String, session: DuelSession, wait: float) -> void:
	var screen: DuelScreen = DuelScreen.new()
	screen.setup(session)
	await _show(screen)
	await create_timer(wait).timeout
	await _save(name)


func _capture_onboarding(name: String, wait: float, segment: int) -> void:
	var session: DuelSession = Onboarding.session()
	var screen: DuelScreen = DuelScreen.new()
	screen.setup(session, true)
	await _show(screen)
	if segment == 0:
		await create_timer(wait).timeout
	else:
		# 안내 칸을 차례로 눌러 2구간 공개(양보 사건) 직후를 찍는다.
		for i: int in range(segment + 1):
			while not screen._waiting_commit:
				await process_frame
			screen._on_picked(Onboarding.guided_pick(i))
		await screen.band.cells[0].get_tree().create_timer(0.35).timeout
	await _save(name)


func _capture_result() -> void:
	var session: DuelSession = _fixture_session(false)
	while session.present_next():
		session.commit(0)
	var scene_screen: DuelScreen = DuelScreen.new()
	scene_screen.setup(session)
	await _show(scene_screen)
	scene_screen.world.set_standing(session.crowd_me, session.crowd_opp, 1.0, false)
	await scene_screen.world.play_finale(session.crowd_me, session.crowd_opp).finished
	await RenderingServer.frame_post_draw
	var scene: Image = _viewport.get_texture().get_image()
	var result: ResultScreen = ResultScreen.new()
	result.setup(session, scene, {"feathers": 30, "daily_first_win": true, "band_before": 3, "band_after": 3}, false, 3)
	await _show(result)
	await create_timer(0.3).timeout
	await _save("result")


func _capture_home() -> void:
	var home: HomeScreen = HomeScreen.new()
	home.setup(3, 245, true)
	await _show(home)
	await create_timer(0.3).timeout
	await _save("home")


func _show(screen: Control) -> void:
	for child: Node in _viewport.get_children():
		child.queue_free()
	var holder: Control = Control.new()
	holder.theme = UiTheme.build()
	holder.size = Vector2(_size)
	_viewport.add_child(holder)
	screen.size = Vector2(_size)
	holder.add_child(screen)
	await process_frame


func _save(name: String) -> void:
	await RenderingServer.frame_post_draw
	var path: String = "%s/%s.png" % [_out, name]
	_viewport.get_texture().get_image().save_png(path)
	print("[capture] %s" % path)
