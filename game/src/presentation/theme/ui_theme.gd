class_name UiTheme
extends RefCounted
## 서체와 공통 Theme. 숫자는 둥근 숫자 서체(Fredoka), 글은 Noto Sans KR 이다.
## 둘 다 SIL OFL 1.1 이며 라이선스 원문은 assets/fonts 에 함께 둔다.
## Web·AppsInToss 에서 시스템 서체 대체에 기대지 않도록 한글 서체를 번들한다.

const TEXT_FONT_PATH: String = "res://assets/fonts/NotoSansKR-Variable.ttf"
const NUMBER_FONT_PATH: String = "res://assets/fonts/Fredoka-Variable.ttf"

static var _cache: Dictionary = {}


static func text_font(weight: int = 700) -> FontVariation:
	return _variation(TEXT_FONT_PATH, weight)


## 숫자 서체에 없는 글자(한글 등)는 본문 서체로 넘어간다.
static func number_font(weight: int = 700) -> FontVariation:
	var font: FontVariation = _variation(NUMBER_FONT_PATH, weight)
	if font.fallbacks.is_empty():
		font.fallbacks = [text_font(weight)]
	return font


static func build() -> Theme:
	var theme: Theme = Theme.new()
	theme.default_font = text_font(500)
	theme.default_font_size = int(16 * Palette.DP)
	theme.set_color("font_color", "Label", Palette.INK)
	theme.set_color("font_color", "Button", Palette.INK)
	theme.set_color("font_pressed_color", "Button", Palette.INK)
	theme.set_color("font_hover_color", "Button", Palette.INK)
	theme.set_color("font_focus_color", "Button", Palette.INK)
	return theme


## 주 행동 버튼. 따뜻한 진영색 바탕에 흰 글자, 얇은 잉크 외곽선.
static func primary_button(button: Button, label: String) -> void:
	_button(button, label, Palette.CHIP_MINE, Color.WHITE, 20)


## 보조 행동 버튼. 밝은 바탕에 잉크 글자.
static func secondary_button(button: Button, label: String) -> void:
	_button(button, label, Palette.PANEL, Palette.INK, 16)


static func pill(bg: Color, radius_dp: float = 15.0, border: Color = Palette.DOLL_LINE) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = bg
	box.set_corner_radius_all(int(radius_dp * Palette.DP))
	box.set_border_width_all(int(1.5 * Palette.DP))
	box.border_color = border
	box.anti_aliasing = true
	return box


static func _button(button: Button, label: String, bg: Color, fg: Color, size_dp: int) -> void:
	button.text = label
	button.add_theme_font_override("font", text_font(700))
	button.add_theme_font_size_override("font_size", int(size_dp * Palette.DP))
	for state: String in ["font_color", "font_pressed_color", "font_hover_color", "font_focus_color"]:
		button.add_theme_color_override(state, fg)
	var normal: StyleBoxFlat = pill(bg, 18.0, Palette.INK)
	normal.set_border_width_all(int(2 * Palette.DP))
	normal.content_margin_left = 20 * Palette.DP
	normal.content_margin_right = 20 * Palette.DP
	normal.content_margin_top = 12 * Palette.DP
	normal.content_margin_bottom = 12 * Palette.DP
	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = bg.darkened(0.12)
	# 눌림은 색만이 아니라 아래로 꺼지는 모양으로도 보인다.
	pressed.content_margin_top += 2 * Palette.DP
	pressed.content_margin_bottom -= 2 * Palette.DP
	var disabled: StyleBoxFlat = normal.duplicate()
	disabled.bg_color = bg.lerp(Palette.TIMER_TRACK, 0.6)
	disabled.border_color = Palette.STEP_LINE
	var focus: StyleBoxFlat = StyleBoxFlat.new()
	focus.draw_center = false
	focus.set_border_width_all(int(3 * Palette.DP))
	focus.border_color = Palette.INK
	focus.set_corner_radius_all(int(20 * Palette.DP))
	focus.set_expand_margin_all(4 * Palette.DP)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_stylebox_override("focus", focus)
	button.custom_minimum_size.y = 56 * Palette.DP


static func _variation(path: String, weight: int) -> FontVariation:
	var key: String = "%s@%d" % [path, weight]
	if _cache.has(key):
		return _cache[key]
	var variation: FontVariation = FontVariation.new()
	variation.base_font = load(path)
	var wght: int = TextServerManager.get_primary_interface().name_to_tag("wght")
	variation.variation_opentype = {wght: weight}
	_cache[key] = variation
	return variation
