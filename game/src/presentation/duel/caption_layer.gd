class_name CaptionLayer
extends Control
## 필수 체험과 최초 특수 게이트의 짧은 설명. 확인을 직접 눌러야 다음으로 넘어간다.

signal layout_changed
signal continued

const ICONS: Dictionary = {
	"steal": preload("res://assets/art/gate_steal.svg"),
	"shield": preload("res://assets/art/gate_shield.svg"),
	"yield": preload("res://assets/art/yield.svg"),
	"blocked": preload("res://assets/art/blocked.svg"),
}

var _card: PanelContainer
var _icon: TextureRect
var _text: Label
var _hint: Label
var _waiting: bool = false


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
	_card.minimum_size_changed.connect(_place.call_deferred)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", int(4 * dp))
	_card.add_child(column)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", int(8 * dp))
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(row)
	_icon = TextureRect.new()
	var icon_material: ShaderMaterial = ShaderMaterial.new()
	icon_material.shader = preload("res://src/presentation/theme/caption_icon.gdshader")
	_icon.material = icon_material
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.custom_minimum_size = Vector2(22, 22) * dp
	row.add_child(_icon)
	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text.custom_minimum_size.x = 0
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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


## wait=true이면 직접 확인할 때까지 기다린다.
func show_caption(key: String, icon: String, wait: bool, detail: String = "") -> void:
	_text.text = tr(key) + ("\n" + detail if not detail.is_empty() else "")
	_icon.texture = ICONS.get(icon, null)
	_icon.visible = _icon.texture != null
	_hint.visible = wait
	visible = true
	_place.call_deferred()
	_card.modulate.a = 0.0
	create_tween().tween_property(_card, "modulate:a", 1.0, 0.18)
	if not wait:
		return
	_waiting = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	await continued


func hide_caption() -> void:
	visible = false
	_waiting = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout_changed.emit()


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
	var width: float = maxf(0.0, size.x - 16.0 * Palette.DP)
	_card.custom_minimum_size.x = width
	_card.size = Vector2(width, 0)
	_card.reset_size()
	_card.position = Vector2(8.0 * Palette.DP, maxf(0, size.y - _card.size.y - 12.0 * Palette.DP))
	layout_changed.emit()
