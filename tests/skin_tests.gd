extends SceneTree
## Uses in-memory textures and ResourceLoader cache entries. No artwork is saved.

const LocalSkin = preload("res://scripts/local_skin.gd")
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	_test_alpha_and_frames()
	_test_loading_transactions()
	print("Skin tests: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)


func _texture(hollow: bool = false) -> ImageTexture:
	var image: Image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for x: int in range(8, 24):
		for y: int in range(8, 24):
			image.set_pixel(x, y, Color.WHITE)
	image.set_pixel(10, 10, Color(1, 1, 1, 0.05))
	if hollow:
		image.set_pixel(16, 16, Color.TRANSPARENT)
	return ImageTexture.create_from_image(image)


func _frames() -> SpriteFrames:
	var result: SpriteFrames = SpriteFrames.new()
	result.remove_animation(&"default")
	result.add_animation(&"idle")
	result.add_frame(&"idle", _texture())
	result.add_frame(&"idle", _texture(true))
	result.add_animation(&"jump")
	result.add_frame(&"jump", _texture(true))
	result.add_frame(&"jump", _texture())
	result.add_animation(&"wave") # An optional action can be present but empty.
	return result


func _test_alpha_and_frames() -> void:
	var skin = LocalSkin.new()
	var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
	skin.frames = _frames()
	skin.mode = &"custom"
	skin.apply(sprite, &"idle", 0.0, false)
	check(sprite.animation == &"idle" and sprite.frame == 0, "custom idle starts at the first frame")
	check(skin.hit_test(Vector2.ZERO), "opaque center receives clicks")
	check(not skin.hit_test(Vector2(-12, -12)), "transparent in-image pixel passes clicks through")
	check(not skin.hit_test(Vector2(-6, -6)), "alpha below threshold passes clicks through")
	check(not skin.hit_test(Vector2(-17, 0)) and not skin.hit_test(Vector2(16, 0)), "out-of-image coordinates are rejected")
	check(skin.outline.size() >= 3 and Geometry2D.is_point_in_polygon(Vector2.ZERO, skin.outline), "bitmap outline encloses the rendered opaque body")
	check(is_equal_approx(sprite.scale.x, 250.0 / 32.0), "skin fits the available display area")
	skin.apply(sprite, &"idle", 1.0, false)
	check(sprite.frame == 1, "progress one selects the final frame without overflow")
	check(not skin.hit_test(Vector2.ZERO), "hit mask updates when the displayed frame changes")
	skin.apply(sprite, &"jump", 0.0, false)
	check(sprite.animation == &"jump" and sprite.frame == 0, "custom action selects its own animation")
	skin.apply(sprite, &"wave", 0.0, false)
	check(sprite.animation == &"idle" and sprite.frame == 0, "empty optional action falls back to idle")
	skin.apply(sprite, &"missing", 0.0, false)
	check(sprite.animation == &"idle", "missing optional action falls back to idle")
	skin.mode = &"original"
	skin.apply(sprite, &"idle", 0.0, true)
	check(sprite.frame == 1, "local original preview uses its blink frame")
	skin.apply(sprite, &"idle", 0.0, false)
	check(sprite.frame == 0, "local original preview returns to its open-eye frame")
	sprite.free()


func _test_loading_transactions() -> void:
	var skin = LocalSkin.new()
	var original: SpriteFrames = _frames()
	skin.frames = original
	skin.mode = &"custom"
	# This suite belongs in a clean checkout; excluded original PNGs are absent.
	if not FileAccess.file_exists("res://assets/pet/xiaoxi.png"):
		check(not skin.load_original(), "missing local original fails cleanly")
		check(skin.frames == original and skin.mode == &"custom", "missing original preserves the active skin")
	else:
		print("Skin tests: skipped missing-original case because local originals exist")
	# take_over_path registers only an in-process cache entry. It creates no file.
	var invalid: SpriteFrames = SpriteFrames.new()
	invalid.take_over_path(LocalSkin.CUSTOM_PATH)
	check(ResourceLoader.exists(LocalSkin.CUSTOM_PATH), "synthetic custom resource is visible to ResourceLoader")
	check(not skin.load_custom(), "custom resource without idle is rejected")
	check(skin.frames == original and skin.mode == &"custom", "invalid candidate cannot replace an active skin")
	var empty: SpriteFrames = SpriteFrames.new()
	empty.add_animation(&"idle")
	empty.take_over_path(LocalSkin.CUSTOM_PATH)
	check(not skin.load_custom() and skin.frames == original, "empty idle cannot replace an active skin")
	var wrong_type: Resource = Resource.new()
	wrong_type.take_over_path(LocalSkin.CUSTOM_PATH)
	check(not skin.load_custom() and skin.frames == original, "wrong resource type cannot replace an active skin")
	var valid: SpriteFrames = _frames()
	valid.take_over_path(LocalSkin.CUSTOM_PATH)
	check(skin.load_custom() and skin.frames == valid, "valid custom frames become the active resource")
	var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
	skin.apply(sprite, &"wave", 0.0, false)
	check(sprite.animation == &"idle" and skin.hit_test(Vector2.ZERO), "loaded skin still supports empty-action fallback and alpha hit tests")
	sprite.free()
