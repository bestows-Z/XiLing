extends RefCounted
## 对同一动作使用相同尺度和落脚参考，避免每帧重新适配边框导致人物忽大忽小。
static func load_six(path: String, sleeping: bool = false) -> Array[Texture2D]:
	var result: Array[Texture2D] = []
	if not ResourceLoader.exists(path): return result
	var sheet: Texture2D = load(path) as Texture2D
	var cell: Vector2i = Vector2i(sheet.get_size()) / Vector2i(3, 2)
	var image: Image = sheet.get_image()
	var bounds: Array[Rect2] = []
	for index: int in range(6):
		var region: Rect2i = Rect2i(Vector2i(index % 3, index / 3) * cell, cell)
		var texture: AtlasTexture = AtlasTexture.new()
		texture.atlas = sheet
		texture.region = Rect2(region)
		texture.filter_clip = true
		result.append(texture)
		var bitmap: BitMap = BitMap.new()
		bitmap.create_from_image_alpha(image.get_region(region), 0.15)
		var rect: Rect2 = Rect2(Vector2(cell) * 0.5, Vector2.ZERO)
		for polygon: PackedVector2Array in bitmap.opaque_to_polygons(Rect2i(Vector2i.ZERO, cell), 3.0):
			for point: Vector2 in polygon: rect = rect.expand(point)
		bounds.append(rect)
	var max_height: float = 1.0
	var max_width: float = 1.0
	for rect: Rect2 in bounds:
		max_height = maxf(max_height, rect.size.y)
		max_width = maxf(max_width, rect.size.x)
	var fit: float = minf((260.0 if sleeping else 368.0) / max_height, 312.0 / max_width)
	var offset: Vector2 = Vector2(-(bounds[0].get_center().x - cell.x * 0.5) * fit, 182.0 - (bounds[0].end.y - cell.y * 0.5) * fit)
	for texture: Texture2D in result:
		texture.set_meta("display_fit", fit)
		texture.set_meta("display_offset", offset)
	return result
