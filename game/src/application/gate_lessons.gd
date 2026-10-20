class_name GateLessons
extends RefCounted

static func example(kind: Gate.Kind) -> Dictionary:
	var gates: Array[Gate] = [Gate.make(Gate.Kind.STEAL, 20), Gate.make(Gate.Kind.ADD, 4)]
	var caption: String = "LESSON_STEAL"
	var pick: int = 0
	if kind == Gate.Kind.SHIELD:
		gates[1] = Gate.make(Gate.Kind.SHIELD, CourseGenerator.SHIELD_COUNTER)
		caption = "LESSON_SHIELD"
		pick = 1
	var result: Dictionary = DuelEngine.resolve_segment(12, 20, gates, pick, 0 if pick == 1 else 1)
	return {"caption": caption, "numbers": "%d → %d   :   %d → %d" % [12, result["a"], 20, result["b"]]}
