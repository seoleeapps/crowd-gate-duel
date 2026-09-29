class_name TestRecords
extends RefCounted
## 상대 기록 경로. AC-005 재생 일치, AC-006 판당 원격 읽기 1건·쓰기 1건,
## AC-007 오프라인 봇 폴백과 재연결 시 1건 업로드, 그리고 봇 위장 금지(DEC-003).

const STORE_PATH: String = "user://test_records_progress.json"


static func run() -> TestBase:
	var t: TestBase = TestBase.new("records")
	_test_record_has_no_result(t)
	_test_record_rejects_bad_input(t)
	_test_replay_matches_original(t)
	_test_remote_budget_per_duel(t)
	_test_offline_bot_and_reconnect_upload(t)
	_test_slow_fetch_goes_bot_then_reuses(t)
	AtomicFileStore.remove(STORE_PATH)
	return t


## 사람이 한 판을 두고 기록을 남긴 상황을 만든다.
static func _recorded_duel(seed_text: String, band: int, name: String) -> DuelSession:
	var course: Course = CourseValidator.generate_valid(seed_text, band)["course"]
	var session: DuelSession = DuelSession.new(
		course, Opponent.bot(band), int(CourseGenerator.band_config(band)["commit_ms"])
	)
	var i: int = 0
	while session.present_next():
		session.commit((i * 7 + name.length()) % 3)
		i += 1
	return session


static func _test_record_has_no_result(t: TestBase) -> void:
	var session: DuelSession = _recorded_duel("no-result", 2, "kim")
	var data: Dictionary = session.to_record("kim", 1000).to_dict()
	var keys: Array = data.keys()
	keys.sort()
	t.check_eq(
		keys,
		["band", "courseSeed", "createdAt", "displayName", "picks", "schemaVersion"],
		"기록 필드는 06 데이터 계약 그대로이고 결과 수치가 없다"
	)


static func _test_record_rejects_bad_input(t: TestBase) -> void:
	var good: Dictionary = _recorded_duel("reject", 3, "lee").to_record("lee", 1).to_dict()
	t.check(ReplayRecord.from_dict(good) != null, "정상 기록은 통과")

	var cases: Dictionary = {
		"미래 규칙 버전": {"schemaVersion": ReplayRecord.SCHEMA_VERSION + 1},
		"범위 밖 선택": {"picks": [0, 3, 1]},
		"숫자가 아닌 선택": {"picks": ["a"]},
		"대역 범위 밖": {"band": 9},
		"빈 시드": {"courseSeed": ""},
	}
	for label: String in cases:
		var bad: Dictionary = good.duplicate(true)
		bad.merge(cases[label], true)
		t.check(ReplayRecord.from_dict(bad) == null, "거부: %s" % label)

	var short: Dictionary = good.duplicate(true)
	short["picks"] = [0]
	var short_record: ReplayRecord = ReplayRecord.from_dict(short)
	t.check(short_record != null and not short_record.is_playable(), "구간 수와 선택 수가 다르면 재생 불가")


static func _test_replay_matches_original(t: TestBase) -> void:
	# AC-005. 원격을 거친 기록으로 대국하면 상대의 구간별 선택과 군중 궤적이 원본과 같아야 한다.
	var mismatches: int = 0
	for i: int in range(20):
		var original: DuelSession = _recorded_duel("replay-src-%d" % i, 1 + i % 5, "p%d" % i)
		var wire: Variant = JSON.parse_string(JSON.stringify(original.to_record("p", 0).to_dict()))
		var record: ReplayRecord = ReplayRecord.from_dict(wire)

		# 새 플레이어가 그 기록을 상대로, 원본의 봇이 뒀던 수를 그대로 둔다.
		var challenger: DuelSession = DuelSession.new(
			record.build_course(), Opponent.from_record(record), 3000
		)
		var j: int = 0
		while challenger.present_next():
			challenger.commit(original.picks_opp[j])
			j += 1

		if challenger.picks_opp != original.picks_me:
			mismatches += 1
		for k: int in range(original.trace.size()):
			if int(challenger.trace[k]["opp"]) != int(original.trace[k]["me"]):
				mismatches += 1
			if int(challenger.trace[k]["me"]) != int(original.trace[k]["opp"]):
				mismatches += 1
	t.check_eq(mismatches, 0, "기록 20건 재생이 원본과 구간별로 100% 일치")


static func _test_remote_budget_per_duel(t: TestBase) -> void:
	# AC-006. 한 판 = 미리 받기 1건 + 끝난 뒤 올리기 1건. 판 도중 요청 0건.
	var port: LocalRemoteRecordPort = LocalRemoteRecordPort.new()
	port.pool.append(_recorded_duel("budget-src", 2, "park").to_record("park", 0).to_dict())
	var store: ProgressStore = ProgressStore.new(STORE_PATH)
	var resolver: OpponentResolver = OpponentResolver.new(port)
	var sync: RecordSync = RecordSync.new(port, store)

	resolver.prefetch(2)
	resolver.prefetch(2)
	var setup: Dictionary = resolver.take_setup(2, "budget-fallback")
	var opponent: Opponent = setup["opponent"]
	t.check(not opponent.is_bot(), "기록이 있으면 기록 상대")
	t.check_eq(opponent.display_name(), "park", "기록 상대는 사람의 표시명")

	var session: DuelSession = DuelSession.new(setup["course"], opponent, 3500)
	var reads_before_play: int = port.read_count
	while session.present_next():
		session.commit(1)
	t.check_eq(port.read_count - reads_before_play, 0, "판 진행 중 원격 요청 0건")
	sync.submit(session.to_record("me", 5))

	t.check_eq(port.read_count, 1, "판당 읽기 1건")
	t.check_eq(port.write_count, 1, "판당 쓰기 1건")
	t.check_eq(port.my_document["picks"], session.picks_me, "내 문서는 선택 시퀀스로 덮어써진다")
	t.check(store.pending_upload().is_empty(), "올리고 나면 대기 기록이 비워진다")


static func _test_offline_bot_and_reconnect_upload(t: TestBase) -> void:
	# AC-007. 연결이 없으면 봇 상대로 판이 완결되고, 기록은 로컬에 있다가 재연결 때 1건으로 올라간다.
	AtomicFileStore.remove(STORE_PATH)
	var port: LocalRemoteRecordPort = LocalRemoteRecordPort.new()
	port.online = false
	var store: ProgressStore = ProgressStore.new(STORE_PATH)
	var resolver: OpponentResolver = OpponentResolver.new(port)
	var sync: RecordSync = RecordSync.new(port, store)

	resolver.prefetch(1)
	t.check_eq(port.read_count, 0, "오프라인이면 읽기 요청을 보내지 않는다")
	var setup: Dictionary = resolver.take_setup(1, "offline-1")
	var opponent: Opponent = setup["opponent"]
	t.check(opponent.is_bot(), "오프라인이면 봇 상대")
	t.check_eq(opponent.display_name(), "", "봇에는 사람 표시명이 없다")

	var last_picks: Array[int] = []
	for n: int in range(3):
		var session: DuelSession = DuelSession.new(
			resolver.take_setup(1, "offline-%d" % n)["course"], Opponent.bot(1), 4000
		)
		while session.present_next():
			session.commit(n % 3)
		t.check(session.is_finished(), "오프라인 판 %d 완결" % n)
		sync.submit(session.to_record("me", n))
		last_picks = session.picks_me
	t.check_eq(port.write_count, 0, "오프라인 동안 쓰기 0건")

	# 앱을 다시 켠 것처럼 저장소를 새로 읽는다.
	var reopened: ProgressStore = ProgressStore.new(STORE_PATH)
	reopened.read()
	t.check(not reopened.pending_upload().is_empty(), "대기 기록이 디스크에 남아 있다")
	var sync_after: RecordSync = RecordSync.new(port, reopened)
	port.online = true
	sync_after.flush()
	t.check_eq(port.write_count, 1, "재연결 시 1건만 올린다")
	var uploaded: Array[int] = []
	for raw: Variant in port.my_document["picks"]:
		uploaded.append(int(raw))
	t.check_eq(uploaded, last_picks, "올라간 것은 가장 최근 판의 기록")


static func _test_slow_fetch_goes_bot_then_reuses(t: TestBase) -> void:
	# 기록이 늦으면 기다리지 않고 봇으로 시작한다. 늦게 온 기록은 다음 판에 쓰고 다시 읽지 않는다.
	var port: LocalRemoteRecordPort = LocalRemoteRecordPort.new()
	port.respond_immediately = false
	port.pool.append(_recorded_duel("slow-src", 3, "choi").to_record("choi", 0).to_dict())
	var resolver: OpponentResolver = OpponentResolver.new(port)

	resolver.prefetch(3)
	t.check(resolver.is_pending(), "요청 중")
	var first: Dictionary = resolver.take_setup(3, "slow-fallback")
	t.check((first["opponent"] as Opponent).is_bot(), "응답 전이면 즉시 봇")

	port.deliver()
	resolver.prefetch(3)
	t.check_eq(port.read_count, 1, "늦게 온 기록이 있으면 다음 판에 다시 읽지 않는다")
	var second: Dictionary = resolver.take_setup(3, "slow-fallback-2")
	t.check(not (second["opponent"] as Opponent).is_bot(), "다음 판은 늦게 온 기록 상대")

	# 늦게 온 기록을 기다리는 사이 대역이 올랐으면 그 기록을 쓰지 않는다.
	resolver.prefetch(3)
	port.deliver()
	var promoted: Dictionary = resolver.take_setup(4, "slow-promoted")
	t.check((promoted["opponent"] as Opponent).is_bot(), "대역이 달라진 기록은 쓰지 않는다")
	t.check_eq((promoted["course"] as Course).band, 4, "지금 대역의 코스로 시작")
