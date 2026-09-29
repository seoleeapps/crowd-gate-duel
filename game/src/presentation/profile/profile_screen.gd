class_name ProfileScreen
extends Control
## SCR-005 프로필과 꾸미기. 시선 순서: 내 무리 미리보기 → 깃발·팔레트·테두리 목록 → 전적.
## 판매 항목이 승패에 영향을 주지 않음을 목록 위에 한 줄로 밝힌다.

signal back_pressed

var store: ProgressStore
var _preview: WorldView
var _feathers: PanelContainer
var _toast: Label
var _cards: Array[CosmeticCard] = []


func setup(store_in: ProgressStore) -> void:
	store = store_in


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dp: float = Palette.DP
	var bg: ColorRect = ColorRect.new()
	bg.color = Palette.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", int(12 * dp))
	add_child(ScreenKit.margin(column))

	_feathers = ScreenKit.pill_label("")
	column.add_child(ScreenKit.header(tr("PROFILE_TITLE"), func() -> void: back_pressed.emit(), _feathers))

	var frame: PanelContainer = PanelContainer.new()
	var box: StyleBoxFlat = UiTheme.pill(Palette.PANEL, 16.0, Palette.INK)
	box.set_border_width_all(int(2 * dp))
	frame.add_theme_stylebox_override("panel", box)
	frame.clip_contents = true
	frame.custom_minimum_size.y = 190 * dp
	_preview = WorldView.new()
	frame.add_child(_preview)
	column.add_child(frame)
	_preview.show_only_mine(CourseGenerator.START_CROWD)

	var note: Label = _label(tr("COSMETIC_NOTE"), 14, 500, Palette.INK_SOFT)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(note)

	var list: VBoxContainer = VBoxContainer.new()
	list.add_theme_constant_override("separation", int(10 * dp))
	for slot: Cosmetics.Slot in [Cosmetics.Slot.FLAG, Cosmetics.Slot.PALETTE, Cosmetics.Slot.BORDER]:
		list.add_child(ScreenKit.section_title(tr(["SLOT_FLAG", "SLOT_PALETTE", "SLOT_BORDER"][slot])))
		var grid: GridContainer = GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", int(8 * dp))
		grid.add_theme_constant_override("v_separation", int(8 * dp))
		for id: String in Cosmetics.ids_in(slot):
			var card: CosmeticCard = CosmeticCard.new(id)
			card.pressed.connect(_on_card.bind(id))
			grid.add_child(card)
			_cards.append(card)
		list.add_child(grid)
	var stats: Label = _label(tr("STATS") % [store.wins(), int(store.data["losses"]), int(store.data["draws"])], 14, 500, Palette.INK_SOFT)
	list.add_child(stats)
	column.add_child(ScreenKit.scroll(list))

	_toast = _label("", 14, 700, Palette.INK)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_toast)
	_refresh()


func _on_card(id: String) -> void:
	if store.is_unlocked(id):
		store.equip(id)
		store.write()
		_refresh()
		return
	var price: int = Cosmetics.price_of(id)
	if store.feathers() < price:
		_toast.text = tr("NOT_ENOUGH") % (price - store.feathers())
		return
	var sheet: ConfirmSheet = ConfirmSheet.new(tr("UNLOCK_CONFIRM") % price, tr("UNLOCK"))
	sheet.confirmed.connect(func() -> void:
		if store.purchase(id):
			store.equip(id)
			store.write()
			_toast.text = tr("ITEM_UNLOCKED")
			_refresh()
	)
	add_child(sheet)


func _refresh() -> void:
	(_feathers.get_child(0) as Label).text = "◆ %d" % store.feathers()
	for card: CosmeticCard in _cards:
		var slot: Cosmetics.Slot = Cosmetics.slot_of(card.item_id)
		card.refresh(store.is_unlocked(card.item_id), store.equipped(slot) == card.item_id)
	_preview.set_my_style(
		Color(Cosmetics.value_of(store.equipped(Cosmetics.Slot.PALETTE))),
		Cosmetics.value_of(store.equipped(Cosmetics.Slot.FLAG))
	)


func _label(text: String, size_dp: int, weight: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_override("font", UiTheme.text_font(weight))
	label.add_theme_font_size_override("font_size", int(size_dp * Palette.DP))
	label.add_theme_color_override("font_color", color)
	return label
