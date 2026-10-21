class_name GateCell
extends Button
## 게이트 띠의 한 칸. 아이콘과 수치만 보여 주고 설명 문장을 쓰지 않는다(03 SCR-002).
## 종류는 아이콘 모양으로 구분하고 칸에는 진영색을 쓰지 않는다.
##
## 상태: 선택 가능 → (내가 확약) 잠김 / 흐림 → (공개) 뒤집혀 나·상대 표식이 붙는다.

const ICONS: Dictionary = {
	Gate.Kind.MULTIPLY: preload("res://assets/art/gate_multiply.svg"),
	Gate.Kind.ADD: preload("res://assets/art/gate_add.svg"),
	Gate.Kind.STEAL: preload("res://assets/art/gate_steal.svg"),
	Gate.Kind.SHIELD: preload("res://assets/art/gate_shield.svg"),
}
const LOCK_ICON: Texture2D = preload("res://assets/art/lock.svg")
const HALF_ICON: Texture2D = preload("res://assets/art/half.svg")
const YIELD_ICON: Texture2D = preload("res://assets/art/yield.svg")
const BLOCKED_ICON: Texture2D = preload("res://assets/art/blocked.svg")

var gate: Gate
## 색각 보조 표시 강화(SCR-006). 켜면 종류마다 다른 바탕 무늬를 더한다.
var assist: bool = false
var _icon: TextureRect
var _value: Label
var _markers: HBoxContainer
var _locked_by_me: bool = false


func _init(gate_in: Gate) -> void:
	gate = gate_in
	focus_mode = Control.FOCUS_ALL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(0, 96 * Palette.DP)
	var empty: StyleBoxEmpty = StyleBoxEmpty.new()
	for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, empty)
	accessibility_name = describe(gate)

	var column: VBoxContainer = VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", int(10 * Palette.DP))
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)

	_icon = TextureRect.new()
	_icon.texture = ICONS[gate.kind]
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.custom_minimum_size = Vector2(34, 34) * Palette.DP
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_icon)

	_value = Label.new()
	_value.text = label_for(gate)
	_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_value.add_theme_font_override("font", UiTheme.number_font(700))
	_value.add_theme_font_size_override("font_size", int(32 * Palette.DP))
	_value.add_theme_color_override("font_color", Palette.INK)
	column.add_child(_value)

	_markers = HBoxContainer.new()
	_markers.alignment = BoxContainer.ALIGNMENT_CENTER
	_markers.add_theme_constant_override("separation", int(4 * Palette.DP))
	_markers.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_markers.position.y = 8 * Palette.DP
	_markers.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_markers)


static func label_for(g: Gate) -> String:
	match g.kind:
		Gate.Kind.MULTIPLY:
			return "×" + multiplier_text(g.value)
		Gate.Kind.ADD:
			return "+%d" % g.value
	return "%d%%" % g.value


## 200 → "2", 150 → "1.5", 125 → "1.25". 정수 백분율을 사람이 읽는 배수로 바꾼다.
static func multiplier_text(value: int) -> String:
	var text: String = "%d.%02d" % [value / 100, value % 100]
	return text.trim_suffix("0").trim_suffix("0").trim_suffix(".")


## 스크린리더용 고유 설명. 예: "불리기, 1.5배"
static func describe(g: Gate) -> String:
	match g.kind:
		Gate.Kind.MULTIPLY:
			return TranslationServer.translate("A11Y_GATE_MUL") % multiplier_text(g.value)
		Gate.Kind.ADD:
			return TranslationServer.translate("A11Y_GATE_ADD") % g.value
		Gate.Kind.STEAL:
			return TranslationServer.translate("A11Y_GATE_STEAL") % g.value
	return TranslationServer.translate("A11Y_GATE_SHIELD") % g.value


## 내가 확약한 칸은 진한 테두리와 자물쇠, 나머지는 흐려진다.
func lock(mine_picked: bool) -> void:
	_locked_by_me = mine_picked
	disabled = true
	modulate = Color.WHITE if mine_picked else Color(1, 1, 1, 0.45)
	queue_redraw()


## 공개 때 양쪽 칸이 동시에 뒤집히며 표식이 붙는다.
## marks: [{"mine": bool, "label": String, "icon": Texture2D 또는 null}]
func reveal(marks: Array[Dictionary]) -> Tween:
	var tween: Tween = create_tween()
	pivot_offset = size / 2.0
	tween.tween_property(self, "scale:x", 0.0, 0.12)
	tween.tween_callback(func() -> void:
		modulate = Color.WHITE if not marks.is_empty() or _locked_by_me else Color(1, 1, 1, 0.35)
		for child: Node in _markers.get_children():
			_markers.remove_child(child)
			child.queue_free()
		for mark: Dictionary in marks:
			_markers.add_child(_marker(mark))
		_markers.reset_size()
		_markers.position.x = (size.x - _markers.size.x) / 2.0
	)
	tween.tween_property(self, "scale:x", 1.0, 0.12)
	return tween


func _marker(mark: Dictionary) -> PanelContainer:
	var mine: bool = bool(mark["mine"])
	var chip: PanelContainer = PanelContainer.new()
	var box: StyleBoxFlat = UiTheme.pill(Palette.chip_color(mine), 12.0)
	box.content_margin_left = 8 * Palette.DP
	box.content_margin_right = 8 * Palette.DP
	chip.add_theme_stylebox_override("panel", box)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", int(3 * Palette.DP))
	chip.add_child(row)
	var label: Label = Label.new()
	label.text = str(mark["label"])
	label.add_theme_font_override("font", UiTheme.text_font(700))
	label.add_theme_font_size_override("font_size", int(12 * Palette.DP))
	label.add_theme_color_override("font_color", Color.WHITE)
	row.add_child(label)
	var icon: Texture2D = mark.get("icon", null)
	if icon != null:
		var rect: TextureRect = TextureRect.new()
		rect.texture = icon
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.custom_minimum_size = Vector2(14, 14) * Palette.DP
		row.add_child(rect)
	return chip


func _draw() -> void:
	var dp: float = Palette.DP
	if assist:
		_draw_pattern()
	if has_focus() and not disabled:
		draw_rect(Rect2(Vector2(4, 4) * dp, size - Vector2(8, 8) * dp), Palette.INK, false, 3 * dp)
	if button_pressed or is_pressed():
		draw_rect(Rect2(Vector2.ZERO, size), Color(Palette.INK, 0.06))
	if _locked_by_me:
		draw_rect(Rect2(Vector2(5, 5) * dp, size - Vector2(10, 10) * dp), Palette.CHIP_MINE, false, 5 * dp)
		var lock_size: Vector2 = Vector2(22, 22) * dp
		var corner: Vector2 = Vector2(size.x - lock_size.x - 12 * dp, size.y - lock_size.y - 12 * dp)
		draw_circle(corner + lock_size / 2.0, 16 * dp, Palette.CHIP_MINE, true, -1.0, true)
		draw_texture_rect(LOCK_ICON, Rect2(corner, lock_size), false)


## 종류별 바탕 무늬. 아이콘 모양에 더해 두 번째 구분 단서가 된다.
##   불리기: 사선 / 모으기: 점 격자 / 빼앗기: 가로줄 / 방패: 격자
func _draw_pattern() -> void:
	var dp: float = Palette.DP
	var ink: Color = Color(Palette.INK, 0.1)
	var step: float = 14 * dp
	match gate.kind:
		Gate.Kind.MULTIPLY:
			var x: float = -size.y
			while x < size.x:
				draw_line(Vector2(x, size.y), Vector2(x + size.y, 0), ink, 2 * dp)
				x += step
		Gate.Kind.ADD:
			var y: float = step / 2.0
			while y < size.y:
				var x: float = step / 2.0
				while x < size.x:
					draw_circle(Vector2(x, y), 2 * dp, ink)
					x += step
				y += step
		Gate.Kind.STEAL:
			var y: float = step / 2.0
			while y < size.y:
				draw_line(Vector2(0, y), Vector2(size.x, y), ink, 2 * dp)
				y += step
		Gate.Kind.SHIELD:
			var x: float = step / 2.0
			while x < size.x:
				draw_line(Vector2(x, 0), Vector2(x, size.y), ink, 2 * dp)
				x += step
			var y: float = step / 2.0
			while y < size.y:
				draw_line(Vector2(0, y), Vector2(size.x, y), ink, 2 * dp)
				y += step
