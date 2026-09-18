class_name TestBase
extends RefCounted
## 경량 테스트 하네스. 실패를 모아 요약하고 종료 코드를 결정한다.

var suite_name: String = ""
var passed: int = 0
var failed: int = 0
var failures: Array[String] = []


func _init(suite_name_in: String) -> void:
	suite_name = suite_name_in


func check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		failures.append(label)
		print("  [FAIL] %s :: %s" % [suite_name, label])


func check_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual == expected:
		passed += 1
	else:
		failed += 1
		failures.append(label)
		print("  [FAIL] %s :: %s (expected=%s actual=%s)" % [suite_name, label, str(expected), str(actual)])


func summary() -> String:
	return "%s: %d passed, %d failed" % [suite_name, passed, failed]
