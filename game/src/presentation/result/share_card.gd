class_name ShareCard
extends SubViewport
## 공유용 결과 카드. 정사각형과 세로 두 규격을 만든다(04 UI 아트 경계).
## 카드에는 앱 이름과 최종 수만 넣는다. 앱 이름은 제품명 결정(DEC-002) 전까지 작업명이다.

const SQUARE: Vector2i = Vector2i(1080, 1080)
const VERTICAL: Vector2i = Vector2i(1080, 1920)


## 카드를 한 번 그려 이미지로 돌려준다. 호출자는 트리에 붙인 뒤 await 한다.
static func render(parent: Node, card_size: Vector2i, scene: Image, me: int, opp: int, result_color: Color) -> Image:
	var card: ShareCard = ShareCard.new()
	card.size = card_size
	card.render_target_update_mode = SubViewport.UPDATE_ONCE
	card.transparent_bg = false
	parent.add_child(card)
	card._build(scene, me, opp, result_color)
	await RenderingServer.frame_post_draw
	var image: Image = card.get_texture().get_image()
	card.queue_free()
	return image


func _build(scene: Image, me: int, opp: int, result_color: Color) -> void:
	var dp: float = Palette.DP
	var root: Control = Control.new()
	root.size = Vector2(size)
	root.theme = UiTheme.build()
	add_child(root)
	var bg: ColorRect = ColorRect.new()
	bg.color = Palette.BG
	bg.size = root.size
	root.add_child(bg)
	var picture: TextureRect = TextureRect.new()
	if scene != null and not scene.is_empty():
		picture.texture = ImageTexture.create_from_image(ResultScreen.scene_crop(scene))
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	picture.size = Vector2(root.size.x, root.size.y - 150 * dp)
	root.add_child(picture)
	var strip: ColorRect = ColorRect.new()
	strip.color = Palette.PANEL
	strip.position = Vector2(0, root.size.y - 150 * dp)
	strip.size = Vector2(root.size.x, 150 * dp)
	root.add_child(strip)
	var edge: ColorRect = ColorRect.new()
	edge.color = result_color
	edge.position = strip.position
	edge.size = Vector2(root.size.x, 4 * dp)
	root.add_child(edge)
	var score: Label = Label.new()
	score.text = "%d : %d" % [me, opp]
	score.add_theme_font_override("font", UiTheme.number_font(700))
	score.add_theme_font_size_override("font_size", int(44 * dp))
	score.add_theme_color_override("font_color", result_color)
	score.position = Vector2(20 * dp, strip.position.y + 22 * dp)
	root.add_child(score)
	var name_label: Label = Label.new()
	name_label.text = tr("APP_NAME")
	name_label.add_theme_font_override("font", UiTheme.text_font(700))
	name_label.add_theme_font_size_override("font_size", int(18 * dp))
	name_label.add_theme_color_override("font_color", Palette.INK)
	name_label.position = Vector2(20 * dp, strip.position.y + 90 * dp)
	root.add_child(name_label)
