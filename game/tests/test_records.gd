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
		["band", "commitExtended", "courseSeed", "createdAt", "displayName", "picks", "schemaVersion"],
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


