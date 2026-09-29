class_name ProgressRibbon
extends Control
## 상단 진행 리본: "4/7" 과 구간 칸, 그리고 판 중 유일한 버튼인 일시정지.

signal pause_pressed

var total: int = 5
var current: int = 0
var _label: Label
var _pause: Button


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = Label.new()
	_label.add_theme_font_override("font", UiTheme.number_font(700))
	_label.add_theme_font_size_override("font_size", int(17 * Palette.DP))
	_label.add_theme_color_override("font_color", Palette.INK)
	add_child(_label)
	_pause = Button.new()
	_pause.accessibility_name = tr("A11Y_PAUSE")
	_pause.custom_minimum_size = Vector2(48, 48) * Palette.DP
	_pause.size = _pause.custom_minimum_size
	var box: StyleBoxFlat = UiTheme.pill(Palette.PANEL, 12.0, Palette.STEP_ON)
	box.set_border_width_all(int(1.5 * Palette.DP))
	for state: String in ["normal", "hover", "focus"]:
		_pause.add_theme_stylebox_override(state, box)
	var pressed_box: StyleBoxFlat = box.duplicate()
	pressed_box.bg_color = Palette.TIMER_TRACK
	_pause.add_theme_stylebox_override("pressed", pressed_box)
	_pause.pressed.connect(func() -> void: pause_pressed.emit())
	_pause.draw.connect(_draw_pause_icon)
	add_child(_pause)
	resized.connect(_layout)
	_layout()


func set_progress(current_in: int, total_in: int) -> void:
	current = current_in
	total = total_in
	_label.text = "%d/%d" % [current, total]
	queue_redraw()


func _layout() -> void:
	var dp: float = Palette.DP
	_label.position = Vector2(14 * dp, (size.y - _label.size.y) / 2.0)
	_pause.position = Vector2(size.x - _pause.size.x - 12 * dp, (size.y - _pause.size.y) / 2.0)
	queue_redraw()


func _draw() -> void:
	var dp: float = Palette.DP
	var left: float = 58 * dp
	var right: float = size.x - 76 * dp
	var gap: float = 6 * dp
	var w: float = (right - left - gap * float(total - 1)) / float(maxi(total, 1))
	var h: float = 8 * dp
	var y: float = size.y / 2.0 - h / 2.0
	for i: int in range(total):
		var rect: Rect2 = Rect2(Vector2(left + float(i) * (w + gap), y), Vector2(w, h))
		var step: int = i + 1
		if step < current:
			draw_style_box(_step_box(Palette.STEP_ON, Palette.STEP_ON, 0), rect)
		elif step == current:
			# 지금 구간은 크고 굵은 외곽선으로. 색이 아니라 모양으로도 구분된다.
			draw_style_box(_step_box(Palette.PANEL, Palette.STEP_ON, 2), rect.grow(3 * dp))
		else:
			draw_style_box(_step_box(Palette.PANEL, Palette.STEP_LINE, 1), rect)


func _step_box(bg: Color, border: Color, width_dp: int) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(int(float(width_dp) * Palette.DP))
	box.set_corner_radius_all(int(6 * Palette.DP))
	box.anti_aliasing = true
	return box


func _draw_pause_icon() -> void:
	var dp: float = Palette.DP
	var c: Vector2 = _pause.size / 2.0
	for dx: float in [-5.0, 5.0]:
		_pause.draw_rect(Rect2(c + Vector2(dx * dp - 2.5 * dp, -8 * dp), Vector2(5, 16) * dp), Palette.INK)
