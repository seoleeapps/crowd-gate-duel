class_name TestDuelSession
extends RefCounted
## 대국 상태 머신. 확약 만료 자동 선택, 일시정지 재개, 진행 중 판 복원,
## 그리고 세션 경로와 순수 판정 경로가 같은 결과를 내는지(AC-003) 본다.


static func run() -> TestBase:
	var t: TestBase = TestBase.new("duel_session")
	_test_flow_matches_engine(t)
	_test_commit_is_final(t)
	_test_timeout_auto_picks_leftmost(t)
	_test_pause_keeps_remaining(t)
	_test_snapshot_restore(t)
	return t


static func _bot_session(seed_text: String, band: int) -> DuelSession:
	var course: Course = CourseValidator.generate_valid(seed_text, band)["course"]
	var commit_ms: int = int(CourseGenerator.band_config(band)["commit_ms"])
	return DuelSession.new(course, Opponent.bot(band), commit_ms)


static func _play_through(session: DuelSession, picks: Array[int]) -> void:
	var i: int = 0
	while session.present_next():
		session.commit(picks[i % picks.size()])
		i += 1


static func _test_flow_matches_engine(t: TestBase) -> void:
	var mismatches: int = 0
	for i: int in range(30):
		var session: DuelSession = _bot_session("session-%d" % i, 1 + i % 5)
		_play_through(session, [i % 3, (i + 1) % 3, 2])
		var replayed: Dictionary = DuelEngine.play(session.course, session.picks_me, session.picks_opp)
		if int(replayed["a"]) != session.crowd_me or int(replayed["b"]) != session.crowd_opp:
			mismatches += 1
		if int(replayed["result"]) != session.result():
			mismatches += 1
	t.check_eq(mismatches, 0, "세션 30판이 순수 판정 재실행과 100% 일치")

	var again_a: DuelSession = _bot_session("session-repeat", 3)
	var again_b: DuelSession = _bot_session("session-repeat", 3)
	_play_through(again_a, [0, 1, 2])
	_play_through(again_b, [0, 1, 2])
	t.check_eq(again_a.picks_opp, again_b.picks_opp, "같은 코스·같은 선택이면 봇 선택도 같다")
	t.check(again_a.is_finished(), "구간을 다 쓰면 종료 상태")
	t.check_eq(again_a.trace.size(), again_a.course.segment_count(), "구간마다 해소 기록 1건")


static func _test_commit_is_final(t: TestBase) -> void:
	var session: DuelSession = _bot_session("commit-final", 2)
	session.present_next()
	var first: Dictionary = session.commit(1)
	var second: Dictionary = session.commit(0)
	t.check(not first.is_empty(), "확약하면 곧바로 해소 결과가 나온다")
	t.check(second.is_empty(), "해소 뒤 같은 구간에 다시 확약할 수 없다")
	t.check_eq(session.picks_me, [1] as Array[int], "첫 확약만 남는다")
	t.check(session.commit(5).is_empty(), "범위 밖 선택은 무시된다")


static func _test_timeout_auto_picks_leftmost(t: TestBase) -> void:
	var session: DuelSession = _bot_session("timeout", 1)
	session.present_next()
	t.check(session.tick(session.commit_ms - 1).is_empty(), "만료 전에는 아무 일도 없다")
	var step: Dictionary = session.tick(1)
	t.check(not step.is_empty(), "만료 순간 자동 확약")
	t.check_eq(int(step["pick_me"]), 0, "자동 선택은 가장 왼쪽 칸")
	t.check(bool(step["auto"]), "자동 선택으로 표시된다")


static func _test_pause_keeps_remaining(t: TestBase) -> void:
	var session: DuelSession = _bot_session("pause", 3)
	session.present_next()
	session.tick(1000)
	var left: int = session.remaining_ms
	session.pause()
	t.check(session.tick(60000).is_empty(), "일시정지 중에는 시간이 흐르지 않는다")
	t.check(session.commit(0).is_empty(), "일시정지 중에는 확약할 수 없다")
	session.resume()
	t.check_eq(session.remaining_ms, left, "복귀하면 남은 시간부터 재개")


static func _test_snapshot_restore(t: TestBase) -> void:
	var session: DuelSession = _bot_session("snapshot", 4)
	for pick: int in [2, 0, 1]:
		session.present_next()
		session.commit(pick)
	session.present_next()
	session.tick(700)

	# 저장 파일을 거친 것처럼 JSON 왕복을 시킨다. 숫자가 float 으로 돌아와도 복원돼야 한다.
	var through_json: Variant = JSON.parse_string(JSON.stringify(session.to_dict()))
	var restored: DuelSession = DuelSession.from_dict(through_json)
	t.check(restored != null, "스냅샷 복원 성공")
	t.check_eq(restored.segment_index, session.segment_index, "같은 구간에서 재개")
	t.check_eq(restored.remaining_ms, session.remaining_ms, "남은 확약 시간 보존")
	t.check_eq(restored.crowd_me, session.crowd_me, "내 군중 재계산 일치")
	t.check_eq(restored.crowd_opp, session.crowd_opp, "상대 군중 재계산 일치")
	t.check_eq(restored.picks_opp, session.picks_opp, "봇 선택 재계산 일치")

	var broken: Dictionary = session.to_dict()
	broken["version"] = 99
	t.check(DuelSession.from_dict(broken) == null, "모르는 스냅샷 버전은 복원하지 않는다")

	# 기록 상대의 규칙 버전이 오르면 복원할 수 없다. 봇으로 바꿔 복원하지 않고 판을 버린다.
	var record: ReplayRecord = ReplayRecord.make("rec", 4, session.course.seed_text, [0, 1, 2, 0, 1, 2, 0, 1], 0)
	var with_record: DuelSession = DuelSession.new(session.course, Opponent.from_record(record), 2800)
	with_record.present_next()
	with_record.commit(1)
	var stale: Dictionary = with_record.to_dict()
	stale["opponent"]["record"]["schemaVersion"] = ReplayRecord.SCHEMA_VERSION + 1
	t.check(DuelSession.from_dict(stale) == null, "기록 상대를 복원할 수 없으면 판을 버린다")
