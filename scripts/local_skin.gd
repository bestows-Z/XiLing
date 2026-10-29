extends RefCounted
## 原始待机/眨眼 PNG 与动作图集共用透明度命中接口。
const XiaoxiAnimations = preload("res://scripts/xiaoxi_animations.gd")

const CUSTOM_PATH: String = "res://assets/local/skin.tres"
var frames: SpriteFrames
var mode: StringName = &"native"
var hit_image: Image
var outline: PackedVector2Array = PackedVector2Array()
var _texture_id: int = 0
var frame_offset: Vector2 = Vector2.ZERO
var original_path: String = "res://assets/pet/xiaoxi.png"
var blink_path: String = "res://assets/pet/xiaoxi_blink.png"
var custom_path: String = CUSTOM_PATH

func configure(profile: Resource) -> void:
	original_path = profile.original_image
	blink_path = profile.blink_image
	custom_path = profile.animation_frames

func load_custom() -> bool:
	if custom_path.is_empty() or not ResourceLoader.exists(custom_path):
		return false
	var resource: Resource = load(custom_path)
	if not resource is SpriteFrames:
		return false
	var candidate: SpriteFrames = resource as SpriteFrames
	if not candidate.has_animation(&"idle") or candidate.get_frame_count(&"idle") == 0:
		return false
	frames = candidate
	_texture_id = 0
	return true

func load_original() -> bool:
	var open_path: String = original_path
	if open_path.is_empty() or (not ResourceLoader.exists(open_path) and not FileAccess.file_exists(open_path)):
		return false
	var open_image: Image = _read_local_image(open_path)
	if open_image == null or open_image.is_empty():
		return false
	frames = SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.add_animation(&"idle")
	frames.add_frame(&"idle", ImageTexture.create_from_image(open_image))
	if ResourceLoader.exists(blink_path) or FileAccess.file_exists(blink_path):
		var blink_image: Image = _read_local_image(blink_path)
		if blink_image != null and not blink_image.is_empty():
			frames.add_frame(&"idle", ImageTexture.create_from_image(blink_image))
	if original_path == "res://assets/pet/xiaoxi.png": XiaoxiAnimations.append_to(frames)
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
	if mode == &"original" and chosen == &"idle":
		sprite.frame = 1 if blinking and count > 1 else 0
	else:
		var remaining: float = clampf(progress, 0.0, 1.0) * total_frame_duration(chosen)
		var selected: int = count - 1
		for index: int in range(count):
			remaining -= frames.get_frame_duration(chosen, index)
			if remaining < 0.0:
				selected = index
				break
		sprite.frame = selected
	var texture: Texture2D = frames.get_frame_texture(chosen, sprite.frame)
	if texture == null:
		return
	var fit: float = minf(250.0 / texture.get_width(), 340.0 / texture.get_height())
	if mode == &"original":
		fit = minf(280.0 / texture.get_width(), 384.0 / texture.get_height())
		if texture is AtlasTexture: fit = 320.0 / texture.get_height()
		fit = float(texture.get_meta("display_fit", fit))
	frame_offset = texture.get_meta("display_offset", Vector2(0, 26) if mode == &"original" and texture is AtlasTexture else Vector2.ZERO)
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

func total_frame_duration(animation_name: StringName) -> float:
	var total: float = 0.0
	if frames != null and frames.has_animation(animation_name):
		for index: int in range(frames.get_frame_count(animation_name)):
			total += frames.get_frame_duration(animation_name, index)
	return total
