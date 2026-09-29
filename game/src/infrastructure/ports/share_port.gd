class_name SharePort
extends RefCounted
## 결과 카드 공유 포트.
##
## 이 기본 구현은 목이다. 카드 이미지를 사용자 폴더에 저장하고 경로를 돌려준다.
## 마켓별 공유 시트 연결 시 상속해 `share_image` 를 바꾼다.

const DIR: String = "user://share"


## 반환: 저장한 파일 경로. 실패하면 빈 문자열.
func share_image(image: Image, file_name: String) -> String:
	DirAccess.make_dir_recursive_absolute(DIR)
	var path: String = "%s/%s.png" % [DIR, file_name]
	return path if image.save_png(path) == OK else ""
