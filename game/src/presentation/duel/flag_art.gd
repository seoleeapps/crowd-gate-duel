class_name FlagArt
extends RefCounted
## 깃발 그리기. 무늬는 기하 도형 조합이다(04 캐릭터와 세계).
## 대국의 무리와 꾸미기 미리보기가 같은 코드로 그린다.
##   나 기본: chevron, 상대: dot, 봇 전용: bars(무채색), 꾸미기: diamond·cross·stripes·triangle·ring·zigzag·star


## base 는 깃대 아래 끝. unit 은 시안 1 단위의 픽셀 크기다.
static func draw(canvas: CanvasItem, base: Vector2, unit: float, pattern: String, cloth: Color, mark: Color) -> void:
	var top: Vector2 = base - Vector2(0, 30 * unit)
	var w: float = 20 * unit
	var fh: float = 13 * unit
	canvas.draw_line(base, top, Palette.POLE, 1.6 * unit, true)
	canvas.draw_colored_polygon(PackedVector2Array([
		top, top + Vector2(w, 0), top + Vector2(w - 3.5 * unit, fh / 2.0), top + Vector2(w, fh), top + Vector2(0, fh),
	]), cloth)
	var c: Vector2 = top + Vector2(w / 2.0 - 1.5 * unit, fh / 2.0)
	var line: float = 2.2 * unit
	match pattern:
		"chevron":
			canvas.draw_polyline(PackedVector2Array([
				top + Vector2(3 * unit, 2.5 * unit), top + Vector2(10 * unit, fh / 2.0), top + Vector2(3 * unit, fh - 2.5 * unit),
			]), mark, 2.4 * unit, true)
		"dot":
			canvas.draw_circle(c + Vector2(1.5 * unit, 0), 3.4 * unit, mark, true, -1.0, true)
		"bars":
			for x: float in [6.0, 12.0]:
				canvas.draw_line(top + Vector2(x * unit, 2 * unit), top + Vector2(x * unit, fh - 2 * unit), mark, line)
		"diamond":
			canvas.draw_colored_polygon(PackedVector2Array([
				c + Vector2(0, -4.5 * unit), c + Vector2(4.5 * unit, 0), c + Vector2(0, 4.5 * unit), c + Vector2(-4.5 * unit, 0),
			]), mark)
		"cross":
			canvas.draw_line(c + Vector2(-4 * unit, 0), c + Vector2(4 * unit, 0), mark, line)
			canvas.draw_line(c + Vector2(0, -4 * unit), c + Vector2(0, 4 * unit), mark, line)
		"stripes":
			for y: float in [3.5, 6.5, 9.5]:
				canvas.draw_line(top + Vector2(2 * unit, y * unit), top + Vector2(w - 5 * unit, y * unit), mark, 1.6 * unit)
		"triangle":
			canvas.draw_colored_polygon(PackedVector2Array([
				c + Vector2(-4 * unit, 3.5 * unit), c + Vector2(4 * unit, 3.5 * unit), c + Vector2(0, -4 * unit),
			]), mark)
		"ring":
			canvas.draw_arc(c, 3.6 * unit, 0.0, TAU, 20, mark, 1.8 * unit, true)
		"zigzag":
			canvas.draw_polyline(PackedVector2Array([
				c + Vector2(-6 * unit, 2 * unit), c + Vector2(-3 * unit, -2 * unit), c + Vector2(0, 2 * unit),
				c + Vector2(3 * unit, -2 * unit), c + Vector2(6 * unit, 2 * unit),
			]), mark, 1.8 * unit, true)
		"star":
			var star: PackedVector2Array = PackedVector2Array()
			for i: int in range(10):
				var radius: float = (4.6 if i % 2 == 0 else 2.0) * unit
				var angle: float = -PI / 2.0 + PI * float(i) / 5.0
				star.append(c + Vector2(cos(angle), sin(angle)) * radius)
			canvas.draw_colored_polygon(star, mark)
