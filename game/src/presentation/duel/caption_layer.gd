class_name CaptionLayer
extends Control
## 온보딩 자막(DEC-017). 한 구간에 한 가지 규칙을 한 줄로 보여 준다.
## 핵심 순간에는 탭하거나 잠시 기다려야 넘어가, 방금 일어난 일을 볼 시간을 준다.
## 일반 대국에서는 쓰지 않는다. 판 중 화면에 요소를 더하지 않는다는 원칙(03)은 일반 대국에 그대로 남는다.

signal continued

const ICONS: Dictionary = {
	"yield": preload("res://assets/art/yield.svg"),
	"blocked": preload("res://assets/art/blocked.svg"),
}
const FOCUS_WAIT_SECONDS: float = 4.0

var _card: PanelContainer
var _icon: TextureRect
var _text: Label
var _hint: Label
var _waiting: bool = false
## 자막을 띄울 때마다 오른다. 앞 자막의 4초 타이머가 뒤 자막을 닫지 않게 번호로 가린다.
var _serial: int = 0


func _ready() -> void:
	var dp: float = Palette.DP
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card = PanelContainer.new()
	var box: StyleBoxFlat = UiTheme.pill(Palette.INK, 18.0, Palette.INK)
	box.content_margin_left = 16 * dp
	box.content_margin_right = 16 * dp
	box.content_margin_top = 10 * dp
	box.content_margin_bottom = 10 * dp
	_card.add_theme_stylebox_override("panel", box)
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_card)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", int(4 * dp))
	_card.add_child(column)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", int(8 * dp))
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(row)
	_icon = TextureRect.new()
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.custom_minimum_size = Vector2(22, 22) * dp
	row.add_child(_icon)
	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text.custom_minimum_size.x = 290 * dp
	_text.add_theme_font_override("font", UiTheme.text_font(700))
	_text.add_theme_font_size_override("font_size", int(18 * dp))
	_text.add_theme_color_override("font_color", Color.WHITE)
	row.add_child(_text)
	_hint = Label.new()
	_hint.text = tr("TAP_CONTINUE")
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_override("font", UiTheme.text_font(500))
	_hint.add_theme_font_size_override("font_size", int(13 * dp))
	_hint.add_theme_color_override("font_color", Palette.TIMER_TRACK)
	column.add_child(_hint)
	visible = false


## 자막을 띄운다. 핵심 순간(wait=true)이면 탭하거나 4초가 지나야 돌아온다.
func show_caption(key: String, icon: String, wait: bool) -> void:
	_text.text = tr(key)
	_icon.texture = ICONS.get(icon, null)
	_icon.visible = _icon.texture != null
	_hint.visible = wait
	visible = true
	_place.call_deferred()
	_card.modulate.a = 0.0
	create_tween().tween_property(_card, "modulate:a", 1.0, 0.18)
	if not wait:
		return
	_serial += 1
	var serial: int = _serial
	_waiting = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	# 일시정지 중에는 멈추는 타이머라, 앱이 백그라운드에 있는 동안 자막이 저절로 닫히지 않는다.
	get_tree().create_timer(FOCUS_WAIT_SECONDS, false).timeout.connect(func() -> void:
		if serial == _serial:
			_continue()
	)
	await continued


func hide_caption() -> void:
	visible = false


func _gui_input(event: InputEvent) -> void:
	if _waiting and (event is InputEventScreenTouch or event is InputEventMouseButton) and event.is_pressed():
		accept_event()
		_continue()


func _continue() -> void:
	if not _waiting:
		return
	_waiting = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	continued.emit()


## 이 층은 리본 아래에서 시작한다(일시정지 버튼을 덮지 않는다). 카드는 층 맨 위 가운데에 둔다.
func _place() -> void:
	_card.reset_size()
	_card.position = Vector2((size.x - _card.size.x) / 2.0, 12.0 * Palette.DP)
