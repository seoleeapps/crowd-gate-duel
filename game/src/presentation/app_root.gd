extends Control
## 화면 전환 루트. 03 내비게이션 그래프를 따른다.
##
##   첫 실행 → 온보딩 대국 → 결과 → 홈
##   홈 → 대국 → 결과 → 홈 / 한 판 더
##
##   홈 → 꾸미기 → 홈 / 홈 → 설정 → 홈
##
## 화면은 입력과 연출만 맡고, 판 결과 반영과 진행 저장는 여기서 처리한다.

const MUSIC_HOME: AudioStream = preload("res://assets/audio/bgm_home.ogg")
const MUSIC_DUEL: AudioStream = preload("res://assets/audio/bgm_duel.ogg")
const STING_WIN: AudioStream = preload("res://assets/audio/sting_win.wav")
const STING_LOSE: AudioStream = preload("res://assets/audio/sting_lose.wav")

var _stage: Stage
var _current: Control
## 같은 판의 종료 신호가 중복되어도 보상은 한 번만 반영한다.
var _settled: Dictionary = {}
var _tutorial_replay: bool = false
var _sharing: bool = false


func _ready() -> void:
	theme = UiTheme.build()
	_stage = Stage.new()
	add_child(_stage)
	var in_progress: Dictionary = App.progress.in_progress()
	var saved: DuelSession = DuelSession.from_dict(in_progress.get("session", {}))
	if not App.progress.onboarding_done():
		_start_onboarding()
	elif saved != null:
		# 진행 중인 봇 대국은 남은 선택 시간부터 이어서 한다.
		_start_duel(saved)
	else:
		_show_home()


func _swap(screen: Control) -> void:
	if _current != null:
		_current.queue_free()
	_current = screen
	_stage.add_child(screen)
	# 모든 버튼에 가벼운 클릭음(04 오디오 표). 게이트 칸은 확약음이 따로 있어 제외한다.
	for node: Node in screen.find_children("*", "Button", true, false):
		if not node is GateCell:
			(node as Button).pressed.connect(App.feedback.play.bind("click"))


func _show_home() -> void:
	var home: HomeScreen = HomeScreen.new()
	home.setup(App.progress.band(), App.progress.feathers())
	home.my_color = _my_color()
	home.my_flag = _my_flag()
	home.start_pressed.connect(_on_start_pressed)
	home.profile_pressed.connect(_show_profile)
	home.settings_pressed.connect(_show_settings)
	_swap(home)
	App.feedback.set_intensity(1.0)
	App.feedback.play_music(MUSIC_HOME)
	# 다음 판의 결과 광고를 미리 준비한다.
	App.ads.preload_ad()


func _on_start_pressed() -> void:
	_start_new_duel()


func _start_new_duel() -> void:
	if not App.progress.onboarding_done():
		_start_onboarding()
		return
	App.ads.preload_ad()
	var band: int = App.progress.band()
	var report: Dictionary = CourseValidator.generate_valid(App.fallback_seed(band), band)
	assert(bool(report["ok"]))
	_start_duel(DuelSession.new(report["course"], Opponent.bot(band), App.commit_ms(band)))


func _start_duel(session: DuelSession) -> void:
	var screen: DuelScreen = _duel_screen(session, false)
	screen.checkpoint.connect(_save_in_progress.bind(session))
	screen.committed.connect(_on_committed.bind(session, false))
	screen.segment_resolved.connect(_save_in_progress.bind(session))
	screen.finished.connect(_on_duel_finished.bind(session))
	_swap(screen)


func _start_onboarding(replay: bool = false) -> void:
	_tutorial_replay = replay
	var session: DuelSession = Onboarding.session(0 if replay else App.progress.tutorial_step())
	var screen: DuelScreen = _duel_screen(session, true)
	screen.tutorial_accepted.connect(func(next_step: int) -> void:
		if not _tutorial_replay:
			App.progress.set_tutorial_step(next_step)
			App.progress.write()
	)
	screen.finished.connect(_on_onboarding_finished.bind(session))
	_swap(screen)


func _duel_screen(session: DuelSession, tutorial: bool) -> DuelScreen:
	var screen: DuelScreen = DuelScreen.new()
	screen.setup(session, tutorial)
	screen.pause_when_backgrounded = App.pause_on_focus_loss
	screen.lesson_store = App.progress
	screen.feedback = App.feedback
	screen.reduce_shake = bool(App.progress.setting("reduce_shake"))
	screen.colorblind_assist = bool(App.progress.setting("colorblind_assist"))
	screen.my_color = _my_color()
	screen.my_flag = _my_flag()
	App.feedback.play_music(MUSIC_DUEL)
	return screen


func _my_color() -> Color:
	return Color(Cosmetics.value_of(App.progress.equipped(Cosmetics.Slot.PALETTE)))


func _my_flag() -> String:
	return Cosmetics.value_of(App.progress.equipped(Cosmetics.Slot.FLAG))


func _show_profile() -> void:
	var screen: ProfileScreen = ProfileScreen.new()
	screen.setup(App.progress)
	screen.back_pressed.connect(_show_home)
	_swap(screen)


func _show_settings() -> void:
	var screen: SettingsScreen = SettingsScreen.new()
	screen.setup(App.progress)
	screen.back_pressed.connect(_show_home)
	screen.settings_changed.connect(_on_setting_changed)
	screen.reset_confirmed.connect(_on_reset)
	screen.tutorial_pressed.connect(_start_onboarding.bind(true))
	screen.privacy_options_pressed.connect(App.ads.show_privacy_options)
	screen.privacy_required = App.ads.privacy_required
	_swap(screen)


func _on_setting_changed(key: String) -> void:
	App.apply_settings()
	if key == "locale":
		# 언어를 바꾸면 화면 문구를 새 언어로 다시 만든다.
		_show_settings()
	elif key == "music":
		App.feedback.play_music(MUSIC_HOME)


## 사용자가 확인한 초기화는 로컬 진행을 지우고 필수 체험부터 다시 시작한다.
func _on_reset() -> void:
	App.progress.reset_progress()
	App.progress.write()
	_start_onboarding()


func _on_committed(_step: Dictionary, session: DuelSession, _tutorial: bool) -> void:
	_save_in_progress(session)

func _save_in_progress(session: DuelSession) -> void:
	App.progress.set_in_progress({"session": session.to_dict()})
	App.progress.write()

func _on_duel_finished(scene: Image, session: DuelSession) -> void:
	var id: int = session.get_instance_id()
	if _settled.has(id):
		return
	_settled[id] = true
	var reward: Dictionary = App.progress.apply_result(session.result(), App.today())
	App.progress.set_in_progress({})
	var saved: bool = App.progress.write() == OK
	_show_result(session, scene, reward, false, saved)


func _on_onboarding_finished(scene: Image, session: DuelSession) -> void:
	var feathers: int = 0 if _tutorial_replay else App.progress.complete_onboarding()
	App.progress.write()
	var items: Array[String] = []
	if feathers > 0:
		items.append(Cosmetics.ONBOARDING_REWARD)
	_show_result(session, scene, {"feathers": feathers, "items": items}, true, false)


func _show_result(session: DuelSession, scene: Image, reward: Dictionary, tutorial: bool, ad_allowed: bool) -> void:
	App.feedback.stop_music()
	var stinger: AudioStream = STING_WIN if session.result() == DuelEngine.RESULT_A_WIN else STING_LOSE
	if session.result() != DuelEngine.RESULT_DRAW:
		App.feedback.play_stinger(stinger)
		App.feedback.vibrate(60 if session.result() == DuelEngine.RESULT_A_WIN else 30, 0.6)
	var result: ResultScreen = ResultScreen.new()
	result.setup(session, scene, reward, tutorial)
	result.rematch_pressed.connect(_on_rematch)
	result.home_pressed.connect(_show_home)
	result.share_pressed.connect(_on_share.bind(result, session, scene))
	_swap(result)
	# 결과 숫자가 먼저 그려진 뒤, 같은 결과의 준비 상태를 한 번만 확인한다.
	if not tutorial and ad_allowed:
		result.set_busy(true)
		var prepared: bool = App.ads.ready
		await get_tree().create_timer(0.65).timeout
		if _current == result and App.ad_breaks.try_result(str(session.get_instance_id()), false, prepared and App.in_foreground):
			await App.ad_breaks.finished
		if is_instance_valid(result):
			result.set_busy(false)


func _on_rematch() -> void:
	_start_new_duel()


func _on_share(result: ResultScreen, session: DuelSession, scene: Image) -> void:
	if _sharing:
		return
	_sharing = true
	result.set_busy(true)
	# 카드를 그리는 사이 결과 화면이 닫힐 수 있으므로 필요한 값은 먼저 꺼내 둔다.
	var color: Color = result.result_color()
	var border: String = Cosmetics.value_of(App.progress.equipped(Cosmetics.Slot.BORDER))
	var image: Image = await ShareCard.render(self, ShareCard.SQUARE, scene, session.crowd_me, session.crowd_opp, color, border)
	var path: String = App.share.share_image(image, "result-%d" % App.now_unix())
	var shared: bool = false
	if not path.is_empty():
		shared = await App.share.finished
	_sharing = false
	if is_instance_valid(result):
		result.set_busy(false)
		result.show_toast(tr("SHARE_SAVED") if shared else tr("SHARE_FAILED"))
