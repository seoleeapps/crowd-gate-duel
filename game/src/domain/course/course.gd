class_name Course
extends RefCounted
## 한 판의 코스. 시드에서 결정론적으로 만들어지며 대국·재생·검증이 모두 이 객체를 공유한다.

var seed_text: String = ""
var band: int = 1
var start_crowd_a: int = 12
var start_crowd_b: int = 12
## Array[Array[Gate]] — 구간마다 게이트 3칸
var segments: Array = []


func segment_count() -> int:
	return segments.size()


func gates_at(index: int) -> Array[Gate]:
	var raw: Array = segments[index]
	var typed: Array[Gate] = []
	for gate: Gate in raw:
		typed.append(gate)
	return typed


## 구조 해시. 최근 코스와의 근접 중복 회피에 쓴다(variety_guard).
func structure_hash() -> String:
	var parts: Array[String] = []
	for raw: Array in segments:
		var piece: Array[String] = []
		for gate: Gate in raw:
			piece.append("%d:%d" % [int(gate.kind), gate.value])
		parts.append("|".join(piece))
	return "/".join(parts)


func to_dict() -> Dictionary:
	var out_segments: Array = []
	for raw: Array in segments:
		var one: Array = []
		for gate: Gate in raw:
			one.append(gate.to_dict())
		out_segments.append(one)
	return {
		"seed_text": seed_text,
		"band": band,
		"start_crowd_a": start_crowd_a,
		"start_crowd_b": start_crowd_b,
		"segments": out_segments,
	}


static func from_dict(data: Dictionary) -> Course:
	var course: Course = Course.new()
	course.seed_text = str(data["seed_text"])
	course.band = int(data["band"])
	course.start_crowd_a = int(data["start_crowd_a"])
	course.start_crowd_b = int(data["start_crowd_b"])
	course.segments = []
	for raw: Array in data["segments"]:
		var one: Array[Gate] = []
		for gate_data: Dictionary in raw:
			one.append(Gate.from_dict(gate_data))
		course.segments.append(one)
	return course
