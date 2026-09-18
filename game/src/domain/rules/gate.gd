class_name Gate
extends RefCounted
## 갈림길 게이트 한 칸. 값은 전부 정수이며 규칙 판정에 부동소수점을 쓰지 않는다.
##
## value 의 뜻은 kind 마다 다르다.
##   MULTIPLY : 배수의 백분율. 200 이면 2.0배
##   ADD      : 더할 군중 수
##   STEAL    : 상대 군중에서 가져올 비율(퍼센트)
##   SHIELD   : 빼앗기를 막아냈을 때 반격으로 가져올 비율(퍼센트)

enum Kind { MULTIPLY, ADD, STEAL, SHIELD }

var kind: Kind = Kind.ADD
var value: int = 0


static func make(kind_in: Kind, value_in: int) -> Gate:
	var gate: Gate = Gate.new()
	gate.kind = kind_in
	gate.value = value_in
	return gate


static func kind_name(kind_in: Kind) -> String:
	match kind_in:
		Kind.MULTIPLY:
			return "불리기"
		Kind.ADD:
			return "모으기"
		Kind.STEAL:
			return "빼앗기"
		Kind.SHIELD:
			return "방패"
	return "알수없음"


func is_growth() -> bool:
	return kind == Kind.MULTIPLY or kind == Kind.ADD


## 이 게이트를 혼자 골랐을 때 내 군중이 얻는 증가분.
## 상대와 겹쳐 반감되면 halved 가 true 다. 상호작용(빼앗기·방패)은 여기서 계산하지 않는다.
func growth_gain(crowd: int, halved: bool) -> int:
	var gain: int = 0
	match kind:
		Kind.MULTIPLY:
			gain = crowd * (value - 100) / 100
		Kind.ADD:
			gain = value
		_:
			return 0
	if halved:
		gain = gain / 2
	return gain


func to_dict() -> Dictionary:
	return {"kind": int(kind), "value": value}


static func from_dict(data: Dictionary) -> Gate:
	return Gate.make(data["kind"] as Kind, int(data["value"]))
