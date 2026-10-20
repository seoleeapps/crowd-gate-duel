class_name HomeScreen
extends Control
## SCR-001 홈. 바로 한 판 시작하게 한다.
## 시선 순서: 가운데 큰 시작 버튼 → 내 무리 대기 장면 → 대역 → 깃털.
## 상대 기록 조회는 스피너 없이 뒤에서 한다. 시작 버튼은 늘 바로 누를 수 있다(03 상태 매트릭스).

signal start_pressed
signal profile_pressed
signal settings_pressed

var band: int = 1
var feathers: int = 0
var my_color: Color = Palette.MINE
var my_flag: String = "chevron"

var _start: Button


func setup(band_in: int, feathers_in: int) -> void:
	band = band_in
	feathers = feathers_in


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dp: float = Palette.DP
	var world: WorldView = WorldView.new()
	world.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	world.anchor_bottom = 0.74
	add_child(world)
	world.show_only_mine(CourseGenerator.START_CROWD)
	world.set_my_style(my_color, my_flag)

	var ground: ColorRect = ColorRect.new()
	ground.color = Palette.PANEL
	ground.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ground.anchor_top = 0.74
	add_child(ground)
	var rule: ColorRect = ColorRect.new()
	rule.color = Palette.INK
	rule.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	rule.anchor_top = 0.74
	rule.anchor_bottom = 0.74
	rule.offset_bottom = 2 * dp
	add_child(rule)

	var top: HBoxContainer = HBoxContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 16 * dp
	top.offset_right = -16 * dp
	top.offset_top = 18 * dp
	add_child(top)
	var band_name: String = tr("BAND_%d" % band)
	top.add_child(_pill(tr("BAND_LABEL") % [band, band_name], Palette.INK))
	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	top.add_child(_pill("◆ %d" % feathers, Palette.INK))

	_start = Button.new()
	UiTheme.primary_button(_start, tr("PLAY"))
	_start.accessibility_name = tr("A11Y_START")
	_start.add_theme_font_size_override("font_size", int(26 * dp))
	_start.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_start.anchor_top = 0.74
	_start.anchor_bottom = 0.74
	_start.custom_minimum_size = Vector2(240, 72) * dp
	_start.offset_left = -120 * dp
	_start.offset_right = 120 * dp
	_start.offset_top = 18 * dp
	_start.offset_bottom = 90 * dp
	_start.pressed.connect(func() -> void: start_pressed.emit())
	add_child(_start)

	# 하단 보조 진입점: 꾸미기, 설정(03 SCR-001)
	var bottom: HBoxContainer = HBoxContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 16 * dp
	bottom.offset_right = -16 * dp
	bottom.offset_top = -84 * dp
	bottom.offset_bottom = -20 * dp
	bottom.add_theme_constant_override("separation", int(10 * dp))
	add_child(bottom)
	for pair: Array in [[tr("HOME_PROFILE"), profile_pressed], [tr("HOME_SETTINGS"), settings_pressed]]:
		var button: Button = Button.new()
		UiTheme.secondary_button(button, pair[0])
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var target: Signal = pair[1]
		button.pressed.connect(func() -> void: target.emit())
		bottom.add_child(button)
	_start.grab_focus.call_deferred()


func _pill(text: String, fg: Color) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	var box: StyleBoxFlat = UiTheme.pill(Palette.PANEL, 16.0, Palette.STEP_ON)
	box.content_margin_left = 12 * Palette.DP
	box.content_margin_right = 12 * Palette.DP
	box.content_margin_top = 4 * Palette.DP
	box.content_margin_bottom = 4 * Palette.DP
	panel.add_theme_stylebox_override("panel", box)
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_override("font", UiTheme.number_font(700))
	label.add_theme_font_size_override("font_size", int(16 * Palette.DP))
	label.add_theme_color_override("font_color", fg)
	panel.add_child(label)
	return panel
