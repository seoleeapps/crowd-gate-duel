class_name TestLaunchContract
extends RefCounted

static func run() -> TestBase:
	var t: TestBase = TestBase.new("launch_contract")
	var idle: DuelSession = Onboarding.session()
	idle.present_next()
	t.check(idle.tick(1000000).is_empty(), "AC-L01 무입력은 자동 선택하지 않는다")
	t.check_eq(idle.picks_me.size(), 0, "AC-L01 시간 경과로 튜토리얼을 통과하지 못한다")
	var path: String = "user://test_launch_migration.json"
	var legacy: Dictionary = ProgressStore.defaults()
	legacy["onboarding_done"] = true
	legacy["wins"] = 15
	legacy["feathers"] = 120
	var course: Course = CourseValidator.generate_valid("legacy-record-resume", 1)["course"]
	var original: DuelSession = DuelSession.new(course, Opponent.bot(1), 3000)
	while original.present_next():
		original.commit(0)
	var previous: DuelSession = DuelSession.new(course, Opponent.from_record(original.to_record("Legacy", 0)), 3000)
	previous.present_next()
	legacy["in_progress"] = {"session": previous.to_dict()}
	t.check(DuelSession.from_dict(previous.to_dict()) != null, "구버전 기록 대국 fixture는 복원 가능")
	AtomicFileStore.write(path, legacy)
	var store: ProgressStore = ProgressStore.new(path)
	store.read()
	t.check(not store.onboarding_done(), "AC-L01 기존 자동 완료 기록도 다시 배운다")
	t.check_eq(store.wins(), 15, "AC-L01 기존 승수 보존")
	t.check_eq(store.feathers(), 120, "AC-L01 기존 재화 보존")
	t.check(store.in_progress().is_empty(), "AC-L02 구버전 기록 대국을 일반 상대에 복원하지 않는다")
	t.check_eq(store.complete_onboarding(), 0, "AC-L01 기존 완료 보상 중복 지급 없음")
	AtomicFileStore.remove(path)
	var gates: Array[Gate] = [Gate.make(Gate.Kind.STEAL, 25), Gate.make(Gate.Kind.SHIELD, 10), Gate.make(Gate.Kind.ADD, 6)]
	var steal: Dictionary = GateLessons.example(gates, Gate.Kind.STEAL)
	t.check_eq(steal["percent"], 25, "첫 빼앗기 예시는 현재 25% 수치")
	t.check(str(steal["numbers"]).contains("40 → 30"), "빼앗긴 쪽 감소가 보인다")
	var shield: Dictionary = GateLessons.example(gates, Gate.Kind.SHIELD)
	t.check_eq(shield["percent"], 10, "방패 반격은 현재 10% 수치")
	t.check(str(shield["numbers"]).contains("40 → 36"), "방패 반격의 상대 감소")
	var focus_app: Node = load("res://src/presentation/app.gd").new()
	var focus_before: bool = focus_app.in_foreground
	var focus_tracking_before: bool = focus_app.respect_platform_focus
	focus_app.respect_platform_focus = false
	focus_app.in_foreground = true
	focus_app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	t.check(focus_app.in_foreground, "개발 검수의 포커스 대체는 광고 상태에도 적용")
	focus_app.respect_platform_focus = true
	focus_app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	t.check(not focus_app.in_foreground, "실제 앱의 포커스 상실은 광고 표시를 막는다")
	focus_app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	t.check(focus_app.in_foreground, "실제 앱의 포커스 복귀 상태 반영")
	focus_app.respect_platform_focus = focus_tracking_before
	focus_app.in_foreground = focus_before
	focus_app.free()
	return t
