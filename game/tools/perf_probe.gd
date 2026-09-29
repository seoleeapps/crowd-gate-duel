extends SceneTree
## 성능 예산 측정(06 성능 예산). 실제 렌더러로 돌린다.
##   godot --path game --resolution 540x1170 --script res://tools/perf_probe.gd
##
##   - 군중 표현: 두 무리 500명일 때 늘어나는 드로우콜이 10 이하인가
##   - 판정 1구간: 1ms 미만인가
##   - 대국 화면 프레임 시간(이 개발 기기 기준, 실기기 대체 아님)

const FRAMES: int = 90
const CROWD_DRAW_CALL_BUDGET: int = 10
const RESOLVE_BUDGET_USEC: float = 1000.0

var _viewport: SubViewport
var _failures: PackedStringArray = []


func _initialize() -> void:
	create_timer(120.0, true, false, true).timeout.connect(func() -> void:
		print("[perf] FAIL 감시 시간 초과")
		quit(1)
	)
	_run.call_deferred()


func _run() -> void:
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(1080, 2340)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_viewport)

	var small: Dictionary = await _measure_world(12, 12)
	var large: Dictionary = await _measure_world(500, 480)
	var delta: int = int(large["draw_calls"]) - int(small["draw_calls"])
	print("[perf] 드로우콜 12:12=%d 500:480=%d 증가=%d (예산 %d)" % [small["draw_calls"], large["draw_calls"], delta, CROWD_DRAW_CALL_BUDGET])
	print("[perf] 프레임 시간 500:480 평균 %.2fms 최대 %.2fms" % [large["avg_ms"], large["max_ms"]])
	if delta > CROWD_DRAW_CALL_BUDGET:
		_failures.append("군중 드로우콜 증가 %d > %d" % [delta, CROWD_DRAW_CALL_BUDGET])

	var usec: float = _bench_resolve()
	print("[perf] 판정 1구간 평균 %.1fµs (예산 %.0fµs)" % [usec, RESOLVE_BUDGET_USEC])
	if usec >= RESOLVE_BUDGET_USEC:
		_failures.append("판정 1구간 %.1fµs" % usec)

	if _failures.is_empty():
		print("[perf] ALL GREEN")
		quit(0)
	else:
		for failure: String in _failures:
			print("[perf] FAIL %s" % failure)
		quit(1)


## 대국 화면의 세계만 띄워 두 무리를 세우고 드로우콜과 프레임 시간을 잰다.
func _measure_world(me: int, opp: int) -> Dictionary:
	for child: Node in _viewport.get_children():
		child.queue_free()
	var world: WorldView = WorldView.new()
	world.size = Vector2(1080, 1680)
	_viewport.add_child(world)
	await process_frame
	world.set_standing(me, opp, 0.6, false)
	for i: int in range(10):
		await process_frame
	var draw_calls: int = 0
	var total_ms: float = 0.0
	var max_ms: float = 0.0
	for i: int in range(FRAMES):
		var start: int = Time.get_ticks_usec()
		await process_frame
		var ms: float = float(Time.get_ticks_usec() - start) / 1000.0
		total_ms += ms
		max_ms = maxf(max_ms, ms)
		draw_calls = maxi(draw_calls, int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)))
	return {"draw_calls": draw_calls, "avg_ms": total_ms / float(FRAMES), "max_ms": max_ms}


func _bench_resolve() -> float:
	var course: Course = CourseGenerator.generate("perf-bench", 5)
	var rounds: int = 20000
	var start: int = Time.get_ticks_usec()
	for i: int in range(rounds):
		var gates: Array[Gate] = course.gates_at(i % course.segment_count())
		DuelEngine.resolve_segment(40 + i % 50, 60 - i % 30, gates, i % 3, (i / 3) % 3)
	return float(Time.get_ticks_usec() - start) / float(rounds)
