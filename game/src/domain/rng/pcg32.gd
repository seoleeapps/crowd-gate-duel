class_name Pcg32
extends RefCounted
## PCG32 (pcg32_random_r) 결정론 PRNG. 버전 고정 직접 구현.
## 규칙·분배·AI는 이 스트림만 사용한다. 부동소수점을 쓰지 않는다.

const MUL: int = 6364136223846793005
const MASK32: int = 0xFFFFFFFF

var state: int = 0
var inc: int = 1


static func seeded(initstate: int, initseq: int) -> Pcg32:
	var rng: Pcg32 = Pcg32.new()
	rng.state = 0
	rng.inc = ((initseq << 1) | 1)
	rng.next_u32()
	rng.state = rng.state + initstate
	rng.next_u32()
	return rng


static func from_state(saved_state: int, saved_inc: int) -> Pcg32:
	var rng: Pcg32 = Pcg32.new()
	rng.state = saved_state
	rng.inc = saved_inc
	return rng


## 부호 없는 64비트 논리 우측 시프트 (GDScript int는 부호 있는 64비트).
static func lsr64(value: int, amount: int) -> int:
	if amount <= 0:
		return value
	if amount >= 64:
		return 0
	return (value >> amount) & ~((-1) << (64 - amount))


func next_u32() -> int:
	var old: int = state
	state = old * MUL + inc
	var xorshifted: int = Pcg32.lsr64(Pcg32.lsr64(old, 18) ^ old, 27) & MASK32
	var rot: int = Pcg32.lsr64(old, 59)
	return ((xorshifted >> rot) | ((xorshifted << ((32 - rot) & 31)) & MASK32)) & MASK32


## [0, bound) 균등 정수. 모듈로 편향 제거(threshold 기법).
func next_below(bound: int) -> int:
	assert(bound > 0)
	var threshold: int = (0x100000000 - bound) % bound
	while true:
		var r: int = next_u32()
		if r >= threshold:
			return r % bound
	return 0


## Fisher–Yates: index 47부터 1까지 감소하며 스왑 (RULESET 결정론 계약).
func shuffle_in_place(items: Array) -> void:
	var i: int = items.size() - 1
	while i >= 1:
		var j: int = next_below(i + 1)
		var tmp: Variant = items[i]
		items[i] = items[j]
		items[j] = tmp
		i -= 1


func snapshot() -> Dictionary:
	return {"state": state, "inc": inc}
