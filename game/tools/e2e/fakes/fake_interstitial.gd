extends InterstitialAdPort
## 실제 광고를 대신하는 개발 검수 경계. 결과 저장 순서와 콜백 중복을 관찰한다.
var tree: SceneTree
var store: ProgressStore
var shows: int = 0
var loads: int = 0
var privacy_opens: int = 0
var persisted_before_show: bool = false

func _init(tree_in: SceneTree, store_in: ProgressStore) -> void:
	tree = tree_in
	store = store_in
	can_request = true
	ready = true

func preload_ad() -> void:
	loads += 1
	ready = can_request

func show() -> bool:
	if not ready or not can_request:
		return false
	shows += 1
	ready = false
	showing = true
	var persisted: Dictionary = AtomicFileStore.read(store.path)["data"]
	persisted_before_show = (persisted.get("in_progress", {}) as Dictionary).is_empty() and (
		int(persisted.get("wins", 0)) + int(persisted.get("losses", 0)) + int(persisted.get("draws", 0)) > 0)
	tree.create_timer(0.25).timeout.connect(func() -> void:
		showing = false
		if shows == 1:
			failed.emit()
			failed.emit()
		else:
			closed.emit()
			closed.emit()
	)
	return true

func show_privacy_options() -> void:
	privacy_opens += 1
	consent_changed.emit()
