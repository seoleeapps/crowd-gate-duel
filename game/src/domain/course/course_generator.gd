class_name CourseGenerator
extends RefCounted
## 시드에서 코스를 조립하는 결정론 생성기.
##
## 외부 시드는 그대로 쓰지 않고 해싱해서 PCG32 에 넣는다(DEC-006). Godot 기본
## RandomNumberGenerator 는 애벌랜치 효과가 없어 비슷한 시드가 비슷한 수열을 내므로
## 날짜·대역처럼 서로 닮은 시드를 그대로 쓰면 코스가 서로 닮아 버린다.
##
## 구간 구성은 네 패턴 중 하나다. 빼앗기와 방패는 구간당 최대 1칸이며, 방패는 빼앗기가
## 같은 구간에 있을 때만 등장한다. 방패만 있는 구간은 막을 대상이 없어 죽은 칸이 되기 때문이다.
##   P1 {불리기, 모으기, 성장 한 칸 더}  — 성장만
##   P2 {불리기, 모으기, 빼앗기}
##   P3 {불리기, 빼앗기, 방패}
##   P4 {모으기, 빼앗기, 방패}

const START_CROWD: int = 12

## 한 구간의 칸들은 서로 비슷한 가치를 가져야 한다. 한 칸이 압도적으로 좋으면 그 칸이
## 자명한 정답이 되어 상대를 읽을 이유가 사라진다. 그래서 값을 독립적으로 뽑지 않고
## **구간마다 목표 이득을 먼저 정한 뒤 각 칸이 그 근처가 되도록 역산**한다.
##
## 불리기는 복리라 배수를 크게 두면 구간이 쌓일수록 모으기를 구조적으로 압도한다.
## 실측에서 독립 추첨 방식은 "늘 불리기" 승률 87%, 구간 내 기대값 비 5배를 만들었다.
const TARGET_GAIN_MIN_PCT: int = 40  ## 그 구간 예상 군중 대비
const TARGET_GAIN_MAX_PCT: int = 90
const GATE_SPREAD_MIN_PCT: int = 80  ## 목표 이득 대비 칸별 편차
const GATE_SPREAD_MAX_PCT: int = 125
const MULTIPLY_MIN: int = 120
const MULTIPLY_MAX: int = 260
const ADD_FLOOR: int = 6

## 구간당 평균 성장률(백분율). 예상 군중 곡선을 그리는 데만 쓴다.
const EXPECTED_GROWTH_PCT: int = 145

const STEAL_MIN: int = 15
const STEAL_MAX: int = 25
const SHIELD_COUNTER: int = 10

## 대역별 파라미터. 05-economy-content-liveops.md 의 난이도 테이블과 같은 값이다.
const BANDS: Array[Dictionary] = [
	{"band": 1, "segments": 5, "special_pct": 0, "commit_ms": 4000},
	{"band": 2, "segments": 6, "special_pct": 15, "commit_ms": 3500},
	{"band": 3, "segments": 7, "special_pct": 25, "commit_ms": 3000},
	{"band": 4, "segments": 8, "special_pct": 35, "commit_ms": 2800},
	{"band": 5, "segments": 9, "special_pct": 40, "commit_ms": 2500},
]


static func band_config(band: int) -> Dictionary:
	var index: int = clampi(band, 1, BANDS.size()) - 1
	return BANDS[index]


## 외부 시드 문자열을 64비트로 흩뜨린다. FNV-1a 64 변형.
static func hash_seed(seed_text: String) -> int:
	var hash_value: int = 0x00000100000001B3
	for code: int in seed_text.to_utf8_buffer():
		hash_value = hash_value ^ code
		hash_value = hash_value * 0x100000001B3
	return hash_value


static func generate(seed_text: String, band: int) -> Course:
	var config: Dictionary = band_config(band)
	var rng: Pcg32 = Pcg32.seeded(hash_seed(seed_text), int(config["band"]))

	var course: Course = Course.new()
	course.seed_text = seed_text
	course.band = int(config["band"])
	course.start_crowd_a = START_CROWD
	course.start_crowd_b = START_CROWD
	course.segments = []

	var special_pct: int = int(config["special_pct"])
	var segment_count: int = int(config["segments"])
	for i: int in range(segment_count):
		course.segments.append(_build_segment(rng, special_pct, expected_crowd_at(i)))
	return course


## 구간 i 에 도달했을 때의 예상 군중 수. 모으기 값을 그 시점 규모에 맞추는 데 쓴다.
static func expected_crowd_at(segment_index: int) -> int:
	var crowd: int = START_CROWD
	for _k: int in range(segment_index):
		crowd = crowd * EXPECTED_GROWTH_PCT / 100
	return crowd


static func _build_segment(rng: Pcg32, special_pct: int, expected_crowd: int) -> Array[Gate]:
	var gates: Array[Gate] = []
	# 이 구간에서 한 칸이 대략 얼마를 벌어야 하는지 먼저 정한다.
	var span: int = TARGET_GAIN_MAX_PCT - TARGET_GAIN_MIN_PCT + 1
	var target_gain: int = maxi(
		ADD_FLOOR, expected_crowd * (TARGET_GAIN_MIN_PCT + rng.next_below(span)) / 100
	)
	var roll: int = rng.next_below(100)

	if roll < special_pct:
		# 특수 구간. 절반은 빼앗기만, 절반은 빼앗기와 방패가 함께 나와 순환 우위가 완성된다.
		if rng.next_below(2) == 0:
			gates.append(_multiply(rng, expected_crowd, target_gain))
			gates.append(_add(rng, target_gain))
			gates.append(_steal(rng))
		elif rng.next_below(2) == 0:
			gates.append(_multiply(rng, expected_crowd, target_gain))
			gates.append(_steal(rng))
			gates.append(Gate.make(Gate.Kind.SHIELD, SHIELD_COUNTER))
		else:
			gates.append(_add(rng, target_gain))
			gates.append(_steal(rng))
			gates.append(Gate.make(Gate.Kind.SHIELD, SHIELD_COUNTER))
	else:
		# 성장 구간. 불리기와 모으기가 반드시 함께 나와 우열 역전 판단이 성립한다.
		gates.append(_multiply(rng, expected_crowd, target_gain))
		gates.append(_add(rng, target_gain))
		if rng.next_below(2) == 0:
			gates.append(_multiply(rng, expected_crowd, target_gain))
		else:
			gates.append(_add(rng, target_gain))

	_shuffle_gates(rng, gates)
	return gates


## 목표 이득을 내도록 배수를 역산한다. 군중이 적은 초반에는 같은 이득을 내려면 배수가
## 커지고, 군중이 불어난 후반에는 배수가 작아진다. 화면에서 읽기 쉽도록 10 단위로 끊는다.
static func _multiply(rng: Pcg32, expected_crowd: int, target_gain: int) -> Gate:
	var gain: int = _spread(rng, target_gain)
	var pct: int = 100 + gain * 100 / maxi(1, expected_crowd)
	pct = (pct + 5) / 10 * 10
	return Gate.make(Gate.Kind.MULTIPLY, clampi(pct, MULTIPLY_MIN, MULTIPLY_MAX))


## 모으기 값도 같은 목표 이득에서 나온다. 그래서 전환점(= 모으기 값 / (배수 - 1))이
## 늘 그 구간의 군중 근처에 놓이고, 불리기와 모으기 중 무엇이 큰지가 매번 아슬아슬해진다.
static func _add(rng: Pcg32, target_gain: int) -> Gate:
	return Gate.make(Gate.Kind.ADD, maxi(ADD_FLOOR, _spread(rng, target_gain)))


## 목표 이득 주변으로 값을 흩뜨린다. 칸마다 조금씩 달라야 판단이 생긴다.
static func _spread(rng: Pcg32, target_gain: int) -> int:
	var span: int = GATE_SPREAD_MAX_PCT - GATE_SPREAD_MIN_PCT + 1
	return target_gain * (GATE_SPREAD_MIN_PCT + rng.next_below(span)) / 100


static func _steal(rng: Pcg32) -> Gate:
	return Gate.make(Gate.Kind.STEAL, STEAL_MIN + rng.next_below(STEAL_MAX - STEAL_MIN + 1))


## 칸 위치 편향을 없앤다. 확약 시간 초과 시 가장 왼쪽이 자동 선택되므로
## 종류가 늘 같은 자리에 오면 자동 선택이 특정 전략과 같아진다.
static func _shuffle_gates(rng: Pcg32, gates: Array[Gate]) -> void:
	var i: int = gates.size() - 1
	while i >= 1:
		var j: int = rng.next_below(i + 1)
		var tmp: Gate = gates[i]
		gates[i] = gates[j]
		gates[j] = tmp
		i -= 1
