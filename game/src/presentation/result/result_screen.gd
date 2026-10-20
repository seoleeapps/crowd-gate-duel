class_name ResultScreen
extends Control
## SCR-003 결과 화면. 승패를 한 장면으로 남기고 공유 카드를 만든다.
##
## 시선 순서: 충돌 직후 정지 장면 → 승패 단어 → 양쪽 최종 수 → 행동 버튼.
## 광고 진입점은 이 화면에만 있다. 패배했을 때 보상형 광고 재도전 1자리를 옵트인 버튼과
## 사전 고지로 보여 주고, 오프라인이거나 오늘 상한을 다 쓰면 숨긴다(DEC-007).

signal rematch_pressed
signal share_pressed
signal home_pressed

var session: DuelSession
var scene: Image
## { "feathers": int, "daily_first_win": bool, "band_before": int, "band_after": int }
var reward: Dictionary = {}
var tutorial: bool = false
var toast: Label


func setup(session_in: DuelSession, scene_in: Image, reward_in: Dictionary, tutorial_in: bool) -> void:
	session = session_in
	scene = scene_in
	reward = reward_in
	tutorial = tutorial_in


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dp: float = Palette.DP
	var bg: ColorRect = ColorRect.new()
	bg.color = Palette.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, int(20 * dp))
	margin.add_theme_constant_override("margin_top", int(16 * dp))
	add_child(margin)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", int(10 * dp))
	margin.add_child(column)

	column.add_child(_scene_view())
	column.add_child(_result_word())
	column.add_child(_score_row())
	if not tutorial:
		var decisive: Control = _decisive_row()
		if decisive != null:
			column.add_child(decisive)
	var rewards: Label = _reward_line()
	if rewards != null:
		column.add_child(rewards)

	column.add_child(_buttons())
	toast = _text("", 14, 500, Palette.INK_SOFT)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(toast)


func result_word() -> String:
	match session.result():
		DuelEngine.RESULT_A_WIN:
			return tr("RESULT_WIN")
		DuelEngine.RESULT_B_WIN:
			return tr("RESULT_LOSS")
	return tr("RESULT_DRAW")


func result_color() -> Color:
	match session.result():
		DuelEngine.RESULT_A_WIN:
			return Palette.CHIP_MINE
		DuelEngine.RESULT_B_WIN:
			return Palette.CHIP_OPP
	return Palette.TIE


func _scene_view() -> Control:
	var frame: PanelContainer = PanelContainer.new()
	var box: StyleBoxFlat = UiTheme.pill(Palette.PANEL, 16.0, Palette.INK)
	box.set_border_width_all(int(2 * Palette.DP))
	frame.add_theme_stylebox_override("panel", box)
	# 장면은 남는 세로 공간을 모두 쓴다. 짧은 화면에서도 버튼이 화면 안에 남는다.
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var rect: TextureRect = TextureRect.new()
	rect.custom_minimum_size = Vector2(0, 72 * Palette.DP)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if scene != null and not scene.is_empty():
		rect.texture = ImageTexture.create_from_image(scene_crop(scene))
	frame.add_child(rect)
	frame.clip_contents = true
	return frame


## 충돌 장면에서 정상 부근만 잘라 낸다. 공유 카드도 같은 잘라 낸 장면을 쓴다.
static func scene_crop(image: Image) -> Image:
	var w: int = image.get_width()
	var h: int = image.get_height()
	# 위쪽 진행 리본과 일시정지 버튼은 장면이 아니므로 잘라 낸다.
	var top: int = mini(int(float(w) / 360.0 * DuelScreen.RIBBON_DP), h - 1)
	var crop_h: int = mini(h - top, int(float(w) * 0.9))
	return image.get_region(Rect2i(0, top, w, crop_h))


func _result_word() -> Label:
	var label: Label = _text(result_word(), 42, 800, result_color())
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _score_row() -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", int(14 * Palette.DP))
	var me: CountChip = CountChip.new(CountChip.Kind.MINE)
	me.set_value(session.crowd_me)
	row.add_child(me)
	row.add_child(_text(":", 28, 800, Palette.INK))
	var opp: CountChip = CountChip.new(CountChip.Kind.OPP)
	opp.set_value(session.crowd_opp)
	if session.opponent.is_bot():
		opp.set_badge(CrowdView.Badge.BOT)
	elif session.opponent.is_tutorial():
		opp.set_badge(CrowdView.Badge.PRACTICE)
	row.add_child(opp)
	return row


## 격차가 가장 크게 움직인 구간을 되짚는다. 다음 판의 학습이 된다.
func _decisive_row() -> Control:
	var index: int = session.decisive_segment()
	if index < 0:
		return null
	var entry: Dictionary = session.trace[index]
	var gates: Array[Gate] = session.course.gates_at(index)
	var panel: PanelContainer = PanelContainer.new()
	var box: StyleBoxFlat = UiTheme.pill(Palette.PANEL, 14.0, Palette.STEP_LINE)
	box.set_content_margin_all(12 * Palette.DP)
	panel.add_theme_stylebox_override("panel", box)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", int(6 * Palette.DP))
	panel.add_child(column)
	column.add_child(_text(tr("DECISIVE") % (index + 1), 14, 700, Palette.INK_SOFT))
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", int(12 * Palette.DP))
	row.add_child(_pick_badge(tr("CHIP_ME"), true, gates[int(entry["pick_me"])]))
	row.add_child(_pick_badge(_opp_word(), false, gates[int(entry["pick_opp"])]))
	var swing: int = (int(entry["me"]) - int(entry["opp"])) - (int(entry["before_me"]) - int(entry["before_opp"]))
	row.add_child(_text("%+d" % swing, 22, 800, Palette.CHIP_MINE if swing >= 0 else Palette.CHIP_OPP))
	column.add_child(row)
	return panel


func _pick_badge(who: String, mine: bool, gate: Gate) -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", int(4 * Palette.DP))
	row.add_child(_text(who, 13, 700, Palette.chip_color(mine)))
	var icon: TextureRect = TextureRect.new()
	icon.texture = GateCell.ICONS[gate.kind]
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(22, 22) * Palette.DP
	row.add_child(icon)
	var value: Label = _text(GateCell.label_for(gate), 18, 700, Palette.INK)
	value.add_theme_font_override("font", UiTheme.number_font(700))
	row.add_child(value)
	return row


func _reward_line() -> Label:
	var parts: PackedStringArray = []
	var feathers: int = int(reward.get("feathers", 0))
	if feathers > 0:
		parts.append(tr("FEATHERS_GAINED") % feathers)
	if bool(reward.get("daily_first_win", false)):
		parts.append(tr("DAILY_FIRST_WIN"))
	if int(reward.get("band_after", 0)) > int(reward.get("band_before", 0)):
		parts.append(tr("BAND_UP") % int(reward["band_after"]))
	if not (reward.get("items", []) as Array).is_empty():
		parts.append(tr("NEW_ITEM"))
	if parts.is_empty():
		return null
	var label: Label = _text(" · ".join(parts), 16, 700, Palette.INK)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _buttons() -> Control:
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", int(10 * Palette.DP))
	var primary: Button = Button.new()
	if tutorial:
		UiTheme.primary_button(primary, tr("HOME"))
		primary.pressed.connect(func() -> void: home_pressed.emit())
		column.add_child(primary)
		return column
	UiTheme.primary_button(primary, tr("REMATCH"))
	primary.pressed.connect(func() -> void: rematch_pressed.emit())
	column.add_child(primary)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", int(10 * Palette.DP))
	var share: Button = Button.new()
	UiTheme.secondary_button(share, tr("SHARE"))
	share.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	share.pressed.connect(func() -> void: share_pressed.emit())
	row.add_child(share)
	var home: Button = Button.new()
	UiTheme.secondary_button(home, tr("HOME"))
	home.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	home.pressed.connect(func() -> void: home_pressed.emit())
	row.add_child(home)
	column.add_child(row)
	primary.grab_focus.call_deferred()
	return column


## 광고를 보는 동안 모든 버튼을 막는다. 연타와 광고 중 이탈을 함께 막는다.
func set_busy(busy: bool) -> void:
	for node: Node in find_children("*", "Button", true, false):
		(node as Button).disabled = busy


func show_toast(message: String) -> void:
	toast.text = message


func _opp_word() -> String:
	if session.opponent.is_bot():
		return tr("CHIP_BOT")
	if session.opponent.is_tutorial():
		return tr("CHIP_PRACTICE")
	return tr("CHIP_OPP")


func _text(value: String, size_dp: int, weight: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = value
	label.add_theme_font_override("font", UiTheme.text_font(weight))
	label.add_theme_font_size_override("font_size", int(size_dp * Palette.DP))
	label.add_theme_color_override("font_color", color)
	return label
