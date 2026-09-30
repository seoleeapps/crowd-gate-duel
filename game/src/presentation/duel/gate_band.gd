class_name GateBand
extends Control
## 화면을 가로지르는 게이트 띠. 칸 사이 구분선만 두고 장식 프레임을 쓰지 않는다(04 UI 아트 경계).
## 구간이 바뀌면 띠가 위에서 내려온다.

signal picked(index: int)

const HAND_ICON: Texture2D = preload("res://assets/art/hand.svg")

var cells: Array[GateCell] = []
var assist: bool = false
var _row: HBoxContainer
var _hand: TextureRect
var _hand_tween: Tween


func _ready() -> void:
	clip_contents = true
	_row = HBoxContainer.new()
	_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_row.add_theme_constant_override("separation", 0)
	add_child(_row)
	_hand = TextureRect.new()
	_hand.texture = HAND_ICON
	_hand.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hand.custom_minimum_size = Vector2(56, 56) * Palette.DP
	_hand.size = _hand.custom_minimum_size
	_hand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hand.visible = false
	add_child(_hand)


## guided 가 0 이상이면 그 칸만 누를 수 있고 손이 그 칸을 가리킨다(온보딩).
func present(gates: Array[Gate], guided: int = -1) -> Tween:
	for cell: GateCell in cells:
		cell.queue_free()
	cells.clear()
	for i: int in range(gates.size()):
		var cell: GateCell = GateCell.new(gates[i])
		cell.assist = assist
		cell.pressed.connect(func() -> void: picked.emit(i))
		if guided >= 0 and guided != i:
			cell.disabled = true
			cell.modulate = Color(1, 1, 1, 0.4)
		_row.add_child(cell)
		cells.append(cell)
	queue_redraw()
	_row.position.y = -size.y * 0.6
	_row.modulate.a = 0.0
	var tween: Tween = create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_row, "position:y", 0.0, 0.35)
	tween.tween_property(_row, "modulate:a", 1.0, 0.2)
	if guided >= 0:
		tween.chain().tween_callback(_point_hand.bind(guided))
	else:
		_stop_hand()
	return tween


func lock(pick: int) -> void:
	_stop_hand()
	for i: int in range(cells.size()):
		cells[i].lock(i == pick)


## 공개. 같은 칸이면 두 표식이 한 칸에 나란히 붙고 연결된다.
## 양보 사건은 먼저 지나간 쪽 표식에 오르막, 막힌 쪽 표식에 통행 금지 표시, 동수 반감은 양쪽에 절반 표시를 붙인다.
func reveal(step: Dictionary, opp_label: String) -> Tween:
	var events: Array = step["events"]
	var pick_me: int = int(step["pick_me"])
	var pick_opp: int = int(step["pick_opp"])
	var me_icon: Texture2D = null
	var opp_icon: Texture2D = null
	if events.has("split_even"):
		me_icon = GateCell.HALF_ICON
		opp_icon = GateCell.HALF_ICON
	elif events.has("yield_to_a"):
		me_icon = GateCell.YIELD_ICON
		opp_icon = GateCell.BLOCKED_ICON
	elif events.has("yield_to_b"):
		opp_icon = GateCell.YIELD_ICON
		me_icon = GateCell.BLOCKED_ICON
	var tween: Tween = create_tween().set_parallel()
	for i: int in range(cells.size()):
		var marks: Array[Dictionary] = []
		if i == pick_me:
			marks.append({"mine": true, "label": tr("CHIP_ME"), "icon": me_icon})
		if i == pick_opp:
			marks.append({"mine": false, "label": opp_label, "icon": opp_icon})
		tween.tween_subtween(cells[i].reveal(marks))
	return tween


## 온보딩 핵심 순간: 두 표식이 붙은 칸을 두 번 크게 두드려 보인다.
func pulse(index: int) -> void:
	var cell: GateCell = cells[index]
	cell.pivot_offset = cell.size / 2.0
	var tween: Tween = create_tween().set_loops(2)
	tween.tween_property(cell, "scale", Vector2.ONE * 1.06, 0.18)
	tween.tween_property(cell, "scale", Vector2.ONE, 0.18)


func _point_hand(index: int) -> void:
	var cell: GateCell = cells[index]
	var base: Vector2 = cell.position + Vector2(cell.size.x * 0.66, cell.size.y * 0.58)
	_hand.position = base
	_hand.visible = true
	_stop_hand_tween()
	_hand_tween = create_tween().set_loops()
	_hand_tween.tween_property(_hand, "position", base + Vector2(0, 14) * Palette.DP, 0.35)
	_hand_tween.tween_property(_hand, "position", base, 0.35)


func _stop_hand() -> void:
	_stop_hand_tween()
	_hand.visible = false


func _stop_hand_tween() -> void:
	if _hand_tween != null:
		_hand_tween.kill()
		_hand_tween = null


func _draw() -> void:
	var dp: float = Palette.DP
	draw_rect(Rect2(Vector2.ZERO, size), Palette.PANEL)
	draw_line(Vector2(0, dp), Vector2(size.x, dp), Palette.INK, 2 * dp)
	for i: int in range(1, maxi(cells.size(), 1)):
		var x: float = size.x * float(i) / float(cells.size())
		draw_line(Vector2(x, 0), Vector2(x, size.y - 16 * dp), Palette.INK, 1.5 * dp)
