class_name GateLessons
extends RefCounted
## 현재 등장한 수치로, 다른 성장 효과가 없는 한 번의 상호작용을 보여 준다.

static func example(current: Array[Gate], kind: Gate.Kind) -> Dictionary:
	var active: Gate
	var steal: Gate
	for gate: Gate in current:
		if gate.kind == kind:
			active = gate
		if gate.kind == Gate.Kind.STEAL:
			steal = gate
	assert(active != null)
	var gates: Array[Gate] = [active, Gate.make(Gate.Kind.MULTIPLY, 100)]
	var caption: String = "LESSON_STEAL"
	if kind == Gate.Kind.SHIELD:
		assert(steal != null)
		gates[1] = steal
		caption = "LESSON_SHIELD"
	var result: Dictionary = DuelEngine.resolve_segment(12, 40, gates, 0, 1)
	return {"caption": caption, "percent": active.value,
		"numbers": "%d%% × 40 = %d\n12 → %d   :   40 → %d" % [active.value, int(result["a"]) - 12, result["a"], result["b"]]}
