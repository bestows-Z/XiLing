extends SceneTree
const Brain = preload("res://scripts/pet_brain.gd")
const Visual = preload("res://scripts/pet_visual.gd")
const Adapter = preload("res://scripts/local_skin.gd")
const Animator = preload("res://scripts/pet_animation_controller.gd")
var failures: int = 0
var checks: int = 0
func check(value: bool, text: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(text)
func _initialize() -> void:
	var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
	var visual = Visual.new()
	sprite.add_child(visual)
	var brain = Brain.new()
	var skin = Adapter.new()
	var animation = Animator.new()
	animation.setup(sprite, visual, skin)
	animation.enabled = false
	brain.request(&"jump")
	animation.tick(1.0, brain)
	check(animation.elapsed == 0.0 and visual.pose["body"] == Vector2.ZERO, "pause freezes movement instead of advancing the pose")
	animation.enabled = true
	animation.tick(0.5, brain)
	check(animation.elapsed > 0.0, "animation resumes")
	var frames: SpriteFrames = SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.add_animation(&"idle")
	frames.set_animation_speed(&"idle", 2.0)
	var image: Image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	frames.add_frame(&"idle", ImageTexture.create_from_image(image), 1.0)
	frames.add_frame(&"idle", ImageTexture.create_from_image(image), 3.0)
	skin.frames = frames
	skin.mode = &"custom"
	skin.apply(sprite, &"idle", 0.4, false)
	check(sprite.frame == 1, "unequal frame durations are respected")
	brain.reset()
	brain.action_elapsed = 1.0
	animation.apply(brain)
	check(sprite.frame == 1, "looping skin uses total relative frame duration")
	skin.mode = &"original"
	animation._blink_timer = 0.001
	animation.tick(0.02, brain)
	check(sprite.frame == 1, "original artwork blinks")
	animation.tick(0.2, brain)
	check(sprite.frame == 0, "blink returns to open-eye frame")
	skin.mode = &"native"
	animation.apply(brain)
	check(visual.visible and sprite.sprite_frames == null, "native fallback has no texture dependency")
	sprite.free()
	var original = Adapter.new()
	if original.load_original():
		var original_sprite: AnimatedSprite2D = AnimatedSprite2D.new()
		original.apply(original_sprite, &"idle", 0.0, false)
		check(original_sprite.sprite_frames.get_frame_texture(&"idle", 0).get_width() == 1024, "default idle retains the user's original image")
		for action: StringName in [&"wave", &"jump", &"pet", &"feed", &"curious", &"wake", &"walk", &"dance"]:
			check(original.frames.has_animation(action) and original.frames.get_frame_count(action) >= 2, "%s has actual picture frames" % action)
			original.apply(original_sprite, action, 0.25, false)
			check(original_sprite.animation == action and original_sprite.sprite_frames.get_frame_texture(action, original_sprite.frame) is AtlasTexture, "%s displays a real action pose" % action)
		check(original.frames.get_frame_texture(&"sleep", 0) is AtlasTexture, "sleep shows its actual sleeping drawing")
		original_sprite.free()
	print("Animation tests: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
