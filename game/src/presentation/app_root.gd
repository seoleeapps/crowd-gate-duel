extends Control
## 화면 전환 루트. 03 내비게이션 그래프를 따른다.
##
##   첫 실행 → 온보딩 대국 → 결과 → 홈
##   홈 → 대국 → 결과 → 홈 / 한 판 더 / 보상 광고 재도전
##
## 화면은 입력과 연출만 맡고, 판 결과 반영·기록 업로드·진행 저장·분석 이벤트는 여기서 처리한다.

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


func _show_home() -> void:
	var home: HomeScreen = HomeScreen.new()
	home.setup(App.progress.band(), App.progress.feathers(), App.remote.is_online())
	home.start_pressed.connect(_on_start_pressed)
	_swap(home)
	# 다음 판 상대 기록을 미리 1건 받아 둔다. 도착하지 않아도 시작을 막지 않는다.
	App.resolver.prefetch(App.progress.band())
	App.analytics.log_event("home_view", {"band": App.progress.band()})


func _on_start_pressed() -> void:
	App.analytics.log_event("duel_start_tap", {"band": App.progress.band()})
	_start_new_duel()


func _start_new_duel() -> void:
	var band: int = App.progress.band()
	var setup: Dictionary = App.resolver.take_setup(band, App.fallback_seed(band))
	var opponent: Opponent = setup["opponent"]
	App.analytics.log_event("opponent_resolved", {"opponent_kind": "bot" if opponent.is_bot() else "record"})
	_start_duel(DuelSession.new(setup["course"], opponent, App.commit_ms(band)))


## ad_allowed: 이 판이 지면 보상형 광고 재도전을 제안할지. 재도전 판에는 다시 제안하지 않는다(판당 1회).
func _start_duel(session: DuelSession, ad_allowed: bool = true) -> void:
	var screen: DuelScreen = DuelScreen.new()
	screen.setup(session)
	screen.committed.connect(_on_committed.bind(session, false))
	screen.segment_resolved.connect(_save_in_progress.bind(session, ad_allowed))
	screen.finished.connect(_on_duel_finished.bind(session, ad_allowed))
	_swap(screen)
	App.analytics.log_event("level_start", {"band": session.course.band, "segment_count": session.course.segment_count()})


func _start_onboarding() -> void:
	var session: DuelSession = Onboarding.session()
	var screen: DuelScreen = DuelScreen.new()
	screen.setup(session, true)
	screen.committed.connect(_on_committed.bind(session, true))
	screen.finished.connect(_on_onboarding_finished.bind(session))
	_swap(screen)
	App.analytics.log_event("tutorial_begin")


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
	App.record_sync.submit(session.to_record("", App.now_unix()))
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
	_show_result(session, scene, {"feathers": feathers}, true, false)


func _show_result(session: DuelSession, scene: Image, reward: Dictionary, tutorial: bool, ad_allowed: bool) -> void:
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
	var saved: int = 0
	for card_size: Vector2i in [ShareCard.SQUARE, ShareCard.VERTICAL]:
		var image: Image = await ShareCard.render(self, card_size, scene, session.crowd_me, session.crowd_opp, color)
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
