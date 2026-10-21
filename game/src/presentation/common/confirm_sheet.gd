class_name ConfirmSheet
extends ColorRect
## 확인 창. 되돌리기 어려운 행동(해금, 진행 초기화) 앞과 긴 안내문에 쓴다.
## 확인 버튼 문구가 비어 있으면 닫기 버튼 하나만 있는 안내 창이 된다.

signal confirmed
signal closed

var _message: String
var _confirm_text: String
var _danger: bool


func _init(message: String, confirm_text: String = "", danger: bool = false) -> void:
	_message = message
	_confirm_text = confirm_text
	_danger = danger


func _ready() -> void:
	var dp: float = Palette.DP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color = Color(Palette.INK, 0.55)
	var panel: PanelContainer = PanelContainer.new()
	var box: StyleBoxFlat = UiTheme.pill(Palette.PANEL, 20.0, Palette.INK)
	box.set_border_width_all(int(2 * dp))
	box.set_content_margin_all(22 * dp)
	panel.add_theme_stylebox_override("panel", box)
	var panel_width: float = minf(300 * dp, size.x - 16 * dp)
	panel.custom_minimum_size.x = panel_width
	add_child(panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", int(18 * dp))
	panel.add_child(column)
	var text: Label = Label.new()
	text.text = _message
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size.x = panel_width - 44 * dp
	text.add_theme_font_override("font", UiTheme.text_font(500))
	text.add_theme_font_size_override("font_size", int(16 * dp))
	column.add_child(text)
	var row: VBoxContainer = VBoxContainer.new()
	row.add_theme_constant_override("separation", int(10 * dp))
	column.add_child(row)
	var close: Button = Button.new()
	UiTheme.secondary_button(close, tr("CANCEL") if not _confirm_text.is_empty() else tr("OK"))
	close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close.pressed.connect(_close)
	row.add_child(close)
	if not _confirm_text.is_empty():
		var ok: Button = Button.new()
		UiTheme.primary_button(ok, _confirm_text)
		if _danger:
			var style: StyleBoxFlat = ok.get_theme_stylebox("normal").duplicate()
			style.bg_color = Palette.INK
			ok.add_theme_stylebox_override("normal", style)
			ok.add_theme_stylebox_override("hover", style)
		ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ok.pressed.connect(func() -> void:
			confirmed.emit()
			queue_free()
		)
		row.add_child(ok)
	close.grab_focus.call_deferred()
	var center: Callable = func() -> void:
		panel.reset_size()
		panel.position = (size - panel.size) / 2.0
	resized.connect(center.call_deferred)
	panel.minimum_size_changed.connect(center.call_deferred)
	center.call_deferred()


func _close() -> void:
	closed.emit()
	queue_free()
