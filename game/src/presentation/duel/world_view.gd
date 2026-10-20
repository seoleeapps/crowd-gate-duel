class_name WorldView
extends Control
## 대국 화면의 세계: 하늘, 언덕 3겹, 하나의 언덕길, 정상 결승선, 두 무리.
## A-0 에서 고른 B안 "하나의 언덕길"을 구현한다. **순위는 길 위의 높이로 읽는다.**
##
## 좌표는 시안(360 x 561.6 dp)을 이 컨트롤 크기에 맞춰 늘린 것이다. 가로는 폭에, 세로는 높이에 맞춘다.
## 무리의 높이는 두 군중 수의 로그 비로 정한다. 군중은 지수적으로 커지므로 선형으로 두면
## 격차가 조금만 벌어져도 한쪽이 화면 밖으로 밀린다.

signal layout_changed

const W: float = 360.0
const H: float = 561.6
const ROAD_POINTS: Array[Vector2] = [Vector2(300, 640), Vector2(74, 440), Vector2(288, 268), Vector2(180, 152)]
const ROAD_WIDTH: float = 70.0
const HILL_Y: Array[float] = [150.0, 250.0, 380.0]
## 로그 비 1 당 벌어지는 길 비율(한쪽). 44:31 이면 약 0.18 씩 벌어진다.
const SPREAD_PER_LOG: float = 0.5
const MIN_HALF_GAP: float = 0.04
const MAX_HALF_GAP: float = 0.3
## 높이가 같거나 가까울 때 두 무리를 좌우로 벌리는 거리. 같은 높이를 지키려고 수평으로 벌린다.
const LATERAL_DP: float = 40.0

var bottom_clearance: float = 0.0
var top_clearance: float = 8 * Palette.DP
var me_view: CrowdView
var opp_view: CrowdView
var me_chip: CountChip
var opp_chip: CountChip
var tie_chip: CountChip

var _road_edge: Line2D
var _road_fill: Line2D
var _decor: Node2D
var _fx: Node2D
## 현재 배치: x = 내 위치, y = 상대 위치(길 비율 0~1), z = 좌우 벌림(0~1)
var _placement: Vector3 = Vector3(0.28, 0.28, 1.0)
var _me_count: int = 12
var _opp_count: int = 12
var _show_opp: bool = true


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_road_edge = _line(Palette.ROAD_EDGE)
	_road_fill = _line(Palette.ROAD)
	_decor = Node2D.new()
	_decor.draw.connect(_draw_decor)
	add_child(_decor)
	opp_view = CrowdView.new()
	opp_view.mine = false
	opp_view.body_color = Palette.OPP
	opp_view.flag_pattern = "dot"
	add_child(opp_view)
	me_view = CrowdView.new()
	add_child(me_view)
	opp_chip = CountChip.new(CountChip.Kind.OPP)
	me_chip = CountChip.new(CountChip.Kind.MINE)
	tie_chip = CountChip.new(CountChip.Kind.TIE)
	for chip: CountChip in [opp_chip, me_chip, tie_chip]:
		add_child(chip)
		chip.minimum_size_changed.connect(_apply.call_deferred)
	_fx = Node2D.new()
	add_child(_fx)
	resized.connect(_relayout)
	_relayout()


## 홈 화면처럼 내 무리만 세워 둔다.
func show_only_mine(count: int) -> void:
	_show_opp = false
	opp_view.visible = false
	opp_chip.visible = false
	me_view.idle_sway = true
	set_standing(count, count, 0.0, false)


## 꾸미기: 내 무리의 팔레트와 깃발 무늬.
func set_my_style(color: Color, pattern: String) -> void:
	me_view.body_color = color
	me_view.flag_pattern = pattern
	me_view.set_count(me_view.count)


func set_opponent_badge(badge: CrowdView.Badge) -> void:
	opp_view.badge = badge
	opp_view.queue_redraw()
	opp_chip.set_badge(badge)


## 두 군중 수와 판 진행도(0~1)로 무리를 세운다. animate 면 수와 위치가 부드럽게 바뀐다.
func set_standing(me: int, opp: int, progress: float, animate: bool, duration: float = 0.7) -> Tween:
	var target: Vector3 = placement_for(me, opp, progress)
	if not animate:
		_placement = target
		_set_counts(me, opp)
		_apply()
		return null
	var tween: Tween = create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_placement, _placement, target, duration)
	tween.tween_method(_set_counts_lerp.bind(_me_count, _opp_count, me, opp), 0.0, 1.0, duration * 0.8)
	return tween


## 길 비율 위치. 앞선 쪽이 위(정상 쪽)에 선다. 동수면 같은 높이에 좌우로 선다.
static func placement_for(me: int, opp: int, progress: float) -> Vector3:
	var center: float = 0.28 + 0.3 * clampf(progress, 0.0, 1.0)
	if me == opp:
		return Vector3(center, center, 1.0)
	var gap: float = log(float(me) / float(opp))
	var half: float = clampf(absf(gap) * SPREAD_PER_LOG, MIN_HALF_GAP, MAX_HALF_GAP)
	var me_u: float = center + signf(gap) * half
	var opp_u: float = center - signf(gap) * half
	# 한쪽이 길 끝에 닿으면 둘 다 옮겨 간격을 지킨다.
	# 위쪽 한계는 앞선 무리의 수치 표식이 결승선 깃발과 겹치지 않는 높이다.
	var shift: float = maxf(0.0, maxf(me_u, opp_u) - 0.86) - maxf(0.0, 0.06 - minf(me_u, opp_u))
	me_u -= shift
	opp_u -= shift
	# 높이가 가까우면 수평으로 벌려 두 무리가 겹치지 않게 한다. 동수면 정확히 같은 높이에 나란히 선다.
	var lateral: float = clampf(1.0 - absf(me_u - opp_u) / 0.14, 0.0, 1.0)
	return Vector3(me_u, opp_u, lateral)


## 결승 충돌: 두 무리가 정상으로 올라가 가운데서 부딪힌다.
func play_finale(me: int, opp: int) -> Tween:
	var tween: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_method(_set_placement, _placement, Vector3(0.8, 0.8, 1.5), 1.1)
	tween.tween_method(_set_placement, Vector3(0.8, 0.8, 1.5), Vector3(0.8, 0.8, 0.55), 0.3)
	tween.tween_callback(func() -> void:
		var loser: CrowdView = null
		if me < opp:
			loser = me_view
		elif opp < me:
			loser = opp_view
		if loser != null:
			# 지는 쪽은 넘어질 뿐 다치지 않는다(04 아트 방향).
			create_tween().tween_property(loser, "rotation", deg_to_rad(-8.0), 0.25)
	)
	return tween


func me_anchor() -> Vector2:
	return me_view.position


func opp_anchor() -> Vector2:
	return opp_view.position


## 증가: 무리 위로 인형이 튀어나온다. 증가량이 클수록 많이, 빠르게.
## 입자는 무리에 붙여 무리가 새 높이로 옮겨 가도 함께 따라가게 한다.
func burst(mine: bool, amount: int) -> void:
	var particles: CPUParticles2D = _doll_particles(mine, clampi(amount, 6, 48))
	particles.position = Vector2(0, -20 * Palette.DP)
	particles.direction = Vector2.UP
	particles.spread = 55.0
	particles.initial_velocity_min = 120.0 * Palette.DP
	particles.initial_velocity_max = (160.0 + float(mini(amount, 200))) * Palette.DP
	particles.gravity = Vector2(0, 520 * Palette.DP)
	_fire(particles, me_view if mine else opp_view)


## 감소: 개체가 흐려지며 아래로 가라앉는다.
func sink(mine: bool, amount: int) -> void:
	var particles: CPUParticles2D = _doll_particles(mine, clampi(amount, 4, 30))
	particles.direction = Vector2.DOWN
	particles.spread = 30.0
	particles.initial_velocity_min = 20.0 * Palette.DP
	particles.initial_velocity_max = 60.0 * Palette.DP
	particles.gravity = Vector2(0, 60 * Palette.DP)
	particles.color = _body(mine).lerp(Palette.BG, 0.4)
	_fire(particles, me_view if mine else opp_view)


## 빼앗김: 빼앗긴 쪽의 인형이 궤적을 그리며 가져간 쪽으로 끌려간다. 방향이 궤적으로 보인다.
func transfer(to_mine: bool, amount: int) -> Tween:
	var from: Vector2 = opp_anchor() if to_mine else me_anchor()
	var to: Vector2 = me_anchor() if to_mine else opp_anchor()
	var tween: Tween = create_tween().set_parallel()
	for i: int in range(clampi(amount, 1, 12)):
		var doll: Sprite2D = _flying_doll(not to_mine)
		doll.position = from
		var lift: Vector2 = Vector2(0, -(60.0 + 8.0 * float(i)) * Palette.DP)
		tween.tween_method(
			func(t: float) -> void: doll.position = from.lerp(to, t) + lift * sin(PI * t),
			0.0, 1.0, 0.6
		).set_delay(0.04 * float(i))
		tween.tween_property(doll, "modulate", _body(to_mine), 0.6).set_delay(0.04 * float(i))
	tween.chain().tween_callback(_clear_fx_sprites)
	return tween


## 방패 반격: 빼앗기 갈고리가 방패에 맞고 튕겨 되돌아간다.
func counter(attacker_mine: bool) -> Tween:
	var from: Vector2 = me_anchor() if attacker_mine else opp_anchor()
	var to: Vector2 = opp_anchor() if attacker_mine else me_anchor()
	var hook: Sprite2D = Sprite2D.new()
	hook.texture = preload("res://assets/art/gate_steal.svg")
	hook.scale = Vector2.ONE * 0.45
	hook.position = from
	_fx.add_child(hook)
	var tween: Tween = create_tween()
	tween.tween_property(hook, "position", from.lerp(to, 0.8), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(hook, "rotation", PI, 0.12)
	tween.tween_property(hook, "position", from, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(hook.queue_free)
	return tween


## 막힘: 앞서 있던 쪽이 같은 칸에서 제자리에 멈칫한다.
func block(mine: bool) -> Tween:
	var view: CrowdView = me_view if mine else opp_view
	var base: Vector2 = view.position
	var tween: Tween = create_tween()
	for i: int in range(3):
		tween.tween_property(view, "position", base + view.road_dir * 6 * Palette.DP, 0.06)
		tween.tween_property(view, "position", base - view.road_dir * 3 * Palette.DP, 0.06)
	tween.tween_property(view, "position", base, 0.06)
	return tween


func _relayout() -> void:
	var points: PackedVector2Array = _road_points()
	_road_edge.points = points
	_road_fill.points = points
	_road_edge.width = (ROAD_WIDTH + 5.0) * Palette.DP
	_road_fill.width = ROAD_WIDTH * Palette.DP
	_apply()
	queue_redraw()
	_decor.queue_redraw()


func _set_placement(value: Vector3) -> void:
	_placement = value
	_apply()


func _set_counts(me: int, opp: int) -> void:
	_me_count = me
	_opp_count = opp
	me_view.set_count(me)
	opp_view.set_count(opp)
	me_chip.set_value(me)
	opp_chip.set_value(opp)


func _set_counts_lerp(t: float, me_from: int, opp_from: int, me_to: int, opp_to: int) -> void:
	_set_counts(roundi(lerpf(me_from, me_to, t)), roundi(lerpf(opp_from, opp_to, t)))
	_apply()


func _apply() -> void:
	if not is_node_ready() or size.x <= 0.0:
		return
	var lateral: float = _placement.z * LATERAL_DP * Palette.DP
	_place(me_view, _placement.x, -lateral if _show_opp else 0.0)
	_place(opp_view, _placement.y, lateral)
	# 아래쪽(가까운) 무리를 앞에 그린다.
	var front: CrowdView = me_view if me_view.position.y >= opp_view.position.y else opp_view
	var back: CrowdView = opp_view if front == me_view else me_view
	if front.get_index() < back.get_index():
		move_child(front, back.get_index())
	var tie: bool = _show_opp and _me_count == _opp_count
	tie_chip.visible = tie and is_zero_approx(bottom_clearance)
	var me_top: Vector2 = me_view.position + Vector2(0, me_view.top_offset())
	var opp_top: Vector2 = opp_view.position + Vector2(0, opp_view.top_offset())
	me_chip.place_above(me_top)
	opp_chip.place_above(opp_top)
	_clamp_chip(me_chip)
	_clamp_chip(opp_chip)
	if _show_opp and me_chip.get_rect().grow(4 * Palette.DP).intersects(opp_chip.get_rect()):
		# 가까운 두 무리의 표식은 읽는 순서대로 나란히 놓는다.
		var gap: float = 8 * Palette.DP
		var total: float = me_chip.size.x + opp_chip.size.x + gap
		var left: float = clampf((me_chip.position.x + opp_chip.position.x - gap) / 2.0, 8 * Palette.DP, size.x - total - 8 * Palette.DP)
		me_chip.position.x = left
		opp_chip.position.x = left + me_chip.size.x + gap
	if tie:
		var top: float = minf(me_top.y, opp_top.y) - me_chip.size.y - 12 * Palette.DP
		tie_chip.place_above(Vector2((me_top.x + opp_top.x) / 2.0, top))
		_clamp_chip(tie_chip)
		if tie_chip.get_rect().intersects(me_chip.get_rect()) or tie_chip.get_rect().intersects(opp_chip.get_rect()):
			tie_chip.position.y = maxf(me_chip.get_rect().end.y, opp_chip.get_rect().end.y) + 8 * Palette.DP
	_decor.queue_redraw()
	layout_changed.emit()


func _place(view: CrowdView, u: float, lateral: float) -> void:
	var sample: Dictionary = _sample_road(u)
	var dir: Vector2 = sample["dir"]
	view.road_dir = dir
	view.position = sample["point"] + Vector2(lateral, 12 * Palette.DP)
	var bounds: Rect2 = view.visual_bounds()
	view.position.x = clampf(view.position.x, -bounds.position.x + 8 * Palette.DP, size.x - bounds.end.x - 8 * Palette.DP)


## 길 비율 u(0 = 화면 아래 보이는 끝, 1 = 정상 바로 아래)의 점과 오르막 방향.
func _sample_road(u: float) -> Dictionary:
	var points: PackedVector2Array = _road_points()
	var bottom_y: float = size.y - 34.0 * Palette.DP
	var top_y: float = points[points.size() - 1].y + 26.0 * Palette.DP
	var target_y: float = lerpf(bottom_y, top_y, clampf(u, 0.0, 1.0))
	# 길은 아래에서 위로 갈수록 y 가 줄어든다. 목표 높이를 지나는 구간을 찾는다.
	for i: int in range(points.size() - 1):
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		if target_y <= a.y and target_y >= b.y:
			var t: float = (a.y - target_y) / maxf(a.y - b.y, 0.001)
			return {"point": a.lerp(b, t), "dir": (b - a).normalized()}
	return {"point": points[points.size() - 1], "dir": (points[points.size() - 1] - points[points.size() - 2]).normalized()}


func _road_points() -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	for p: Vector2 in ROAD_POINTS:
		out.append(_to_px(p))
	return out


func _to_px(p: Vector2) -> Vector2:
	return Vector2(p.x * size.x / W, p.y * size.y / H)


func _line(color: Color) -> Line2D:
	var line: Line2D = Line2D.new()
	line.default_color = color
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.antialiased = true
	add_child(line)
	return line


func _draw() -> void:
	var dp: float = Palette.DP
	draw_polygon(
		PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]),
		PackedColorArray([Palette.SKY_TOP, Palette.SKY_TOP, Palette.SKY_BOTTOM, Palette.SKY_BOTTOM])
	)
	draw_circle(_to_px(Vector2(W * 0.78, H * 0.19)), 34.0 * dp, Palette.SUN, true, -1.0, true)
	for i: int in range(HILL_Y.size()):
		var y0: float = HILL_Y[i]
		var amp: float = 26.0 - float(i) * 4.0
		var ridge: PackedVector2Array = PackedVector2Array()
		var x: float = 0.0
		while x <= W:
			var y: float = y0 + sin(x / (70.0 + float(i) * 25.0) + float(i) * 1.7) * amp + sin(x / 31.0 + float(i)) * 4.0
			ridge.append(_to_px(Vector2(x, y)))
			x += 6.0
		var hill: PackedVector2Array = ridge.duplicate()
		hill.append(size)
		hill.append(Vector2(0, size.y))
		draw_colored_polygon(hill, Palette.HILLS[i])
		draw_polyline(ridge, Color(Palette.ROAD_EDGE, 0.6), 1.0 * dp, true)


## 길 가운데 점선, 정상 결승선, 순위 보조선. 길 위, 무리 아래에 그린다.
func _draw_decor() -> void:
	var dp: float = Palette.DP
	var points: PackedVector2Array = _road_points()
	for i: int in range(points.size() - 1):
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		var length: float = a.distance_to(b)
		var d: float = 0.0
		while d < length:
			_decor.draw_line(a.lerp(b, d / length), a.lerp(b, minf(d + 3.0 * dp, length) / length), Color(Palette.ROAD_EDGE, 0.7), 1.2 * dp, true)
			d += 12.0 * dp
	_draw_bunting(_to_px(Vector2(128, 100)).x, _to_px(Vector2(232, 100)).x, _to_px(Vector2(0, 100)).y)
	if not _show_opp:
		return
	# 무리 높이마다 가로 점선. 격차가 작아도 누가 위에 있는지 수치 없이 읽힌다.
	if _me_count == _opp_count:
		_dashed_row(me_view.position.y, Palette.TIE)
	else:
		_dashed_row(me_view.position.y, Palette.CHIP_MINE)
		_dashed_row(opp_view.position.y, Palette.CHIP_OPP)


func _dashed_row(y: float, color: Color) -> void:
	var dp: float = Palette.DP
	var x: float = 0.0
	while x < size.x:
		_decor.draw_line(Vector2(x, y), Vector2(x + 2.0 * dp, y), Color(color, 0.85), 1.6 * dp, true)
		x += 7.0 * dp


func _draw_bunting(x1: float, x2: float, y: float) -> void:
	var dp: float = Palette.DP
	_decor.draw_line(Vector2(x1, y + 26 * dp), Vector2(x1, y - 6 * dp), Palette.POLE, 2.2 * dp, true)
	_decor.draw_line(Vector2(x2, y + 26 * dp), Vector2(x2, y - 6 * dp), Palette.POLE, 2.2 * dp, true)
	var rope: PackedVector2Array = PackedVector2Array()
	for i: int in range(17):
		var t: float = float(i) / 16.0
		rope.append(Vector2(lerpf(x1, x2, t), y + 12.0 * dp * 4.0 * t * (1.0 - t) * 0.5))
	_decor.draw_polyline(rope, Palette.BUNTING_LINE, 1.2 * dp, true)
	for i: int in range(1, 9):
		var t: float = float(i) / 9.0
		var x: float = lerpf(x1, x2, t)
		var yy: float = y + 12.0 * dp * 4.0 * t * (1.0 - t)
		var tri: PackedVector2Array = PackedVector2Array([Vector2(x - 6 * dp, yy), Vector2(x + 6 * dp, yy), Vector2(x, yy + 12 * dp)])
		_decor.draw_colored_polygon(tri, Palette.BUNTING[i % 3])
		tri.append(tri[0])
		_decor.draw_polyline(tri, Palette.BUNTING_LINE, 0.9 * dp, true)
	var d: float = x1 + 4 * dp
	while d < x2 - 4 * dp:
		_decor.draw_line(Vector2(d, y + 26 * dp), Vector2(minf(d + 6 * dp, x2 - 4 * dp), y + 26 * dp), Palette.BUNTING_LINE, 2 * dp)
		d += 10 * dp


func _doll_particles(mine: bool, amount: int) -> CPUParticles2D:
	var particles: CPUParticles2D = CPUParticles2D.new()
	particles.texture = CrowdView.DOLL_TEXTURE
	particles.amount = amount
	particles.one_shot = true
	particles.explosiveness = 0.85
	particles.lifetime = 0.9
	particles.scale_amount_min = 0.22
	particles.scale_amount_max = 0.32
	particles.color = _body(mine)
	return particles


func _fire(particles: CPUParticles2D, crowd: CrowdView) -> void:
	particles.local_coords = true
	# 무리에 붙여도 다른 무리보다 위에 그려야 앞 무리에 가려지지 않는다.
	particles.z_index = 10
	crowd.add_child(particles)
	particles.emitting = true
	particles.finished.connect(particles.queue_free)


func _flying_doll(mine: bool) -> Sprite2D:
	var doll: Sprite2D = Sprite2D.new()
	doll.texture = CrowdView.DOLL_TEXTURE
	doll.scale = Vector2.ONE * 0.3
	doll.modulate = _body(mine)
	_fx.add_child(doll)
	return doll


func _clear_fx_sprites() -> void:
	for child: Node in _fx.get_children():
		if child is Sprite2D:
			child.queue_free()


func _body(mine: bool) -> Color:
	return me_view.body_color if mine else opp_view.body_color

func _clamp_chip(chip: CountChip) -> void:
	chip.position.x = clampf(chip.position.x, 8 * Palette.DP, size.x - chip.size.x - 8 * Palette.DP)
	chip.position.y = clampf(chip.position.y, top_clearance, size.y - chip.size.y - bottom_clearance - 8 * Palette.DP)

func reserve_bottom(value: float) -> void:
	bottom_clearance = maxf(0, value)
	_apply()
