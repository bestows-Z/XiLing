extends RefCounted
## Local original artwork is preferred when present; the repository remains usable without it.

const CUSTOM_PATH: String = "res://assets/local/skin.tres"
var frames: SpriteFrames
var mode: StringName = &"native"
var hit_image: Image
var outline: PackedVector2Array = PackedVector2Array()
var _texture_id: int = 0

func load_custom() -> bool:
	if not ResourceLoader.exists(CUSTOM_PATH):
		return false
	var resource: Resource = load(CUSTOM_PATH)
	if not resource is SpriteFrames:
		return false
	var candidate: SpriteFrames = resource as SpriteFrames
	if not candidate.has_animation(&"idle") or candidate.get_frame_count(&"idle") == 0:
		return false
	frames = candidate
	_texture_id = 0
	return true

func load_original() -> bool:
	var open_path: String = "res://assets/pet/xiaoxi.png"
	var blink_path: String = "res://assets/pet/xiaoxi_blink.png"
	if not FileAccess.file_exists(open_path):
		return false
	var open_image: Image = _read_local_image(open_path)
	if open_image == null or open_image.is_empty():
		return false
	frames = SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.add_animation(&"idle")
	frames.add_frame(&"idle", ImageTexture.create_from_image(open_image))
	if FileAccess.file_exists(blink_path):
		var blink_image: Image = _read_local_image(blink_path)
		if blink_image != null and not blink_image.is_empty():
			frames.add_frame(&"idle", ImageTexture.create_from_image(blink_image))
	mode = &"original"
	_texture_id = 0
	return true

func _read_local_image(path: String) -> Image:
	if ResourceLoader.exists(path):
		var texture: Texture2D = load(path) as Texture2D
		if texture != null:
			return texture.get_image()
	# Supports a local PNG added after the editor's last import.
	return Image.load_from_file(ProjectSettings.globalize_path(path))

func apply(sprite: AnimatedSprite2D, action: StringName, progress: float, blinking: bool) -> void:
	if frames == null:
		return
	sprite.sprite_frames = frames
	var chosen: StringName = action if frames.has_animation(action) and frames.get_frame_count(action) > 0 else &"idle"
	var count: int = frames.get_frame_count(chosen)
	if count == 0:
		return
	sprite.animation = chosen
	if mode == &"original":
		sprite.frame = 1 if blinking and count > 1 else 0
	else:
		sprite.frame = clampi(int(progress * count), 0, count - 1)
	var texture: Texture2D = frames.get_frame_texture(chosen, sprite.frame)
	if texture == null:
		return
	var fit: float = minf(250.0 / texture.get_width(), 340.0 / texture.get_height())
	if mode == &"original":
		fit = minf(280.0 / texture.get_width(), 384.0 / texture.get_height())
	sprite.scale = Vector2.ONE * fit
	if texture.get_instance_id() != _texture_id:
		_texture_id = texture.get_instance_id()
		hit_image = texture.get_image()
		_build_outline()

func hit_test(point: Vector2) -> bool:
	if hit_image == null:
		return false
	var pixel: Vector2i = Vector2i((point + Vector2(hit_image.get_size()) * 0.5).floor())
	if pixel.x < 0 or pixel.y < 0 or pixel.x >= hit_image.get_width() or pixel.y >= hit_image.get_height():
		return false
	return hit_image.get_pixelv(pixel).a > 0.1

func _build_outline() -> void:
	var bitmap: BitMap = BitMap.new()
	bitmap.create_from_image_alpha(hit_image, 0.1)
	var rect: Rect2i = Rect2i(Vector2i.ZERO, hit_image.get_size())
	bitmap.grow_mask(3, rect)
	var points: PackedVector2Array = PackedVector2Array()
	for polygon: PackedVector2Array in bitmap.opaque_to_polygons(rect, 2.0):
		for point: Vector2 in polygon:
			points.append(point - Vector2(hit_image.get_size()) * 0.5)
	# A single OS polygon cannot represent disconnected accessories; preserve them with a hull.
	outline = Geometry2D.convex_hull(points) if points.size() >= 3 else PackedVector2Array()
