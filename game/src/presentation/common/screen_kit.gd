class_name ScreenKit
extends RefCounted
## 보조 화면(꾸미기·설정)이 함께 쓰는 틀: 뒤로 버튼이 있는 머리줄, 손가락으로 끌어 스크롤되는 목록.


## 뒤로 버튼(48dp 이상) + 제목 + 오른쪽 위젯(선택).
static func header(title: String, on_back: Callable, right: Control = null) -> HBoxContainer:
	var dp: float = Palette.DP
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", int(12 * dp))
	var back: Button = Button.new()
	back.text = "‹"
	back.accessibility_name = TranslationServer.translate("BACK")
	back.custom_minimum_size = Vector2(48, 48) * dp
	back.add_theme_font_override("font", UiTheme.number_font(700))
	back.add_theme_font_size_override("font_size", int(30 * dp))
	var box: StyleBoxFlat = UiTheme.pill(Palette.PANEL, 12.0, Palette.STEP_ON)
	for state: String in ["normal", "hover", "focus", "pressed"]:
		back.add_theme_stylebox_override(state, box)
	back.pressed.connect(on_back)
	row.add_child(back)
	var label: Label = Label.new()
	label.text = title
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", UiTheme.text_font(700))
	label.add_theme_font_size_override("font_size", int(22 * dp))
	row.add_child(label)
	if right != null:
		row.add_child(right)
	return row


## 내용 위 어디를 끌어도 스크롤된다. 안의 모든 컨트롤을 PASS 로 바꿔 끌기가 목록까지 닿게 한다
## (godot-game troubleshooting "A ScrollContainer Only Scrolls From Its Scrollbar").
static func scroll(content: Control) -> ScrollContainer:
	var container: ScrollContainer = ScrollContainer.new()
	container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(content)
	pass_through(content)
	content.child_entered_tree.connect(func(_node: Node) -> void: pass_through.call_deferred(content))
	return container


static func pass_through(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_PASS
	for child: Node in node.get_children():
		pass_through(child)


static func section_title(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_override("font", UiTheme.text_font(700))
	label.add_theme_font_size_override("font_size", int(16 * Palette.DP))
	label.add_theme_color_override("font_color", Palette.INK_SOFT)
	return label


static func pill_label(text: String) -> PanelContainer:
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
	panel.add_child(label)
	return panel


static func margin(content: Control) -> MarginContainer:
	var box: MarginContainer = MarginContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "bottom"]:
		box.add_theme_constant_override("margin_" + side, int(16 * Palette.DP))
	box.add_theme_constant_override("margin_top", int(18 * Palette.DP))
	box.add_child(content)
	return box
