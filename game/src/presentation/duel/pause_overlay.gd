class_name PauseOverlay
extends ColorRect
## 일시정지. 트리를 멈춰 확약 타이머와 연출을 함께 세운다. 이 노드만 멈춘 동안에도 동작한다.
## 대국 중 이탈 경로는 이것뿐이며 판을 버리는 버튼은 두지 않는다(03 내비게이션).

signal resumed

var _resume: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	color = Color(Palette.INK, 0.55)
	visible = false
	var panel: PanelContainer = PanelContainer.new()
	var box: StyleBoxFlat = UiTheme.pill(Palette.PANEL, 20.0, Palette.INK)
	box.set_border_width_all(int(2 * Palette.DP))
	box.set_content_margin_all(24 * Palette.DP)
	panel.add_theme_stylebox_override("panel", box)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	add_child(panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", int(20 * Palette.DP))
	panel.add_child(column)
	var title: Label = Label.new()
	title.text = tr("PAUSED")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", UiTheme.text_font(700))
	title.add_theme_font_size_override("font_size", int(24 * Palette.DP))
	column.add_child(title)
	_resume = Button.new()
	UiTheme.primary_button(_resume, tr("RESUME"))
	_resume.custom_minimum_size.x = 220 * Palette.DP
	_resume.pressed.connect(_close)
	column.add_child(_resume)
	resized.connect(func() -> void: panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER))


func open() -> void:
	visible = true
	get_tree().paused = true
	_resume.grab_focus()


func _close() -> void:
	visible = false
	get_tree().paused = false
	resumed.emit()
