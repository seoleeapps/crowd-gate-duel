class_name SettingsScreen
extends Control
## SCR-006 설정: 접근성과 데이터 관리.
## 확약 시간 연장, 진동, 소리, 음악, 색각 보조 무늬, 흔들림 줄이기, 언어, 진행 초기화, 개인정보 고지.

signal back_pressed
signal settings_changed(key: String)
signal reset_confirmed

const TOGGLES: Array[String] = ["commit_extended", "vibration", "sound", "music", "colorblind_assist", "reduce_shake"]
const LABELS: Dictionary = {
	"commit_extended": "SET_COMMIT_EXT",
	"vibration": "SET_VIBRATION",
	"sound": "SET_SOUND",
	"music": "SET_MUSIC",
	"colorblind_assist": "SET_COLORBLIND",
	"reduce_shake": "SET_REDUCE_SHAKE",
}
const TOGGLE_ON: Texture2D = preload("res://assets/art/toggle_on.svg")
const TOGGLE_OFF: Texture2D = preload("res://assets/art/toggle_off.svg")
const LOCALES: Array[String] = ["", "en", "ko"]
const LOCALE_LABELS: Array[String] = ["LANG_SYSTEM", "LANG_EN", "LANG_KO"]

var store: ProgressStore


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
	column.add_child(ScreenKit.header(tr("SETTINGS_TITLE"), func() -> void: back_pressed.emit()))

	var list: VBoxContainer = VBoxContainer.new()
	list.add_theme_constant_override("separation", int(6 * dp))
	for key: String in TOGGLES:
		list.add_child(_toggle_row(key))
		if key == "commit_extended":
			var desc: Label = _label(tr("SET_COMMIT_EXT_DESC"), 13, 500, Palette.INK_SOFT)
			desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			list.add_child(desc)

	list.add_child(ScreenKit.section_title(tr("SET_LANGUAGE")))
	var languages: HBoxContainer = HBoxContainer.new()
	languages.add_theme_constant_override("separation", int(8 * dp))
	for i: int in range(LOCALES.size()):
		var button: Button = Button.new()
		var chosen: bool = str(store.setting("locale")) == LOCALES[i]
		if chosen:
			UiTheme.primary_button(button, tr(LOCALE_LABELS[i]))
		else:
			UiTheme.secondary_button(button, tr(LOCALE_LABELS[i]))
		button.add_theme_font_size_override("font_size", int(15 * dp))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_locale.bind(LOCALES[i]))
		languages.add_child(button)
	list.add_child(languages)

	var privacy: Button = Button.new()
	UiTheme.secondary_button(privacy, tr("SET_PRIVACY"))
	privacy.pressed.connect(func() -> void: add_child(ConfirmSheet.new(tr("PRIVACY_TEXT"))))
	list.add_child(privacy)
	var reset: Button = Button.new()
	UiTheme.secondary_button(reset, tr("SET_RESET"))
	reset.add_theme_color_override("font_color", Palette.CHIP_MINE)
	reset.pressed.connect(_on_reset)
	list.add_child(reset)
	column.add_child(ScreenKit.scroll(list))


func _toggle_row(key: String) -> CheckButton:
	var toggle: CheckButton = CheckButton.new()
	toggle.text = tr(LABELS[key])
	toggle.button_pressed = bool(store.setting(key))
	toggle.custom_minimum_size.y = 56 * Palette.DP
	toggle.add_theme_font_override("font", UiTheme.text_font(500))
	toggle.add_theme_font_size_override("font_size", int(16 * Palette.DP))
	# 켜짐은 진영색 바탕과 체크 표시, 꺼짐은 회색 바탕. 색만이 아니라 손잡이 위치와 체크로도 구분된다.
	toggle.add_theme_icon_override("checked", TOGGLE_ON)
	toggle.add_theme_icon_override("unchecked", TOGGLE_OFF)
	toggle.add_theme_icon_override("checked_disabled", TOGGLE_ON)
	toggle.add_theme_icon_override("unchecked_disabled", TOGGLE_OFF)
	toggle.toggled.connect(func(on: bool) -> void:
		store.set_setting(key, on)
		store.write()
		settings_changed.emit(key)
	)
	return toggle


func _on_locale(locale: String) -> void:
	store.set_setting("locale", locale)
	store.write()
	settings_changed.emit("locale")


func _on_reset() -> void:
	var sheet: ConfirmSheet = ConfirmSheet.new(tr("RESET_CONFIRM"), tr("RESET_YES"), true)
	sheet.confirmed.connect(func() -> void: reset_confirmed.emit())
	add_child(sheet)


func _label(text: String, size_dp: int, weight: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_override("font", UiTheme.text_font(weight))
	label.add_theme_font_size_override("font_size", int(size_dp * Palette.DP))
	label.add_theme_color_override("font_color", color)
	return label
