class_name ProgressStore
extends RefCounted
## 로컬 진행 저장. 대역·전적·깃털, 진행 중이던 판, 업로드를 기다리는 내 기록 1건을 담는다.
##
## 저장은 `AtomicFileStore` 로 원자적으로 쓰고 손상 시 직전 스냅샷으로 복구한다(02 저장 계약).
## 이 클라이언트보다 새 버전으로 저장된 파일을 만나면 진행을 지우지 않고 읽기 전용으로 연다(06).

const SCHEMA_VERSION: int = 1
const DEFAULT_PATH: String = "user://progress.json"

## 05 재화 표. 원격 설정으로 조정 가능한 값이지만 원격 설정은 아직 목 경계다.
const FEATHERS_WIN: int = 10
const FEATHERS_LOSS: int = 3
const FEATHERS_DRAW: int = 5
const FEATHERS_DAILY_FIRST_WIN: int = 20
## 대역 n 을 여는 누적 승수. 대역은 내려가지 않는다(05 악용 경로).
const BAND_UNLOCK_WINS: Array[int] = [0, 3, 15, 40, 80]

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
		"in_progress": {},
		"pending_upload": {},
	}


func read() -> void:
	var loaded: Dictionary = AtomicFileStore.read(path)
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
	return {
		"feathers": gained,
		"daily_first_win": daily_first_win,
		"band_before": band_before,
		"band_after": band(),
	}


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


## 업로드 대기 기록은 1건만 둔다. 원격 문서가 덮어쓰기라 가장 최근 기록만 의미가 있다.
func set_pending_upload(record: Dictionary) -> void:
	data["pending_upload"] = record


func pending_upload() -> Dictionary:
	return data["pending_upload"]
