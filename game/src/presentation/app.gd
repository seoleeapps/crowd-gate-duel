extends Node
## 앱 서비스 조립. 게임은 로컬 봇으로 완결하고 Android 경계만 실제 SDK를 사용한다.

var progress: ProgressStore
var ads: InterstitialAdPort
var ad_breaks: InterstitialGate
var share: SharePort
var pause_on_focus_loss: bool = true
var seed_clock: Callable = Time.get_ticks_usec
var in_foreground: bool = true
var feedback: Feedback

func _ready() -> void:
	progress = ProgressStore.new(_progress_path())
	progress.read()
	ads = AndroidInterstitialAdPort.new() if OS.get_name() == "Android" else InterstitialAdPort.new()
	ad_breaks = InterstitialGate.new(ads,
		func() -> int: return int(Time.get_unix_time_from_system() * 1000.0),
		_progress_path() + ".ad-cooldown.json")
	share = SharePort.new()
	feedback = Feedback.new()
	add_child(feedback)
	apply_settings()
	ads.initialize()

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

func commit_ms(band: int) -> int:
	var base: int = int(CourseGenerator.band_config(band)["commit_ms"])
	return base * 3 / 2 if commit_extended() else base

func fallback_seed(band: int) -> String:
	return "%d|%d" % [int(seed_clock.call()), band]

static func _progress_path() -> String:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var index: int = args.find("--progress-path")
	if index >= 0 and index + 1 < args.size():
		return args[index + 1]
	return ProgressStore.DEFAULT_PATH

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		in_foreground = false
	elif what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_APPLICATION_FOCUS_IN:
		in_foreground = true
