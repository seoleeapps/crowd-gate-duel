class_name Cosmetics
extends RefCounted
## 꾸미기 카탈로그(05 재화 Sink). 판매하는 것은 외형뿐이며 판의 강함을 바꾸는 항목이 없다.
##
## 군중 팔레트는 따뜻한 계열만 둔다. 진영은 색으로만 구분하므로(04) 내 무리가 상대의
## 청록과 헷갈리는 색을 고를 수 없어야 한다. 봇 전용인 무채색 막대 깃발도 팔지 않는다.

enum Slot { FLAG, PALETTE, BORDER }

const PRICE_FLAG: int = 150
const PRICE_PALETTE: int = 120
const PRICE_BORDER: int = 200

const DEFAULTS: Dictionary = {
	Slot.FLAG: "flag_chevron",
	Slot.PALETTE: "palette_sunrise",
	Slot.BORDER: "border_none",
}

## id → { slot, price, value }. value 는 화면이 쓰는 표현값(무늬 이름 또는 색)이다.
const ITEMS: Dictionary = {
	"flag_chevron": {"slot": Slot.FLAG, "price": 0, "value": "chevron"},
	"flag_diamond": {"slot": Slot.FLAG, "price": PRICE_FLAG, "value": "diamond"},
	"flag_cross": {"slot": Slot.FLAG, "price": PRICE_FLAG, "value": "cross"},
	"flag_stripes": {"slot": Slot.FLAG, "price": PRICE_FLAG, "value": "stripes"},
	"flag_triangle": {"slot": Slot.FLAG, "price": PRICE_FLAG, "value": "triangle"},
	"flag_ring": {"slot": Slot.FLAG, "price": PRICE_FLAG, "value": "ring"},
	"flag_zigzag": {"slot": Slot.FLAG, "price": PRICE_FLAG, "value": "zigzag"},
	"flag_star": {"slot": Slot.FLAG, "price": PRICE_FLAG, "value": "star"},
	"palette_sunrise": {"slot": Slot.PALETTE, "price": 0, "value": "#ec7a2c"},
	"palette_amber": {"slot": Slot.PALETTE, "price": PRICE_PALETTE, "value": "#e39a1f"},
	"palette_coral": {"slot": Slot.PALETTE, "price": PRICE_PALETTE, "value": "#e5644a"},
	"palette_terracotta": {"slot": Slot.PALETTE, "price": PRICE_PALETTE, "value": "#c65a28"},
	"palette_rose": {"slot": Slot.PALETTE, "price": PRICE_PALETTE, "value": "#de5a6c"},
	"border_none": {"slot": Slot.BORDER, "price": 0, "value": ""},
	"border_ink": {"slot": Slot.BORDER, "price": PRICE_BORDER, "value": "ink"},
	"border_stripes": {"slot": Slot.BORDER, "price": PRICE_BORDER, "value": "stripes"},
	"border_bunting": {"slot": Slot.BORDER, "price": PRICE_BORDER, "value": "bunting"},
}

## 진행 보상으로 주는 항목(05 보상 일정). 온보딩 깃발 1종, 대역 3 팔레트, 대역 5 테두리.
const ONBOARDING_REWARD: String = "flag_diamond"
const BAND_REWARDS: Dictionary = {3: "palette_coral", 5: "border_bunting"}


static func ids_in(slot: Slot) -> Array[String]:
	var out: Array[String] = []
	for id: String in ITEMS:
		if int(ITEMS[id]["slot"]) == slot:
			out.append(id)
	return out


static func slot_of(id: String) -> Slot:
	return ITEMS[id]["slot"]


static func price_of(id: String) -> int:
	return int(ITEMS[id]["price"])


static func value_of(id: String) -> String:
	return str(ITEMS[id]["value"])


static func is_default(id: String) -> bool:
	return DEFAULTS.values().has(id)
