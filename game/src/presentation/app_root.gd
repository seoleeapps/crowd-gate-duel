extends Control
## 화면 전환 루트. 03 내비게이션 그래프를 따른다.
##
##   첫 실행 → 온보딩 대국 → 결과 → 홈
##   홈 → 대국 → 결과 → 홈 / 한 판 더 / 보상 광고 재도전
##
##   홈 → 꾸미기 → 홈 / 홈 → 설정 → 홈
##
## 화면은 입력과 연출만 맡고, 판 결과 반영·기록 업로드·진행 저장·분석 이벤트는 여기서 처리한다.

const MUSIC_HOME: AudioStream = preload("res://assets/audio/bgm_home.ogg")
const MUSIC_DUEL: AudioStream = preload("res://assets/audio/bgm_duel.ogg")
const STING_WIN: AudioStream = preload("res://assets/audio/sting_win.wav")
const STING_LOSE: AudioStream = preload("res://assets/audio/sting_lose.wav")

var _current: Control
## 보상형 광고를 보는 중이면 true. 연타로 재도전이 두 번 걸리지 않게 막는다.
var _ad_in_flight: bool = false


func _ready() -> void:
	theme = UiTheme.build()
	var in_progress: Dictionary = App.progress.in_progress()
	var saved: DuelSession = DuelSession.from_dict(in_progress.get("session", {}))
	if not App.progress.onboarding_done():
		_start_onboarding()
	elif saved != null:
		# 진행 중이던 판은 남은 확약 시간부터 이어서 한다. 재도전 판이면 재도전 제한도 이어 간다.
		_start_duel(saved, bool(in_progress.get("ad_allowed", true)))
	else:
		_show_home()


func _swap(screen: Control) -> void:
	if _current != null:
		_current.queue_free()
	_current = screen
	add_child(screen)
	# 모든 버튼에 가벼운 클릭음(04 오디오 표). 게이트 칸은 확약음이 따로 있어 제외한다.
	for node: Node in screen.find_children("*", "Button", true, false):
		if not node is GateCell:
			(node as Button).pressed.connect(App.feedback.play.bind("click"))


func _show_home() -> void:
	var home: HomeScreen = HomeScreen.new()
	home.setup(App.progress.band(), App.progress.feathers(), App.remote.is_online())
	home.my_color = _my_color()
	home.my_flag = _my_flag()
	home.start_pressed.connect(_on_start_pressed)
	home.profile_pressed.connect(_show_profile)
	home.settings_pressed.connect(_show_settings)
	_swap(home)
	App.feedback.play_music(MUSIC_HOME)
	# 다음 판 상대 기록을 미리 1건 받아 둔다. 도착하지 않아도 시작을 막지 않는다.
	App.resolver.prefetch(App.progress.band(), App.commit_extended())
	App.analytics.log_event("home_view", {"band": App.progress.band()})


func _on_start_pressed() -> void:
	App.analytics.log_event("duel_start_tap", {"band": App.progress.band()})
	_start_new_duel()


func _start_new_duel() -> void:
	var band: int = App.progress.band()
	var setup: Dictionary = App.resolver.take_setup(band, App.fallback_seed(band), App.commit_extended())
	var opponent: Opponent = setup["opponent"]
	App.analytics.log_event("opponent_resolved", {"opponent_kind": "bot" if opponent.is_bot() else "record"})
	_start_duel(DuelSession.new(setup["course"], opponent, App.commit_ms(band)))


## ad_allowed: 이 판이 지면 보상형 광고 재도전을 제안할지. 재도전 판에는 다시 제안하지 않는다(판당 1회).
func _start_duel(session: DuelSession, ad_allowed: bool = true) -> void:
	var screen: DuelScreen = _duel_screen(session, false)
	screen.committed.connect(_on_committed.bind(session, false))
	screen.segment_resolved.connect(_save_in_progress.bind(session, ad_allowed))
	screen.finished.connect(_on_duel_finished.bind(session, ad_allowed))
	_swap(screen)
	App.analytics.log_event("level_start", {"band": session.course.band, "segment_count": session.course.segment_count()})


func _start_onboarding() -> void:
	var session: DuelSession = Onboarding.session()
	var screen: DuelScreen = _duel_screen(session, true)
	screen.committed.connect(_on_committed.bind(session, true))
	screen.finished.connect(_on_onboarding_finished.bind(session))
	_swap(screen)
	App.analytics.log_event("tutorial_begin")


func _duel_screen(session: DuelSession, tutorial: bool) -> DuelScreen:
	var screen: DuelScreen = DuelScreen.new()
	screen.setup(session, tutorial)
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
	App.analytics.log_event("cosmetic_view")


func _show_settings() -> void:
	var screen: SettingsScreen = SettingsScreen.new()
	screen.setup(App.progress)
	screen.back_pressed.connect(_show_home)
	screen.settings_changed.connect(_on_setting_changed)
	screen.reset_confirmed.connect(_on_reset)
	_swap(screen)
	App.analytics.log_event("settings_view")


func _on_setting_changed(key: String) -> void:
	App.apply_settings()
	if key == "commit_extended":
		App.analytics.log_event("commit_time_extend_toggle", {"on": App.commit_extended()})
	if key == "locale":
		# 언어를 바꾸면 화면 문구를 새 언어로 다시 만든다.
		_show_settings()
	elif key == "music":
		App.feedback.play_music(MUSIC_HOME)


## 진행 초기화: 로컬 진행과 원격 기록 문서를 함께 비우고 온보딩부터 다시 시작한다(02 리셋 계약).
func _on_reset() -> void:
	App.progress.reset_progress()
	App.progress.write()
	App.remote.request_clear()
	_start_onboarding()


func _on_committed(step: Dictionary, session: DuelSession, tutorial: bool) -> void:
	var gate: Gate = session.course.gates_at(int(step["segment"]))[int(step["pick_me"])]
	App.analytics.log_event("gate_commit", {
		"gate_type": Gate.kind_name(gate.kind),
		"is_split": bool(step["split"]),
		"my_crowd": int(step["before_me"]),
		"opp_crowd": int(step["before_opp"]),
		"auto": bool(step["auto"]),
		"tutorial": tutorial,
	})
	if tutorial and (step["events"] as Array).has("yield_to_a"):
		App.analytics.log_event("onboarding_split_seen", {"segment_index": int(step["segment"])})


func _save_in_progress(session: DuelSession, ad_allowed: bool) -> void:
	App.progress.set_in_progress({"session": session.to_dict(), "ad_allowed": ad_allowed})
	App.progress.write()


func _on_duel_finished(scene: Image, session: DuelSession, ad_allowed: bool) -> void:
	var reward: Dictionary = App.progress.apply_result(session.result(), App.today())
	App.progress.set_in_progress({})
	App.record_sync.submit(session.to_record("", App.now_unix(), App.commit_extended()))
	App.session_duel_count += 1
	App.analytics.log_event("level_end", {
		"band": session.course.band, "segment_count": session.course.segment_count(), "result": session.result(),
	})
	App.analytics.log_event("duel_finish", {"session_duel_index": App.session_duel_count})
	_show_result(session, scene, reward, false, ad_allowed)


func _on_onboarding_finished(scene: Image, session: DuelSession) -> void:
	var feathers: int = App.progress.complete_onboarding()
	App.progress.write()
	App.analytics.log_event("tutorial_complete")
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
	var retries: int = 0
	if ad_allowed and App.remote.is_online() and App.ads.is_available():
		retries = App.progress.ad_retries_left(App.today())
	var result: ResultScreen = ResultScreen.new()
	result.setup(session, scene, reward, tutorial, retries)
	result.rematch_pressed.connect(_on_rematch)
	result.home_pressed.connect(_show_home)
	result.share_pressed.connect(_on_share.bind(result, session, scene))
	result.ad_retry_pressed.connect(_on_ad_retry.bind(session))
	_swap(result)
	App.analytics.log_event("result_view", {"result": session.result(), "tutorial": tutorial})


func _on_rematch() -> void:
	App.analytics.log_event("rematch_tap")
	_start_new_duel()


func _on_share(result: ResultScreen, session: DuelSession, scene: Image) -> void:
	App.analytics.log_event("result_share_tap", {"result": session.result()})
	# 카드를 그리는 사이 결과 화면이 닫힐 수 있으므로 필요한 값은 먼저 꺼내 둔다.
	var color: Color = result.result_color()
	var border: String = Cosmetics.value_of(App.progress.equipped(Cosmetics.Slot.BORDER))
	var saved: int = 0
	for card_size: Vector2i in [ShareCard.SQUARE, ShareCard.VERTICAL]:
		var image: Image = await ShareCard.render(self, card_size, scene, session.crowd_me, session.crowd_opp, color, border)
		var name: String = "result-%d-%dx%d" % [App.now_unix(), card_size.x, card_size.y]
		if not App.share.share_image(image, name).is_empty():
			saved += 1
	if is_instance_valid(result):
		result.show_toast(tr("SHARE_SAVED") if saved == 2 else tr("SHARE_FAILED"))


## 보상형 광고 재도전: 옵트인 → 광고 → 끝까지 봤을 때만 같은 코스·같은 상대로 1회 재도전.
func _on_ad_retry(session: DuelSession) -> void:
	if _ad_in_flight:
		return
	_ad_in_flight = true
	var result: Control = _current
	if result is ResultScreen:
		(result as ResultScreen).set_busy(true)
	App.analytics.log_event("rewarded_retry_optin", {"placement": "result_retry"})
	App.ads.show()
	var rewarded: bool = await App.ads.finished
	_ad_in_flight = false
	if is_instance_valid(result) and result is ResultScreen:
		(result as ResultScreen).set_busy(false)
	# 광고를 끝까지 보지 않았거나, 기다리는 사이 다른 화면으로 떠났으면 재도전하지 않는다.
	if not rewarded or _current != result:
		return
	App.analytics.log_event("ad_reward_earned", {"placement": "result_retry"})
	App.progress.use_ad_retry(App.today())
	App.progress.write()
	_start_duel(DuelSession.new(session.course, session.opponent, session.commit_ms), false)
