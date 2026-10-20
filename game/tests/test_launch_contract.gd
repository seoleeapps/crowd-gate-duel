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
	AtomicFileStore.write(path, legacy)
	var store: ProgressStore = ProgressStore.new(path)
	store.read()
	t.check(not store.onboarding_done(), "AC-L01 기존 자동 완료 기록도 다시 배운다")
	t.check_eq(store.wins(), 15, "AC-L01 기존 승수 보존")
	t.check_eq(store.feathers(), 120, "AC-L01 기존 재화 보존")
	t.check_eq(store.complete_onboarding(), 0, "AC-L01 기존 완료 보상 중복 지급 없음")
	AtomicFileStore.remove(path)
	var gates: Array[Gate] = [Gate.make(Gate.Kind.STEAL, 25), Gate.make(Gate.Kind.SHIELD, 10), Gate.make(Gate.Kind.ADD, 6)]
	var steal: Dictionary = GateLessons.example(gates, Gate.Kind.STEAL)
	t.check_eq(steal["percent"], 25, "첫 빼앗기 예시는 현재 25% 수치")
	t.check(str(steal["numbers"]).contains("40 → 30"), "빼앗긴 쪽 감소가 보인다")
	var shield: Dictionary = GateLessons.example(gates, Gate.Kind.SHIELD)
	t.check_eq(shield["percent"], 10, "방패 반격은 현재 10% 수치")
	t.check(str(shield["numbers"]).contains("40 → 36"), "방패 반격의 상대 감소")
	return t
