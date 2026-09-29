class_name Stage
extends Control
## 화면을 올려놓는 무대. 태블릿처럼 넓은 화면에서 폭을 9:16 까지로 제한하고 가운데 둔다.
## 좌우는 배경색으로 채워지고 게이트 칸은 확대되지 않는다(03 반응형 기기 매트릭스).

const MAX_WIDTH_PER_HEIGHT: float = 9.0 / 16.0


func _ready() -> void:
	clip_contents = true
	var parent: Control = get_parent() as Control
	if parent != null:
		parent.resized.connect(fit)
	fit()


func fit() -> void:
	var parent: Control = get_parent() as Control
	if parent == null:
		return
	var width: float = minf(parent.size.x, parent.size.y * MAX_WIDTH_PER_HEIGHT)
	size = Vector2(width, parent.size.y)
	position = Vector2((parent.size.x - width) / 2.0, 0)
