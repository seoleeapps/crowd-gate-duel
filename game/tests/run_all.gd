extends SceneTree
## 헤드리스 테스트 러너.
##   godot --headless --path game --script res://tests/run_all.gd
## 실패가 있으면 종료 코드 1. CI 는 로그의 SCRIPT ERROR 도 함께 검사한다.


func _initialize() -> void:
	var suites: Array[TestBase] = []
	print("[run_all] 갈림길 군중 대전 도메인 테스트 시작")
	suites.append(TestPcg32.run())
	suites.append(TestGateRules.run())
	suites.append(TestDeterminism.run())
	suites.append(TestGenerator.run())
	suites.append(TestStrategyMatrix.run())

	var total_passed: int = 0
	var total_failed: int = 0
	print("\n[run_all] 결과 요약")
	for suite: TestBase in suites:
		print("  " + suite.summary())
		total_passed += suite.passed
		total_failed += suite.failed
	print("[run_all] 합계: %d passed, %d failed" % [total_passed, total_failed])
	if total_failed > 0:
		print("[run_all] FAILED")
		quit(1)
	else:
		print("[run_all] ALL GREEN")
		quit(0)
