class_name TestContrast
extends RefCounted
## 명암비(03 접근성, SRC-008). 작은 글자 4.5:1 이상. 화면에 실제로 쓰는 글자·바탕 쌍만 검사한다.


static func run() -> TestBase:
	var t: TestBase = TestBase.new("contrast")
	var pairs: Array = [
		["본문 잉크 / 배경", Palette.INK, Palette.BG],
		["본문 잉크 / 패널", Palette.INK, Palette.PANEL],
		["보조 글자 / 배경", Palette.INK_SOFT, Palette.BG],
		["보조 글자 / 패널", Palette.INK_SOFT, Palette.PANEL],
		["흰 글자 / 나 표식", Color.WHITE, Palette.CHIP_MINE],
		["흰 글자 / 상대 표식", Color.WHITE, Palette.CHIP_OPP],
		["동수 표식 / 흰 바탕", Palette.TIE, Color.WHITE],
		["나 표식색 글자 / 패널", Palette.CHIP_MINE, Palette.PANEL],
		["승패 단어(나) / 배경", Palette.CHIP_MINE, Palette.BG],
		["상대 표식색 글자 / 패널", Palette.CHIP_OPP, Palette.PANEL],
	]
	for pair: Array in pairs:
		var ratio: float = contrast(pair[1], pair[2])
		t.check(ratio >= 4.5, "%s %.2f:1 ≥ 4.5" % [pair[0], ratio])
	return t


## WCAG 2.x 상대 휘도 대비
static func contrast(a: Color, b: Color) -> float:
	var la: float = _luminance(a)
	var lb: float = _luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


static func _luminance(c: Color) -> float:
	return 0.2126 * _linear(c.r) + 0.7152 * _linear(c.g) + 0.0722 * _linear(c.b)


static func _linear(v: float) -> float:
	return v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4)
