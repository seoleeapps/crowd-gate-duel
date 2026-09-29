extends Node
## 앱 전역 서비스. 자동 로드 이름은 `App` 이다.
##
## 포트의 실제 구현(Firebase·광고·공유)은 아직 목 경계다. 여기서 한 번만 조립하고
## 화면은 이 노드를 통해서만 저장소·포트에 닿는다.

var progress: ProgressStore
var remote: RemoteRecordPort
var resolver: OpponentResolver
var record_sync: RecordSync
var analytics: AnalyticsPort
var ads: RewardedAdPort
var share: SharePort
var feedback: Feedback
## 이번 실행에서 끝낸 판 수. 하루 여러 번 여는지 보는 지표(06 duel_finish)에 쓴다.
var session_duel_count: int = 0


func _ready() -> void:
	progress = ProgressStore.new(_progress_path())
	progress.read()
	remote = LocalRemoteRecordPort.new()
	resolver = OpponentResolver.new(remote)
	record_sync = RecordSync.new(remote, progress)
	analytics = AnalyticsPort.new()
	ads = RewardedAdPort.new()
	share = SharePort.new()
	feedback = Feedback.new()
	add_child(feedback)
	apply_settings()
	record_sync.flush()


## 설정을 소리·햅틱과 언어에 반영한다. 언어가 빈 값이면 기기 언어를 따른다.
func apply_settings() -> void:
	feedback.apply_settings(progress.data["settings"])
	var locale: String = str(progress.setting("locale"))
	TranslationServer.set_locale(locale if not locale.is_empty() else OS.get_locale_language())


func commit_extended() -> bool:
	return bool(progress.setting("commit_extended"))


func today() -> String:
	return Time.get_date_string_from_system()


func now_unix() -> int:
	return int(Time.get_unix_time_from_system())


## 확약 시간 연장(DEC-008)을 켜면 대역 기본값의 1.5배다.
func commit_ms(band: int) -> int:
	var base: int = int(CourseGenerator.band_config(band)["commit_ms"])
	return base * 3 / 2 if commit_extended() else base


## 봇 대국 코스의 시드. 판마다 달라야 하므로 시각을 쓴다. 재현은 기록에 남는 코스 시드가 담당한다.
func fallback_seed(band: int) -> String:
	return "%d|%d" % [Time.get_unix_time_from_system() * 1000.0, band]


## QA 도구가 실제 사용자 저장을 건드리지 않도록 저장 경로를 바꿀 수 있다.
##   godot ... -- --progress-path user://smoke/progress.json
static func _progress_path() -> String:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var index: int = args.find("--progress-path")
	if index >= 0 and index + 1 < args.size():
		return args[index + 1]
	return ProgressStore.DEFAULT_PATH
