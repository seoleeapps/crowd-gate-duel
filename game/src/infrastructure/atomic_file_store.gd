class_name AtomicFileStore
extends RefCounted
## 원자적 JSON 저장. 쓰는 도중 앱이 죽어도 저장 파일이 반쯤 쓰인 상태로 남지 않는다.
##
## 순서는 다음과 같다.
##   1. 임시 파일에 쓰고 다시 읽어 검사한다
##   2. 지금 파일이 정상이면 직전 스냅샷(.bak)으로 복사해 둔다
##   3. 임시 파일을 본 파일 이름으로 바꾼다
## 본 파일에는 내용의 SHA-256 을 함께 담는다. 불러올 때 맞지 않으면 손상으로 보고 스냅샷을 쓴다.
##
## JSON 이라 불러온 숫자는 float 이 된다. 호출자는 정수 값을 int() 로 되돌려 쓴다.

const TMP_SUFFIX: String = ".tmp"
const BACKUP_SUFFIX: String = ".bak"


## 반환: OK 또는 실패한 단계의 Error
static func write(path: String, data: Dictionary) -> Error:
	var tmp_path: String = path + TMP_SUFFIX
	var file: FileAccess = FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(_encode(data))
	file.close()

	if _read_valid(tmp_path) == null:
		return ERR_FILE_CORRUPT
	if _read_valid(path) != null:
		var copy_error: Error = DirAccess.copy_absolute(path, path + BACKUP_SUFFIX)
		if copy_error != OK:
			return copy_error
	return DirAccess.rename_absolute(tmp_path, path)


## 반환: { "data": Dictionary, "source": "main" | "backup" | "none" }
## 본 파일이 손상됐으면 직전 스냅샷을, 둘 다 없으면 빈 사전을 돌려준다.
static func read(path: String) -> Dictionary:
	var main: Variant = _read_valid(path)
	if main != null:
		return {"data": main, "source": "main"}
	var backup: Variant = _read_valid(path + BACKUP_SUFFIX)
	if backup != null:
		return {"data": backup, "source": "backup"}
	return {"data": {}, "source": "none"}


static func remove(path: String) -> void:
	for suffix: String in ["", TMP_SUFFIX, BACKUP_SUFFIX]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)


static func _encode(data: Dictionary) -> String:
	var body: String = JSON.stringify(data, "", true)
	return JSON.stringify({"sha256": body.sha256_text(), "body": body})


## 정상이면 Dictionary, 없거나 손상됐으면 null.
static func _read_valid(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var envelope: Variant = _parse(FileAccess.get_file_as_string(path))
	if typeof(envelope) != TYPE_DICTIONARY:
		return null
	var body: String = str(envelope.get("body", ""))
	if body.sha256_text() != str(envelope.get("sha256", "")):
		return null
	var data: Variant = _parse(body)
	if typeof(data) != TYPE_DICTIONARY:
		return null
	return data


## JSON.parse_string 은 실패 시 엔진 오류를 로그에 남긴다. 손상 파일은 예상된 입력이므로
## 오류 코드만 받는 JSON.parse 를 쓴다.
static func _parse(text: String) -> Variant:
	var json: JSON = JSON.new()
	if json.parse(text) != OK:
		return null
	return json.data
