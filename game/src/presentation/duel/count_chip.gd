class_name CountChip
extends PanelContainer
## 무리 바로 위에 붙는 군중 수 표식. 별도 수치 패널을 두지 않고 이것만 쓴다(03 SCR-002).
## 동수일 때는 진영색이 아닌 중립 표식 하나로 "= 동수"를 보여 준다.

const BOT_ICON: Texture2D = preload("res://assets/art/bot.svg")
const LOCK_ICON: Texture2D = preload("res://assets/art/lock.svg")

enum Kind { MINE, OPP, TIE }

var kind: Kind = Kind.MINE
var _badge: TextureRect
var _badge_text: Label
var _label: Label
var _number: Label
var _lock: TextureRect


func _init(kind_in: Kind) -> void:
	kind = kind_in
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dp: float = Palette.DP
	var box: StyleBoxFlat = UiTheme.pill(_bg())
	if kind == Kind.TIE:
		box.border_color = Palette.TIE
		box.set_border_width_all(int(2 * dp))
	box.content_margin_left = 12 * dp
	box.content_margin_right = 12 * dp
	box.content_margin_top = 2 * dp
	box.content_margin_bottom = 2 * dp
	add_theme_stylebox_override("panel", box)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", int(6 * dp))
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(row)

	_badge = _icon(BOT_ICON, 15)
	_badge.visible = false
	row.add_child(_badge)
	_badge_text = _text(13, 700)
	_badge_text.visible = false
	row.add_child(_badge_text)
	_label = _text(13, 700)
	row.add_child(_label)
	_number = Label.new()
	_number.add_theme_font_override("font", UiTheme.number_font(700))
	_number.add_theme_font_size_override("font_size", int(21 * dp))
	_number.add_theme_color_override("font_color", _fg())
	row.add_child(_number)
	_lock = _icon(LOCK_ICON, 14)
	_lock.visible = false
	row.add_child(_lock)

	match kind:
		Kind.MINE:
			_label.text = tr("CHIP_ME")
		Kind.OPP:
			_label.text = tr("CHIP_OPP")
		Kind.TIE:
			_label.text = tr("TIE")
			_number.text = "="
			row.move_child(_number, 0)


func set_value(value: int) -> void:
	if kind != Kind.TIE:
		_number.text = str(value)


## 봇이면 로봇 아이콘과 "봇", 연습 상대면 "연습". 사람 기록이면 아무것도 붙이지 않는다.
func set_badge(badge: CrowdView.Badge) -> void:
	_badge.visible = badge == CrowdView.Badge.BOT
	_badge_text.visible = badge != CrowdView.Badge.NONE
	_badge_text.text = tr("CHIP_BOT") if badge == CrowdView.Badge.BOT else tr("CHIP_PRACTICE")
	_label.visible = badge == CrowdView.Badge.NONE


## 상대의 선택이 잠겼음을 보여 준다. 무엇을 골랐는지는 공개 전까지 보이지 않는다.
func set_locked(locked: bool) -> void:
	_lock.visible = locked


## 발끝 좌표(무리 윗부분)에 표식의 꼬리가 오도록 놓는다.
func place_above(point: Vector2) -> void:
	reset_size()
	position = point - Vector2(size.x / 2.0, size.y + 7 * Palette.DP)


func _draw() -> void:
	if kind == Kind.TIE:
		return
	var dp: float = Palette.DP
	var c: Vector2 = Vector2(size.x / 2.0, size.y)
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-6 * dp, -1), c + Vector2(6 * dp, -1), c + Vector2(0, 7 * dp),
	]), _bg())


func _bg() -> Color:
	match kind:
		Kind.MINE:
			return Palette.CHIP_MINE
		Kind.OPP:
			return Palette.CHIP_OPP
	return Color.WHITE


func _fg() -> Color:
	return Palette.TIE if kind == Kind.TIE else Color.WHITE


func _text(size_dp: int, weight: int) -> Label:
	var label: Label = Label.new()
	label.add_theme_font_override("font", UiTheme.text_font(weight))
	label.add_theme_font_size_override("font_size", int(size_dp * Palette.DP))
	label.add_theme_color_override("font_color", _fg())
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _icon(texture: Texture2D, size_dp: int) -> TextureRect:
	var rect: TextureRect = TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.custom_minimum_size = Vector2(size_dp, size_dp) * Palette.DP
	rect.modulate = _fg()
	return rect
