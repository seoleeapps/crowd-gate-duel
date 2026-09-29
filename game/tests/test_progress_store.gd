class_name TestProgressStore
extends RefCounted
## 로컬 저장. 원자적 쓰기, 손상 시 직전 스냅샷 복구, 새 버전 파일의 읽기 전용 열기,
## 깃털·대역 규칙(05 재화 표).

const PATH: String = "user://test_progress.json"


static func run() -> TestBase:
	var t: TestBase = TestBase.new("progress_store")
	AtomicFileStore.remove(PATH)
	_test_round_trip(t)
	_test_corruption_recovers_backup(t)
	_test_newer_version_is_read_only(t)
	_test_rewards_and_bands(t)
	AtomicFileStore.remove(PATH)
	return t


static func _test_round_trip(t: TestBase) -> void:
	var store: ProgressStore = ProgressStore.new(PATH)
	store.read()
	t.check_eq(store.loaded_from, "none", "첫 실행은 기본값")
	store.apply_result(DuelEngine.RESULT_A_WIN, "2026-09-29")
	t.check_eq(store.write(), OK, "저장 성공")
	t.check(not FileAccess.file_exists(PATH + AtomicFileStore.TMP_SUFFIX), "임시 파일이 남지 않는다")

	var again: ProgressStore = ProgressStore.new(PATH)
	again.read()
	t.check_eq(again.loaded_from, "main", "본 파일에서 읽음")
	t.check_eq(again.wins(), 1, "승수 보존")
	t.check_eq(again.feathers(), store.feathers(), "깃털 보존")


static func _test_corruption_recovers_backup(t: TestBase) -> void:
	var store: ProgressStore = ProgressStore.new(PATH)
	store.read()
	var good_feathers: int = store.feathers()
	store.apply_result(DuelEngine.RESULT_B_WIN, "2026-09-29")
	store.write()  # 이때 직전 정상 파일이 스냅샷으로 복사된다

	# 본 파일을 반쯤 잘라 손상을 주입한다.
	var text: String = FileAccess.get_file_as_string(PATH)
	var file: FileAccess = FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(text.left(text.length() / 2))
	file.close()

	var recovered: ProgressStore = ProgressStore.new(PATH)
	recovered.read()
	t.check_eq(recovered.loaded_from, "backup", "손상되면 직전 스냅샷으로 복구")
	t.check_eq(recovered.feathers(), good_feathers, "스냅샷 시점의 진행")

	# 한 글자만 바뀌어도(체크섬 불일치) 손상으로 본다.
	store.write()
	var tampered: String = FileAccess.get_file_as_string(PATH).replace("\\\"wins\\\":1", "\\\"wins\\\":9")
	file = FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(tampered)
	file.close()
	var checked: ProgressStore = ProgressStore.new(PATH)
	checked.read()
	t.check_eq(checked.loaded_from, "backup", "체크섬이 맞지 않으면 스냅샷 사용")


static func _test_newer_version_is_read_only(t: TestBase) -> void:
	var future: Dictionary = ProgressStore.defaults()
	future["schema_version"] = ProgressStore.SCHEMA_VERSION + 1
	future["wins"] = 50
	AtomicFileStore.write(PATH, future)

	var store: ProgressStore = ProgressStore.new(PATH)
	store.read()
	t.check(store.read_only, "새 버전 저장은 읽기 전용으로 연다")
	t.check_eq(store.wins(), 50, "진행을 초기화하지 않는다")
	t.check(store.write() != OK, "읽기 전용이면 덮어쓰지 않는다")
	AtomicFileStore.remove(PATH)


static func _test_rewards_and_bands(t: TestBase) -> void:
	var store: ProgressStore = ProgressStore.new(PATH)
	var first: Dictionary = store.apply_result(DuelEngine.RESULT_A_WIN, "2026-09-29")
	t.check_eq(int(first["feathers"]), 30, "그날 첫 승은 10 + 20")
	var second: Dictionary = store.apply_result(DuelEngine.RESULT_A_WIN, "2026-09-29")
	t.check_eq(int(second["feathers"]), 10, "같은 날 두 번째 승은 10")
	t.check_eq(int(store.apply_result(DuelEngine.RESULT_B_WIN, "2026-09-29")["feathers"]), 3, "패배 3")
	t.check_eq(int(store.apply_result(DuelEngine.RESULT_DRAW, "2026-09-29")["feathers"]), 5, "무승부 5")

	t.check_eq(store.band(), 1, "2승은 대역 1")
	var third: Dictionary = store.apply_result(DuelEngine.RESULT_A_WIN, "2026-09-30")
	t.check_eq(int(third["band_after"]), 2, "3승에서 대역 2 해금")

	var cases: Dictionary = {0: 1, 2: 1, 3: 2, 14: 2, 15: 3, 40: 4, 79: 4, 80: 5, 500: 5}
	for wins: int in cases:
		t.check_eq(ProgressStore.band_for_wins(wins), int(cases[wins]), "%d승 → 대역 %d" % [wins, cases[wins]])
