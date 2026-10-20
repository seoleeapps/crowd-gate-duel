class_name TestInterstitial
extends RefCounted

class FakeAd extends InterstitialAdPort:
	var shows: int = 0
	var loads: int = 0
	var rejects: bool = false
	func preload_ad() -> void:
		loads += 1
	func show() -> bool:
		if rejects:
			return false
		shows += 1
		ready = false
		showing = true
		return true

static func run() -> TestBase:
	var t: TestBase = TestBase.new("interstitial")
	var now: Array[int] = [0]
	var port: FakeAd = FakeAd.new()
	var gate: InterstitialGate = InterstitialGate.new(port, func() -> int: return now[0])
	port.ready = true
	t.check(not gate.try_result("no-consent", false), "AC-L03 동의 전 표시 없음")
	port.can_request = true
	t.check(not gate.try_result("tutorial", true), "AC-L03 튜토리얼 표시 없음")
	t.check(gate.try_result("first", false), "AC-L03 첫 일반 대국부터 표시")
	t.check(not gate.try_result("first", false), "AC-L03 같은 판 중복 시도 없음")
	port.closed.emit()
	t.check_eq(port.loads, 1, "닫힘 이후 다음 광고 사전 준비")
	port.closed.emit()
	t.check_eq(port.loads, 1, "중복 닫힘 콜백 무시")
	port.ready = true
	now[0] = 44999
	t.check(not gate.try_result("early", false), "44,999ms는 간격 미달")
	now[0] = 45000
	t.check(gate.try_result("boundary", false), "45,000ms부터 허용")
	port.failed.emit()
	port.failed.emit()
	t.check_eq(port.loads, 2, "실패와 중복 콜백은 한 번만 닫힘 처리")
	now[0] = 90000
	port.ready = false
	t.check(not gate.try_result("late-load", false), "미준비는 기다리지 않는다")
	port.ready = true
	t.check(not gate.try_result("late-load", false), "늦은 로드는 같은 판에서 표시하지 않는다")
	port.failed.emit()
	port.ready = true
	t.check(gate.try_result("failure-next-round", false), "실제 표시 실패는 닫힘 간격을 새로 만들지 않는다")
	port.failed.emit()
	port.ready = true
	port.rejects = true
	t.check(not gate.try_result("show-rejected", false), "표시 거부 시 바로 진행")
	port.rejects = false
	t.check(gate.try_result("next", false), "다음 판은 준비된 광고 사용")
	t.check_eq(port.shows, 4, "실제로 시작한 광고 4회")
	# Android 경계의 요청 번호가 잘못된 콜백과 이전 광고의 닫힘을 격리한다.
	var android: AndroidInterstitialAdPort = AndroidInterstitialAdPort.new()
	android.can_request = true
	android._load_token = 2
	android._on_loaded(1)
	t.check(not android.ready, "오래된 로드 콜백 무시")
	android._on_loaded(2)
	t.check(android.ready, "현재 로드만 준비로 반영")
	android._on_consent(false, true)
	t.check(not android.ready and not android.can_request, "동의 변경은 준비 광고를 무효화")
	return t
