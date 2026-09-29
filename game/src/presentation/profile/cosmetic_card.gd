class_name CosmeticCard
extends Button
## 꾸미기 항목 한 칸. 이름 대신 실제 모습(깃발·무리 색·카드 테두리)을 그려 보여 준다.
## 상태: 장착 중(굵은 테두리 + "장착 중") / 해금됨("장착") / 잠김(깃털 가격, 흐린 미리보기).

const CARD_DP: Vector2 = Vector2(100, 112)

var item_id: String
var unlocked: bool = false
var equipped: bool = false
var _status: Label


func _init(item_id_in: String) -> void:
	item_id = item_id_in
	custom_minimum_size = CARD_DP * Palette.DP
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	accessibility_name = TranslationServer.translate("ITEM_" + item_id.to_upper())
	var empty: StyleBoxEmpty = StyleBoxEmpty.new()
	for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, empty)
	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_status.offset_top = -28 * Palette.DP
	_status.offset_bottom = -6 * Palette.DP
	_status.add_theme_font_override("font", UiTheme.number_font(700))
	_status.add_theme_font_size_override("font_size", int(14 * Palette.DP))
	add_child(_status)


func refresh(unlocked_in: bool, equipped_in: bool) -> void:
	unlocked = unlocked_in
	equipped = equipped_in
	if equipped:
		_status.text = TranslationServer.translate("EQUIPPED")
	elif unlocked:
		_status.text = TranslationServer.translate("EQUIP")
	else:
		_status.text = "◆ %d" % Cosmetics.price_of(item_id)
	_status.add_theme_color_override("font_color", Palette.CHIP_MINE if equipped else Palette.INK)
	queue_redraw()


func _draw() -> void:
	var dp: float = Palette.DP
	var frame: StyleBoxFlat = UiTheme.pill(Palette.PANEL, 14.0, Palette.CHIP_MINE if equipped else Palette.STEP_LINE)
	frame.set_border_width_all(int((4 if equipped else 1.5) * dp))
	draw_style_box(frame, Rect2(Vector2(3, 3) * dp, size - Vector2(6, 6) * dp))
	var center: Vector2 = Vector2(size.x / 2.0, size.y * 0.42)
	var fade: float = 1.0 if unlocked else 0.45
	var value: String = Cosmetics.value_of(item_id)
	match Cosmetics.slot_of(item_id):
		Cosmetics.Slot.FLAG:
			FlagArt.draw(self, center + Vector2(-10 * dp, 26 * dp), dp * 1.4, value,
				Color(Palette.MINE, fade), Color(Palette.FLAG_MARK, fade))
		Cosmetics.Slot.PALETTE:
			draw_circle(center, 22 * dp, Color(Color(value), fade), true, -1.0, true)
			draw_arc(center, 22 * dp, 0.0, TAU, 32, Color(Palette.DOLL_LINE, fade), 1.5 * dp, true)
		Cosmetics.Slot.BORDER:
			var card: Rect2 = Rect2(center - Vector2(24, 30) * dp, Vector2(48, 60) * dp)
			draw_rect(card, Palette.BG)
			BorderArt.draw(self, card, value, 1.0 * dp, fade)
	if has_focus():
		draw_style_box(UiTheme.pill(Color(0, 0, 0, 0), 14.0, Palette.INK), Rect2(Vector2.ZERO, size))
