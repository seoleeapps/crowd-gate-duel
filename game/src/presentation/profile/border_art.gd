class_name BorderArt
extends RefCounted
## 결과 카드 테두리(꾸미기). 금속 질감이나 장식 프레임 없이 단색 도형만 쓴다(04 UI 아트 경계).


static func draw(canvas: CanvasItem, rect: Rect2, style: String, unit: float, alpha: float = 1.0) -> void:
	match style:
		"ink":
			canvas.draw_rect(rect.grow(-3 * unit), Color(Palette.INK, alpha), false, 6 * unit)
		"stripes":
			var step: float = 10 * unit
			var x: float = rect.position.x
			var i: int = 0
			while x < rect.end.x:
				var color: Color = Color(Palette.MINE if i % 2 == 0 else Palette.PANEL, alpha)
				canvas.draw_rect(Rect2(x, rect.position.y, minf(step, rect.end.x - x), 6 * unit), color)
				canvas.draw_rect(Rect2(x, rect.end.y - 6 * unit, minf(step, rect.end.x - x), 6 * unit), color)
				x += step
				i += 1
			canvas.draw_rect(rect, Color(Palette.INK, alpha), false, 1.5 * unit)
		"bunting":
			var count: int = maxi(3, int(rect.size.x / (14 * unit)))
			var w: float = rect.size.x / float(count)
			for i: int in range(count):
				var left: float = rect.position.x + float(i) * w
				canvas.draw_colored_polygon(PackedVector2Array([
					Vector2(left, rect.position.y), Vector2(left + w, rect.position.y),
					Vector2(left + w / 2.0, rect.position.y + w * 0.9),
				]), Color(Palette.BUNTING[i % 3] if i % 3 != 0 else Palette.MINE, alpha))
			canvas.draw_rect(rect, Color(Palette.BUNTING_LINE, alpha), false, 1.5 * unit)
		_:
			canvas.draw_rect(rect, Color(Palette.STEP_LINE, alpha), false, 1.0 * unit)
