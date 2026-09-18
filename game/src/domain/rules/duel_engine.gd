class_name DuelEngine
extends RefCounted
## 한 구간의 판정과 한 판 전체의 진행을 담당하는 순수 규칙 레이어.
## Godot 노드와 플랫폼 SDK 를 참조하지 않는다. 같은 입력은 언제나 같은 결과를 낸다.
##
## 해소 순서는 02-gdd.md 의 계약을 그대로 따른다.
##   1. 양쪽 선택을 동시에 공개한다
##   2. 같은 칸이면 우선권을 정한다. 군중이 적은 쪽이 그 게이트를 온전히 가져가고
##      많은 쪽은 아무것도 얻지 못한다. 동수일 때만 반씩 나눠 갖는다
##   3. 방패를 먼저 해소한다
##   4. 빼앗기를 해소한다. 상대가 방패면 무효가 되고 방패 쪽이 반격 이득을 얻는다
##   5. 불리기와 모으기를 해소한다
##   6. 군중 수를 정수로 내림 처리하고 최소 1 로 보정한다
##
## 모든 효과는 구간 시작 시점의 군중 수(스냅샷)를 기준으로 계산한 뒤 마지막에 함께 적용한다.
## 순차 적용하면 처리 순서에 따라 결과가 달라져 재현이 깨진다.

const MIN_CROWD: int = 1

## 결과 코드
const RESULT_A_WIN: int = 1
const RESULT_B_WIN: int = -1
const RESULT_DRAW: int = 0


## 한 구간을 해소한다. gates 는 3칸, pick 은 0~2 인덱스다.
## 반환: { "a": int, "b": int, "split": bool, "events": Array[String] }
static func resolve_segment(
	crowd_a: int, crowd_b: int, gates: Array[Gate], pick_a: int, pick_b: int
) -> Dictionary:
	assert(pick_a >= 0 and pick_a < gates.size())
	assert(pick_b >= 0 and pick_b < gates.size())

	var split: bool = pick_a == pick_b
	var ga: Gate = gates[pick_a]
	var gb: Gate = gates[pick_b]
	var delta_a: int = 0
	var delta_b: int = 0
	var events: Array[String] = []

	if split:
		events.append("split")
		if ga.kind == Gate.Kind.SHIELD:
			# 양쪽 방패면 막을 빼앗기가 없으므로 아무 일도 일어나지 않는다.
			events.append("shield_idle")
		elif crowd_a == crowd_b:
			# 동수면 우선권을 줄 기준이 없다. 이때만 반씩 나눠 갖는다.
			events.append("split_even")
			delta_a += ga.growth_gain(crowd_a, true)
			delta_b += ga.growth_gain(crowd_b, true)
			if ga.kind == Gate.Kind.STEAL:
				var half_pct: int = ga.value / 2
				var a_takes: int = crowd_b * half_pct / 100
				var b_takes: int = crowd_a * half_pct / 100
				delta_a += a_takes - b_takes
				delta_b += b_takes - a_takes
		else:
			# 뒤처진 쪽이 먼저 지나간다. 앞선 쪽은 아무것도 얻지 못한다.
			#
			# 이 비대칭이 이 게임의 심리전을 만든다. 반감처럼 양쪽에 똑같이 적용하면
			# 겹쳐도 격차가 변하지 않아 "늘 가장 센 칸"이 지배 전략이 되고, 상대를 읽을
			# 이유가 사라진다. 우선권을 뒤처진 쪽에 주면 앞선 쪽은 겹침을 피해야 하고
			# 뒤처진 쪽은 겹침을 노려야 해서 매 구간 유인이 정반대가 된다.
			var a_behind: bool = crowd_a < crowd_b
			events.append("yield_to_a" if a_behind else "yield_to_b")
			var mine: int = crowd_a if a_behind else crowd_b
			var theirs: int = crowd_b if a_behind else crowd_a
			var gain: int = ga.growth_gain(mine, false)
			var taken: int = 0
			if ga.kind == Gate.Kind.STEAL:
				taken = theirs * ga.value / 100
			if a_behind:
				delta_a += gain + taken
				delta_b -= taken
			else:
				delta_b += gain + taken
				delta_a -= taken
	else:
		# 성장은 각자 자기 군중에만 적용한다.
		delta_a += ga.growth_gain(crowd_a, false)
		delta_b += gb.growth_gain(crowd_b, false)

		# 빼앗기와 방패의 상호작용. 생성기가 구간당 빼앗기·방패를 각각 최대 1칸으로
		# 제한하므로 서로 다른 칸에서 양쪽 모두 빼앗기인 경우는 존재하지 않는다.
		if ga.kind == Gate.Kind.STEAL:
			if gb.kind == Gate.Kind.SHIELD:
				var counter_b: int = crowd_a * gb.value / 100
				delta_a -= counter_b
				delta_b += counter_b
				events.append("shield_counter_b")
			else:
				var stolen_a: int = crowd_b * ga.value / 100
				delta_a += stolen_a
				delta_b -= stolen_a
				events.append("steal_a")
		elif gb.kind == Gate.Kind.STEAL:
			if ga.kind == Gate.Kind.SHIELD:
				var counter_a: int = crowd_b * ga.value / 100
				delta_b -= counter_a
				delta_a += counter_a
				events.append("shield_counter_a")
			else:
				var stolen_b: int = crowd_a * gb.value / 100
				delta_b += stolen_b
				delta_a -= stolen_b
				events.append("steal_b")

	var next_a: int = max(MIN_CROWD, crowd_a + delta_a)
	var next_b: int = max(MIN_CROWD, crowd_b + delta_b)
	return {"a": next_a, "b": next_b, "split": split, "events": events}


## 코스 전체를 선택열대로 진행한다. picks_a / picks_b 는 구간 수와 길이가 같아야 한다.
## 반환: { "a": int, "b": int, "result": int, "splits": int, "trace": Array[Dictionary] }
static func play(course: Course, picks_a: Array[int], picks_b: Array[int]) -> Dictionary:
	assert(picks_a.size() == course.segments.size())
	assert(picks_b.size() == course.segments.size())

	var crowd_a: int = course.start_crowd_a
	var crowd_b: int = course.start_crowd_b
	var splits: int = 0
	var trace: Array[Dictionary] = []

	for i: int in range(course.segments.size()):
		var gates: Array[Gate] = course.segments[i]
		var step: Dictionary = resolve_segment(crowd_a, crowd_b, gates, picks_a[i], picks_b[i])
		crowd_a = int(step["a"])
		crowd_b = int(step["b"])
		if bool(step["split"]):
			splits += 1
		trace.append({
			"segment": i,
			"pick_a": picks_a[i],
			"pick_b": picks_b[i],
			"a": crowd_a,
			"b": crowd_b,
			"split": step["split"],
		})

	var result: int = RESULT_DRAW
	if crowd_a > crowd_b:
		result = RESULT_A_WIN
	elif crowd_b > crowd_a:
		result = RESULT_B_WIN

	return {"a": crowd_a, "b": crowd_b, "result": result, "splits": splits, "trace": trace}


## 확약 시간이 끝났을 때의 자동 선택. 가장 왼쪽 칸이다(02-gdd.md 계약).
static func auto_pick(_gates: Array[Gate]) -> int:
	return 0
