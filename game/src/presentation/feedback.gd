class_name Feedback
extends Node
## 소리·햅틱 피드백. 핵심 행동마다 여러 채널로 알린다(03 피드백과 게임 필, 04 오디오와 햅틱).
##
## 소리와 햅틱은 각각 끌 수 있고, 둘 다 꺼도 시각 연출만으로 모든 사건이 구분된다(A-4).
## 효과음은 scripts/make_sfx.py 가 절차 생성한 파일이고, 음악은 game-sound-pipeline 산출물이다.

const SFX: Dictionary = {
	"lock": preload("res://assets/audio/sfx/lock.wav"),
	"flip": preload("res://assets/audio/sfx/flip.wav"),
	"yield_pass": preload("res://assets/audio/sfx/yield_pass.wav"),
	"yield_block": preload("res://assets/audio/sfx/yield_block.wav"),
	"split": preload("res://assets/audio/sfx/split.wav"),
	"grow": preload("res://assets/audio/sfx/grow.wav"),
	"shrink": preload("res://assets/audio/sfx/shrink.wav"),
	"steal": preload("res://assets/audio/sfx/steal.wav"),
	"counter": preload("res://assets/audio/sfx/counter.wav"),
	"crash": preload("res://assets/audio/sfx/crash.wav"),
	"click": preload("res://assets/audio/sfx/click.wav"),
	"tick": preload("res://assets/audio/sfx/tick.wav"),
}
const VOICES: int = 6
## 대국 곡은 판 초반에 먹먹하게 시작해 구간이 쌓일수록 밝아진다. 긴장을 소리로 올린다.
const MUSIC_CUTOFF_LOW: float = 900.0
const MUSIC_CUTOFF_HIGH: float = 20000.0
const MUSIC_START_DELAY: float = 0.25
const MUSIC_FADE_SECONDS: float = 0.6
const MUSIC_FADE_FROM_DB: float = -24.0

var sound_on: bool = true
var music_on: bool = true
var vibration_on: bool = true

var _voices: Array[AudioStreamPlayer] = []
var _next_voice: int = 0
var _music: AudioStreamPlayer
var _stinger: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i: int in range(VOICES):
		var voice: AudioStreamPlayer = AudioStreamPlayer.new()
		voice.bus = &"SFX"
		add_child(voice)
		_voices.append(voice)
	_music = AudioStreamPlayer.new()
	_music.bus = &"Music"
	add_child(_music)
	_stinger = AudioStreamPlayer.new()
	_stinger.bus = &"SFX"
	add_child(_stinger)


func apply_settings(settings: Dictionary) -> void:
	sound_on = bool(settings.get("sound", true))
	music_on = bool(settings.get("music", true))
	vibration_on = bool(settings.get("vibration", true))
	if not music_on:
		_music.stop()


## pitch 로 같은 효과음의 크기감을 바꾼다. 증가량이 클수록 높고 빠르다.
func play(sound: String, pitch: float = 1.0) -> void:
	if not sound_on or not SFX.has(sound):
		return
	var voice: AudioStreamPlayer = _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	voice.stream = SFX[sound]
	voice.pitch_scale = pitch
	voice.play()


func play_stinger(stream: AudioStream) -> void:
	if sound_on and stream != null:
		_stinger.stream = stream
		_stinger.play()


## strength 0~1. 모바일 기기에서만 울린다.
func vibrate(duration_ms: int, strength: float) -> void:
	if vibration_on and OS.has_feature("mobile"):
		Input.vibrate_handheld(duration_ms, strength)


## 화면이 바뀌고 잠시 뒤 작게 시작해 서서히 커진다. 갑자기 터지는 시작을 피하고,
## 화면을 만드는 프레임에 음악 디코딩이 겹치지 않게 한다.
## (첫 프레임에 재생을 시작한 채 그 프레임에 종료하면 엔진이 재생 객체를 놓지 못해
## 컴파일 게이트의 1프레임 실행에서 자원 누수로 잡힌 적이 있다.)
func play_music(stream: AudioStream) -> void:
	if not music_on or stream == null:
		_music.stop()
		return
	if _music.stream == stream and _music.playing:
		return
	_music.stop()
	_music.stream = stream
	await get_tree().create_timer(MUSIC_START_DELAY).timeout
	if _music.stream != stream or not music_on:
		return
	_music.volume_db = MUSIC_FADE_FROM_DB
	_music.play()
	create_tween().tween_property(_music, "volume_db", 0.0, MUSIC_FADE_SECONDS)
	set_intensity(1.0)


func stop_music() -> void:
	_music.stop()
	_music.stream = null


## 모든 소리를 멈춘다. 재생 객체는 오디오 스레드가 한 번 돈 뒤에 풀리므로,
## 곧바로 종료하는 검사 도구는 이 호출 뒤 잠시 기다린다.
func stop_all() -> void:
	for player: AudioStreamPlayer in _voices + [_music, _stinger]:
		player.stop()
		player.stream = null


## 0~1. 대국 진행도에 맞춰 음악의 밝기를 올린다.
func set_intensity(value: float) -> void:
	var bus: int = AudioServer.get_bus_index(&"Music")
	if bus < 0 or AudioServer.get_bus_effect_count(bus) == 0:
		return
	var filter: AudioEffectLowPassFilter = AudioServer.get_bus_effect(bus, 0) as AudioEffectLowPassFilter
	if filter != null:
		filter.cutoff_hz = lerpf(MUSIC_CUTOFF_LOW, MUSIC_CUTOFF_HIGH, pow(clampf(value, 0.0, 1.0), 2.0))
