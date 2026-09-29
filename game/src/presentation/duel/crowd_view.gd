class_name CrowdView
extends Node2D
## 한 진영의 무리. 인형 한 종을 군중 수만큼 반복해 그린다(04 시각 문법).
##
## 개체 시뮬레이션이 아니라 수치 하나를 인스턴싱으로 보여 줄 뿐이다. 수가 많아지면 인형을 줄이고
## 촘촘하게 세우며, 200명을 넘으면 뒤쪽을 실루엣 덩어리 하나로 합친다.
## 노드의 원점이 무리 중심이고, `road_dir` 은 길이 오르는 방향이다.

enum Badge { NONE, BOT, PRACTICE }

const DOLL_TEXTURE: Texture2D = preload("res://assets/art/doll.svg")
## 시안의 인형 단위(20 x 28)와 기본 배율 0.62.
const DOLL_W_UNITS: float = 20.0
const DOLL_H_UNITS: float = 28.0
const BASE_SCALE: float = 0.62
const VISIBLE_CAP: int = 200
const GAP_ALONG_DP: float = 11.0
const GAP_ACROSS_DP: float = 10.5

var mine: bool = true
var badge: Badge = Badge.NONE
var count: int = 12
var road_dir: Vector2 = Vector2(1, -1).normalized()
## 홈 대기 장면처럼 제자리에서 흔들린다.
var idle_sway: bool = false

var _multimesh: MultiMesh
var _mesh_instance: MultiMeshInstance2D
## 깃발은 인형 위에 그려야 하므로 인형 뒤에 붙인 별도 층에 그린다.
var _flag_layer: Node2D
var _points: Array[Vector2] = []
var _tilts: Array[float] = []
var _scale: float = BASE_SCALE
var _time: float = 0.0


func _ready() -> void:
	_mesh_instance = MultiMeshInstance2D.new()
	_mesh_instance.texture = DOLL_TEXTURE
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_2D
	_multimesh.use_colors = true
	_multimesh.mesh = _quad_mesh()
	_mesh_instance.multimesh = _multimesh
	add_child(_mesh_instance)
	_flag_layer = Node2D.new()
	_flag_layer.draw.connect(_draw_flags)
	add_child(_flag_layer)
	_rebuild()


func _process(delta: float) -> void:
	if idle_sway:
		_time += delta
		_write_instances()


func set_count(value: int) -> void:
	count = maxi(1, value)
	if is_node_ready():
		_rebuild()


## 무리의 가장 윗부분(깃발 포함)까지의 높이. 수치 표식을 이 위에 붙인다.
func top_offset() -> float:
	var top: float = 0.0
	for p: Vector2 in _points:
		top = minf(top, p.y)
	return top - (DOLL_H_UNITS * _scale + 34.0) * Palette.DP


func flag_color() -> Color:
	return Palette.BOT if badge == Badge.BOT else Palette.side_color(mine)


func _rebuild() -> void:
	var visible: int = mini(count, VISIBLE_CAP)
	# 수가 많아질수록 인형을 줄이고 폭을 넓힌다. 장면의 밀도로 크기를 전달한다.
	_scale = BASE_SCALE * clampf(sqrt(60.0 / float(maxi(count, 1))), 0.62, 1.0)
	var across: int = clampi(ceili(sqrt(float(visible) / 3.0)), 4, 9)
	var along: int = ceili(float(visible) / float(across))
	var unit_along: Vector2 = road_dir
	var unit_across: Vector2 = Vector2(-road_dir.y, road_dir.x)
	var density: float = _scale / BASE_SCALE
	# 흩어짐은 인형 번호에서 결정론적으로 나온다. 같은 수면 매번 같은 모습이다.
	var rng: Pcg32 = Pcg32.seeded(0x5A11 if mine else 0x0DD5, 7)
	_points.clear()
	_tilts.clear()
	for i: int in range(visible):
		var a: int = i / across
		var k: int = i % across
		var u: float = (float(a) - float(along - 1) / 2.0) * GAP_ALONG_DP * density
		var v: float = (float(k) - float(across - 1) / 2.0) * GAP_ACROSS_DP * density
		u += (float(rng.next_below(1000)) / 1000.0 - 0.5) * 7.0 * density
		v += (float(rng.next_below(1000)) / 1000.0 - 0.5) * 6.0 * density
		_points.append((unit_along * u + unit_across * v) * Palette.DP)
		_tilts.append(deg_to_rad(float(rng.next_below(11)) - 5.0))
	# 뒷줄(화면 위쪽)부터 그려 앞줄이 겹쳐 보이게 한다.
	var order: Array[int] = []
	for i: int in range(_points.size()):
		order.append(i)
	order.sort_custom(func(x: int, y: int) -> bool: return _points[x].y < _points[y].y)
	var sorted_points: Array[Vector2] = []
	var sorted_tilts: Array[float] = []
	for i: int in order:
		sorted_points.append(_points[i])
		sorted_tilts.append(_tilts[i])
	_points = sorted_points
	_tilts = sorted_tilts
	_multimesh.instance_count = _points.size()
	_write_instances()
	queue_redraw()
	_flag_layer.queue_redraw()


func _write_instances() -> void:
	var color: Color = Palette.side_color(mine)
	for i: int in range(_points.size()):
		var sway: float = 0.0
		if idle_sway:
			sway = sin(_time * 2.4 + float(i) * 0.7) * 0.08
		var xform: Transform2D = Transform2D(_tilts[i] + sway, Vector2(_scale, _scale), 0.0, _points[i])
		_multimesh.set_instance_transform_2d(i, xform)
		_multimesh.set_instance_color(i, color)


## 발끝이 원점에 오는 사각형. 인형은 발 기준으로 서고 발 기준으로 기운다.
func _quad_mesh() -> ArrayMesh:
	var w: float = DOLL_W_UNITS * Palette.DP * (24.0 / 20.0)
	var h: float = DOLL_H_UNITS * Palette.DP * (32.0 / 28.0)
	var foot: float = h * (28.5 / 32.0)
	var verts: PackedVector2Array = PackedVector2Array([
		Vector2(-w / 2.0, -foot), Vector2(w / 2.0, -foot),
		Vector2(w / 2.0, h - foot), Vector2(-w / 2.0, h - foot),
	])
	var uvs: PackedVector2Array = PackedVector2Array([
		Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1),
	])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3])
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _draw() -> void:
	if count > VISIBLE_CAP:
		_draw_mass()


## 200명을 넘는 부분은 무리 뒤쪽의 실루엣 덩어리로 보여 준다. 넘는 수만큼 덩어리가 길어진다.
func _draw_mass() -> void:
	var extra: float = clampf(float(count - VISIBLE_CAP) / float(VISIBLE_CAP), 0.1, 1.5)
	var center: Vector2 = -road_dir * 30.0 * Palette.DP
	var half_len: float = (26.0 + 30.0 * extra) * Palette.DP
	var half_wid: float = 22.0 * Palette.DP
	var points: PackedVector2Array = PackedVector2Array()
	var across: Vector2 = Vector2(-road_dir.y, road_dir.x)
	for i: int in range(24):
		var a: float = TAU * float(i) / 24.0
		points.append(center + road_dir * cos(a) * half_len + across * sin(a) * half_wid - Vector2(0, 8 * Palette.DP))
	draw_colored_polygon(points, Palette.side_color(mine).darkened(0.25))
	points.append(points[0])
	draw_polyline(points, Palette.DOLL_LINE, 1.0 * Palette.DP, true)


func _draw_flags() -> void:
	if _points.is_empty():
		return
	var by_x: Array[Vector2] = _points.duplicate()
	by_x.sort_custom(func(p: Vector2, q: Vector2) -> bool: return p.x < q.x)
	var bearers: int = 1 if count < 8 else 2
	for i: int in range(bearers):
		var p: Vector2 = by_x[roundi(float(i + 1) * float(by_x.size() - 1) / float(bearers + 1))]
		_draw_flag(p + Vector2(5.0 * _scale, -16.0 * _scale) * Palette.DP)


## 막대 끝에서 위로 올린 깃발. 무늬는 기하 도형이다. 나는 꺾쇠, 상대는 원, 봇은 무채색 막대 둘.
func _draw_flag(base: Vector2) -> void:
	var dp: float = Palette.DP
	var top: Vector2 = base - Vector2(0, 30 * dp)
	var w: float = 20 * dp
	var fh: float = 13 * dp
	_flag_layer.draw_line(base, top, Palette.POLE, 1.6 * dp, true)
	var cloth: PackedVector2Array = PackedVector2Array([
		top, top + Vector2(w, 0), top + Vector2(w - 3.5 * dp, fh / 2.0), top + Vector2(w, fh), top + Vector2(0, fh),
	])
	_flag_layer.draw_colored_polygon(cloth, flag_color())
	var mark: Color = Palette.BOT_MARK if badge == Badge.BOT else Palette.FLAG_MARK
	if badge == Badge.BOT:
		for x: float in [6.0, 12.0]:
			_flag_layer.draw_line(top + Vector2(x * dp, 2 * dp), top + Vector2(x * dp, fh - 2 * dp), mark, 2.2 * dp)
	elif mine:
		var chevron: PackedVector2Array = PackedVector2Array([
			top + Vector2(3 * dp, 2.5 * dp), top + Vector2(10 * dp, fh / 2.0), top + Vector2(3 * dp, fh - 2.5 * dp),
		])
		_flag_layer.draw_polyline(chevron, mark, 2.4 * dp, true)
	else:
		_flag_layer.draw_circle(top + Vector2(w / 2.0, fh / 2.0), 3.4 * dp, mark, true, -1.0, true)
