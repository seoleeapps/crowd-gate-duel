class_name CommitTimer
extends Control
## 하단 확약 타이머 바. 남은 시간을 막대와 숫자로 함께 보여 준다.
## 마지막 1초에는 막대가 진영색으로 바뀌고 숫자가 커진다. 색 하나에만 기대지 않는다.

var ratio: float = 1.0
var seconds_left: float = 0.0
var _label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = Label.new()
	_label.add_theme_font_override("font", UiTheme.number_font(700))
	_label.add_theme_color_override("font_color", Palette.INK)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_label)


func set_time(remaining_ms: int, total_ms: int) -> void:
	ratio = clampf(float(remaining_ms) / float(maxi(total_ms, 1)), 0.0, 1.0)
	seconds_left = float(remaining_ms) / 1000.0
	var warn: bool = remaining_ms > 0 and remaining_ms <= 1000
	_label.text = "%.1f" % seconds_left
	_label.add_theme_font_size_override("font_size", int((24 if warn else 20) * Palette.DP))
	_label.size = Vector2(56, size.y / Palette.DP) * Palette.DP
	_label.position = Vector2(size.x - _label.size.x - 16 * Palette.DP, (size.y - _label.get_minimum_size().y) / 2.0)
	queue_redraw()


func _draw() -> void:
	var dp: float = Palette.DP
	draw_rect(Rect2(Vector2.ZERO, size), Palette.PANEL)
	var track: Rect2 = Rect2(Vector2(16 * dp, size.y / 2.0 - 5 * dp), Vector2(size.x - 100 * dp, 10 * dp))
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.set_corner_radius_all(int(5 * dp))
	box.anti_aliasing = true
	box.bg_color = Palette.TIMER_TRACK
	draw_style_box(box, track)
	if ratio > 0.0:
		var fill: StyleBoxFlat = box.duplicate()
		fill.bg_color = Palette.CHIP_MINE if seconds_left <= 1.0 else Palette.INK
		draw_style_box(fill, Rect2(track.position, Vector2(maxf(track.size.x * ratio, 10 * dp), track.size.y)))
