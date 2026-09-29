class_name Palette
extends RefCounted
## A-1 에서 선택한 시각 방향 "한낮 장터"의 색과 크기 토큰.
## 기준 시안: docs/game-design/ui/duel-screen-style-options.html 의 방향 a.
##
## 진영색은 둘뿐이다. 나는 따뜻한 주황, 상대는 차가운 청록이고 나머지는 중립색이다.
## 게이트 종류는 색이 아니라 아이콘 모양으로 구분한다(04 시각 문법).

## 시안은 360dp 폭 기준이고 화면은 1080px 폭이다.
const DP: float = 3.0

const SKY_TOP: Color = Color("#f7efe2")
const SKY_BOTTOM: Color = Color("#fbf7f0")
const SUN: Color = Color("#fbe3bf")
const HILLS: Array[Color] = [Color("#e4ddd0"), Color("#d4cbbb"), Color("#c2b7a4")]
const ROAD: Color = Color("#f8f3ea")
const ROAD_EDGE: Color = Color("#a89d8b")

const MINE: Color = Color("#ec7a2c")
const OPP: Color = Color("#1e9c90")
const CHIP_MINE: Color = Color("#a84a0c")
const CHIP_OPP: Color = Color("#0c6b62")
const DOLL_LINE: Color = Color("#2d2621")
const FLAG_MARK: Color = Color("#ffffff")
const BOT: Color = Color("#9a948a")
const BOT_MARK: Color = Color("#e8e4dc")
const POLE: Color = Color("#4a4038")
const BUNTING: Array[Color] = [Color("#fffaf0"), Color("#d9cfbe"), Color("#b3a893")]
const BUNTING_LINE: Color = Color("#6d6457")
const TIE: Color = Color("#5f5a52")

const BG: Color = Color("#fbf7f0")
const INK: Color = Color("#2b2622")
const INK_SOFT: Color = Color("#5f5a52")
const PANEL: Color = Color("#fffaf0")
const STEP_LINE: Color = Color("#8c8272")
const STEP_ON: Color = Color("#4a433b")
const TIMER_TRACK: Color = Color("#e6dfd2")
const DIM: Color = Color(0.17, 0.15, 0.13, 0.45)


static func side_color(mine: bool) -> Color:
	return MINE if mine else OPP


static func chip_color(mine: bool) -> Color:
	return CHIP_MINE if mine else CHIP_OPP
