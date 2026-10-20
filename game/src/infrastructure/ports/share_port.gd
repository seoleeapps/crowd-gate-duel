class_name SharePort
extends RefCounted
## Android에서는 파일 접근 권한을 제한한 FileProvider로 시스템 공유창을 연다.
## 개발 환경은 이미지를 로컬에 저장하며 네이티브 공유 성공으로 보고하지 않는다.

signal finished(success: bool)
const DIR: String = "user://share"
var directory: String = DIR
var _bridge: Object

func share_image(image: Image, file_name: String) -> String:
	if image == null or image.is_empty():
		return ""
	DirAccess.make_dir_recursive_absolute(directory)
	var path: String = "%s/%s.png" % [directory, file_name.get_file().validate_filename()]
	if image.save_png(path) != OK:
		return ""
	if OS.get_name() == "Android":
		if not Engine.has_singleton("CrowdGatePlatform"):
			return ""
		if _bridge == null:
			_bridge = Engine.get_singleton("CrowdGatePlatform")
			_bridge.connect("share_finished", _on_finished)
		_bridge.call("shareImage", ProjectSettings.globalize_path(path))
	else:
		finished.emit.call_deferred(true)
	return path

func _on_finished(success: bool) -> void:
	finished.emit(success)
