class_name InterstitialAdPort
extends RefCounted
## 개발 환경의 광고 경계. 광고를 준비하거나 실제 표시했다고 보고하지 않는다.

signal loaded
signal closed
signal failed
signal consent_changed

var ready: bool = false
var showing: bool = false
var can_request: bool = false
var privacy_required: bool = false

func initialize() -> void:
	pass

func preload_ad() -> void:
	pass

func show() -> bool:
	return false

func show_privacy_options() -> void:
	pass
