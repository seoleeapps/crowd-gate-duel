class_name ProgressStore
extends RefCounted
## 오프라인 진행 저장. 전적, 재화, 튜토리얼과 진행 중인 봇 대국을 보존한다.
##
## 저장은 `AtomicFileStore` 로 원자적으로 쓰고 손상 시 직전 스냅샷으로 복구한다(02 저장 계약).
## 이 클라이언트보다 새 버전으로 저장된 파일을 만나면 진행을 지우지 않고 읽기 전용으로 연다(06).

const SCHEMA_VERSION: int = 2
const DEFAULT_PATH: String = "user://progress.json"

## 오프라인 보상 표.
const FEATHERS_WIN: int = 10
const FEATHERS_LOSS: int = 3
const FEATHERS_DRAW: int = 5
const FEATHERS_DAILY_FIRST_WIN: int = 20
## 대역 n 을 여는 누적 승수. 대역은 내려가지 않는다(05 악용 경로).
const BAND_UNLOCK_WINS: Array[int] = [0, 3, 15, 40, 80]
const FEATHERS_ONBOARDING: int = 30

var path: String
var data: Dictionary = {}
var read_only: bool = false
## 마지막 read 가 어디서 읽었는지. "backup" 이면 손상을 복구한 것이다.
var loaded_from: String = "none"


func _init(path_in: String = DEFAULT_PATH) -> void:
	path = path_in
	data = defaults()


static func defaults() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"band": 1,
		"wins": 0,
		"losses": 0,
		"draws": 0,
		"feathers": 0,
		"daily_first_win_date": "",
		"onboarding_done": false,
		"tutorial_version": 0,
		"tutorial_step": 0,
		"gate_lessons": [],
		"unlocked": [],
		"equipped": {
			"flag": Cosmetics.DEFAULTS[Cosmetics.Slot.FLAG],
			"palette": Cosmetics.DEFAULTS[Cosmetics.Slot.PALETTE],
			"border": Cosmetics.DEFAULTS[Cosmetics.Slot.BORDER],
		},
		"settings": default_settings(),
		"in_progress": {},
	}


## 03 SCR-006 항목. locale 이 빈 문자열이면 기기 언어를 따른다.
static func default_settings() -> Dictionary:
	return {
		"commit_extended": false,
		"vibration": true,
		"sound": true,
		"music": true,
		"colorblind_assist": false,
		"reduce_shake": false,
		"locale": "",
	}


func read() -> void:
	var loaded: Dictionary = AtomicFileStore.read(path)
	read_only = false
	loaded_from = str(loaded["source"])
	var raw: Dictionary = loaded["data"]
	data = defaults()
	if raw.is_empty():
		return
	if int(raw.get("schema_version", 0)) > SCHEMA_VERSION:
		read_only = true
	# 없는 키는 기본값으로 채운다. 버전이 오르며 새 항목이 생겨도 기존 진행을 잃지 않는다.
	for key: String in raw:
		data[key] = raw[key]
	var settings: Dictionary = default_settings()
	settings.merge(raw.get("settings", {}), true)
	data["settings"] = settings
	for obsolete: String in ["pending_upload", "pending_clear", "ad_retry_date", "ad_retry_count"]:
		data.erase(obsolete)
	# 원격 기록 대국은 새 봇으로 바꾸어 이어도 같은 판이 되지 않는다.
	# 미완료 대국만 비우고 전적, 재화와 로컬 재생 규약은 보존한다.
	var pending_session: Dictionary = data["in_progress"].get("session", {})
	if str(pending_session.get("opponent", {}).get("kind", "")) == "record":
		data["in_progress"] = {}
	data["schema_version"] = SCHEMA_VERSION


func write() -> Error:
	if read_only:
		return ERR_UNAUTHORIZED
	return AtomicFileStore.write(path, data)


func band() -> int:
	return int(data["band"])


func feathers() -> int:
	return int(data["feathers"])


func wins() -> int:
	return int(data["wins"])


## 판 결과를 반영한다. today 는 "YYYY-MM-DD" 로 호출자가 주입한다.
## 반환: { "feathers": int, "daily_first_win": bool, "band_before": int, "band_after": int }
func apply_result(result: int, today: String) -> Dictionary:
	var gained: int = FEATHERS_DRAW
	var daily_first_win: bool = false
	var band_before: int = band()
	match result:
		DuelEngine.RESULT_A_WIN:
			gained = FEATHERS_WIN
			data["wins"] = wins() + 1
			if str(data["daily_first_win_date"]) != today:
				daily_first_win = true
				gained += FEATHERS_DAILY_FIRST_WIN
				data["daily_first_win_date"] = today
		DuelEngine.RESULT_B_WIN:
			gained = FEATHERS_LOSS
			data["losses"] = int(data["losses"]) + 1
		_:
			data["draws"] = int(data["draws"]) + 1
	data["feathers"] = feathers() + gained
	data["band"] = maxi(band_before, band_for_wins(wins()))
	var rewards: Array[String] = []
	for reward_band: int in Cosmetics.BAND_REWARDS:
		if band_before < reward_band and band() >= reward_band:
			var id: String = Cosmetics.BAND_REWARDS[reward_band]
			if grant(id):
				rewards.append(id)
	return {
		"feathers": gained,
		"daily_first_win": daily_first_win,
		"band_before": band_before,
		"band_after": band(),
		"items": rewards,
	}


func onboarding_done() -> bool:
	return int(data["tutorial_version"]) >= Onboarding.VERSION

func tutorial_step() -> int:
	return clampi(int(data["tutorial_step"]), 0, Onboarding.ANSWERS.size())

func set_tutorial_step(value: int) -> void:
	data["tutorial_step"] = clampi(value, 0, Onboarding.ANSWERS.size())

## onboarding_done은 구버전 완료 보상 지급 기록으로 남긴다.
func complete_onboarding() -> int:
	data["tutorial_version"] = Onboarding.VERSION
	data["tutorial_step"] = Onboarding.ANSWERS.size()
	if bool(data["onboarding_done"]):
		return 0
	data["onboarding_done"] = true
	data["feathers"] = feathers() + FEATHERS_ONBOARDING
	grant(Cosmetics.ONBOARDING_REWARD)
	return FEATHERS_ONBOARDING

func lesson_seen(kind: Gate.Kind) -> bool:
	return (data["gate_lessons"] as Array).has(Gate.kind_name(kind))

func mark_lesson(kind: Gate.Kind) -> void:
	if not lesson_seen(kind):
		(data["gate_lessons"] as Array).append(Gate.kind_name(kind))


func is_unlocked(id: String) -> bool:
	return Cosmetics.is_default(id) or (data["unlocked"] as Array).has(id)


## 보상으로 무료 해금. 이미 있으면 false.
func grant(id: String) -> bool:
	if is_unlocked(id):
		return false
	(data["unlocked"] as Array).append(id)
	return true


## 깃털로 해금. 깃털이 모자라거나 이미 있으면 false 이고 아무것도 바뀌지 않는다.
func purchase(id: String) -> bool:
	if is_unlocked(id) or feathers() < Cosmetics.price_of(id):
		return false
	data["feathers"] = feathers() - Cosmetics.price_of(id)
	(data["unlocked"] as Array).append(id)
	return true


func equip(id: String) -> bool:
	if not is_unlocked(id):
		return false
	data["equipped"][_slot_key(Cosmetics.slot_of(id))] = id
	return true


func equipped(slot: Cosmetics.Slot) -> String:
	return str(data["equipped"][_slot_key(slot)])


func setting(key: String) -> Variant:
	return data["settings"][key]


func set_setting(key: String, value: Variant) -> void:
	data["settings"][key] = value


## 진행 초기화(SCR-006). 설정은 남기고 진행·해금·보관 기록을 모두 지운다.
func reset_progress() -> void:
	var settings: Dictionary = data["settings"]
	data = defaults()
	data["settings"] = settings


static func _slot_key(slot: Cosmetics.Slot) -> String:
	match slot:
		Cosmetics.Slot.FLAG:
			return "flag"
		Cosmetics.Slot.PALETTE:
			return "palette"
	return "border"


static func band_for_wins(win_count: int) -> int:
	var unlocked: int = 1
	for i: int in range(BAND_UNLOCK_WINS.size()):
		if win_count >= BAND_UNLOCK_WINS[i]:
			unlocked = i + 1
	return unlocked


func set_in_progress(snapshot: Dictionary) -> void:
	data["in_progress"] = snapshot


func in_progress() -> Dictionary:
	return data["in_progress"]


