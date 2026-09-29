class_name DuelScreen
extends Control
## SCR-002 대국 화면. 온보딩(SCR-004)도 같은 화면을 쓴다.
##
## 이 화면은 입력을 `DuelSession` 명령으로 바꾸고 세션이 돌려준 해소 결과를 연출할 뿐이다.
## 판정은 하지 않는다. 저장·기록·분석은 신호를 받은 화면 전환 루트가 맡는다.
##
## 구역(시안 기준 780dp 높이): 진행 리본 9% · 언덕길 63% · 게이트 띠 21% · 확약 타이머 7%.
## 리본은 언덕길 위에 겹쳐 놓고, 긴 화면에서는 언덕길만 늘어나며 게이트 띠 높이는 고정이다.

signal committed(step: Dictionary)
signal segment_resolved
signal finished(scene: Image)

const RIBBON_DP: float = 70.0
const BAND_DP: float = 164.0
const TIMER_DP: float = 54.0
const INTRO_SECONDS: float = 1.2
const HOLD_SECONDS: float = 0.45

var session: DuelSession
var tutorial: bool = false

var world: WorldView
var band: GateBand
var ribbon: ProgressRibbon
var timer: CommitTimer
var _pause: PauseOverlay
var _flash: ColorRect
var _ms_carry: float = 0.0
var _waiting_commit: bool = false


func setup(session_in: DuelSession, tutorial_in: bool = false) -> void:
	session = session_in
	tutorial = tutorial_in


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	world = WorldView.new()
	add_child(world)
	ribbon = ProgressRibbon.new()
	ribbon.pause_pressed.connect(_open_pause)
	add_child(ribbon)
	band = GateBand.new()
	band.picked.connect(_on_picked)
	add_child(band)
	timer = CommitTimer.new()
	add_child(timer)
	_flash = ColorRect.new()
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.color = Color(0, 0, 0, 0)
	add_child(_flash)
	_pause = PauseOverlay.new()
	_pause.resumed.connect(_on_resumed)
	add_child(_pause)
	resized.connect(_layout)
	_layout()
	world.set_opponent_badge(_badge())
	_run.call_deferred()


func _notification(what: int) -> void:
	# 앱이 백그라운드로 가면 확약 대기를 멈추고, 돌아오면 남은 시간부터 재개한다(02 상태 머신).
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if is_node_ready() and session != null and not session.is_finished():
			_open_pause()


func _process(delta: float) -> void:
	if not _waiting_commit:
		return
	_ms_carry += delta * 1000.0
	var ms: int = int(_ms_carry)
	_ms_carry -= float(ms)
	var step: Dictionary = session.tick(ms)
	timer.set_time(session.remaining_ms, session.commit_ms)
	if not step.is_empty():
		_on_step(step)


func _layout() -> void:
	var dp: float = Palette.DP
	var band_h: float = BAND_DP * dp
	var timer_h: float = TIMER_DP * dp
	var ribbon_top: float = _safe_top()
	var ribbon_h: float = RIBBON_DP * dp
	var world_bottom: float = size.y - band_h - timer_h
	# 짧은 화면(세로/가로 2 미만)에서는 언덕길을 리본 아래에서 시작해 결승선과 리본이 겹치지 않게 한다.
	# 게이트 띠 높이는 그대로 지킨다(03 반응형 기기 매트릭스).
	var world_top: float = ribbon_top + ribbon_h if size.y / maxf(size.x, 1.0) < 2.0 else 0.0
	world.position = Vector2(0, world_top)
	world.size = Vector2(size.x, world_bottom - world_top)
	ribbon.position = Vector2(0, ribbon_top)
	ribbon.size = Vector2(size.x, ribbon_h)
	band.position = Vector2(0, world_bottom)
	band.size = Vector2(size.x, band_h)
	timer.position = Vector2(0, world_bottom + band_h)
	timer.size = Vector2(size.x, timer_h)
	_flash.size = size
	_pause.size = size


## 노치·펀치홀 아래로 리본을 내린다. 화면 좌표를 이 컨트롤의 좌표로 바꿔 쓴다.
func _safe_top() -> float:
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	var screen: Vector2i = DisplayServer.screen_get_size()
	if screen.y <= 0 or safe.size.y <= 0:
		return 0.0
	return maxf(0.0, float(safe.position.y) * size.y / float(screen.y))


func _run() -> void:
	world.set_standing(session.crowd_me, session.crowd_opp, _progress(), false)
	ribbon.set_progress(maxi(session.segment_index + 1, 1), session.course.segment_count())
	timer.set_time(session.commit_ms, session.commit_ms)
	await get_tree().create_timer(INTRO_SECONDS * (0.6 if tutorial else 1.0)).timeout
	while not session.is_finished():
		# 저장된 판을 복원하면 이미 확약 대기 중일 수 있다.
		if session.phase != DuelSession.Phase.COMMIT_WAIT and not session.present_next():
			break
		ribbon.set_progress(session.segment_index + 1, session.course.segment_count())
		world.opp_chip.set_locked(true)
		var guided: int = Onboarding.guided_pick(session.segment_index) if tutorial else -1
		await band.present(session.current_gates(), guided).finished
		_ms_carry = 0.0
		_waiting_commit = true
		var step: Dictionary = await committed
		await _resolve(step)
		segment_resolved.emit()
	await _finale()


func _on_picked(index: int) -> void:
	if not _waiting_commit:
		return
	var step: Dictionary = session.commit(index)
	if not step.is_empty():
		_on_step(step)


func _on_step(step: Dictionary) -> void:
	_waiting_commit = false
	band.lock(int(step["pick_me"]))
	timer.set_time(0, session.commit_ms)
	committed.emit(step)


## 공개 → 사건 연출 → 무리 변화. 한 구간의 해소 연출은 1.5초 안쪽이다(02 경험 타임라인).
func _resolve(step: Dictionary) -> void:
	world.opp_chip.set_locked(false)
	await band.reveal(step, _opp_label()).finished
	var events: Array = step["events"]
	var d_me: int = int(step["me"]) - int(step["before_me"])
	var d_opp: int = int(step["opp"]) - int(step["before_opp"])
	if events.has("yield_to_a"):
		world.block(false)
	elif events.has("yield_to_b"):
		world.block(true)
	if events.has("steal_a"):
		world.transfer(true, d_me)
	elif events.has("steal_b"):
		world.transfer(false, d_opp)
	elif events.has("shield_counter_b"):
		await world.counter(true).finished
		world.transfer(false, d_opp)
	elif events.has("shield_counter_a"):
		await world.counter(false).finished
		world.transfer(true, d_me)
	if d_me > 0:
		world.burst(true, d_me)
	elif d_me < 0:
		world.sink(true, -d_me)
	if d_opp > 0:
		world.burst(false, d_opp)
	elif d_opp < 0:
		world.sink(false, -d_opp)
	await world.set_standing(int(step["me"]), int(step["opp"]), _progress(), true).finished
	await get_tree().create_timer(HOLD_SECONDS).timeout


## 결승 충돌: 두 무리가 정상에서 부딪히고 화면이 0.3초 멈춘 뒤 이긴 쪽 색으로 한 번 물든다.
func _finale() -> void:
	await world.play_finale(session.crowd_me, session.crowd_opp).finished
	var result: int = session.result()
	var tint: Color = Palette.TIE
	if result == DuelEngine.RESULT_A_WIN:
		tint = Palette.MINE
	elif result == DuelEngine.RESULT_B_WIN:
		tint = Palette.OPP
	_shake()
	await get_tree().create_timer(0.3).timeout
	_flash.color = Color(tint, 0.28)
	var fade: Tween = create_tween()
	fade.tween_property(_flash, "color:a", 0.0, 0.6)
	# 충돌 직후 장면을 결과 화면과 공유 카드에 쓴다. 한 프레임 뒤의 화면이 곧 충돌 정지 장면이다.
	# 화면이 없는 환경(헤드리스 검사)에는 그려진 장면이 없으므로 장면 없이 결과 화면을 띄운다.
	await get_tree().process_frame
	var scene: Image = null
	if DisplayServer.get_name() != "headless":
		scene = get_viewport().get_texture().get_image()
	await fade.finished
	await get_tree().create_timer(0.6).timeout
	finished.emit(scene)


func _shake() -> void:
	var tween: Tween = create_tween()
	for i: int in range(4):
		var offset: Vector2 = Vector2(8 if i % 2 == 0 else -8, 4 if i < 2 else -4) * Palette.DP
		tween.tween_property(world, "position", offset, 0.04)
	tween.tween_property(world, "position", Vector2.ZERO, 0.05)


func _open_pause() -> void:
	if _pause.visible or session == null:
		return
	session.pause()
	_pause.open()


func _on_resumed() -> void:
	session.resume()


func _progress() -> float:
	return float(session.segment_index + 1) / float(maxi(session.course.segment_count(), 1))


func _badge() -> CrowdView.Badge:
	if session.opponent.is_bot():
		return CrowdView.Badge.BOT
	if session.opponent.is_tutorial():
		return CrowdView.Badge.PRACTICE
	return CrowdView.Badge.NONE


func _opp_label() -> String:
	match _badge():
		CrowdView.Badge.BOT:
			return tr("CHIP_BOT")
		CrowdView.Badge.PRACTICE:
			return tr("CHIP_PRACTICE")
	return tr("CHIP_OPP")
