extends RefCounted
const FrameTransition = preload("res://scripts/pet_frame_transition.gd")
## 表现层统一入口：原始待机 PNG、实际动作图集、外部多帧资源。
var sprite: AnimatedSprite2D
var visual: Node2D
var skin: RefCounted
var origin: Vector2
var elapsed: float = 0.0
var profile: Resource
var enabled: bool = true
var blinking: bool = false
var _blink_timer: float = 3.0
var _blink_remaining: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var transition = FrameTransition.new()
var walk_paused: bool = false
var walk_distance: float = 0.0
var walk_direction: float = 1.0
var _delta: float = 0.0
var _last_action: StringName = &""
var _walk_progress: float = 0.0

func setup(target: AnimatedSprite2D, drawing: Node2D, adapter: RefCounted, character: Resource = null) -> void:
	sprite = target
	profile = character
	visual = drawing
	skin = adapter
	origin = target.position
	_rng.randomize()

func tick(delta: float, brain: RefCounted) -> void:
	_delta = delta
	if enabled:
		elapsed += delta
		_blink_timer -= delta
		if blinking:
			_blink_remaining -= delta
			if _blink_remaining <= 0.0:
				blinking = false
				_blink_timer = _rng.randf_range(3.0, 6.0)
		elif _blink_timer <= 0.0:
			blinking = true
			_blink_remaining = 0.12
	apply(brain)
	_delta = 0.0

func apply(brain: RefCounted) -> void:
	var action: StringName = brain.action if enabled else &"idle"
	var progress: float = brain.progress() if enabled else 0.0
	if action == &"walk":
		if not walk_paused: _walk_progress = fposmod(walk_distance / 54.0, 1.0)
		progress = _walk_progress
	var old_texture: Texture2D
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(sprite.animation) and sprite.sprite_frames.get_frame_count(sprite.animation) > sprite.frame:
		old_texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	var old_transform: Transform2D = sprite.transform
	var old_global: Transform2D = sprite.get_global_transform_with_canvas() if sprite.is_inside_tree() else sprite.transform
	var old_outline: PackedVector2Array = skin.outline
	if skin.mode == &"custom" and action == &"idle" and profile != null:
		var mapped: Variant = profile.expressions.get(String(brain.mood.label()), "idle")
		var expression: StringName = StringName(mapped) if mapped is String or mapped is StringName else &"idle"
		if skin.frames != null and skin.frames.has_animation(expression): action = expression
	sprite.position = origin
	sprite.rotation = 0.0
	if skin.mode == &"native":
		sprite.scale = Vector2.ONE
		sprite.sprite_frames = null
		visual.show()
		visual.set_pose(action, progress, elapsed, brain.mood.label(), blinking and enabled)
		transition.finish(sprite)
		_last_action = action
		return
	visual.hide()
	if skin.frames != null and skin.mode in [&"custom", &"original"]:
		var chosen: StringName = action if skin.frames.has_animation(action) and skin.frames.get_frame_count(action) > 0 else &"idle"
		var total: float = skin.total_frame_duration(chosen)
		if skin.frames.get_animation_loop(chosen) and total > 0.0:
			progress = fposmod(brain.action_elapsed * skin.frames.get_animation_speed(chosen) / total, 1.0) if enabled else 0.0
	if action == &"walk": progress = _walk_progress
	skin.apply(sprite, action, progress, (blinking and enabled) or action == &"sleep")
	sprite.position += skin.frame_offset
	if action == &"walk" and walk_direction < 0:
		sprite.scale.x = -absf(sprite.scale.x)
		sprite.position.x = origin.x - skin.frame_offset.x
	if skin.mode == &"original" and enabled:
		sprite.position.y += sin(elapsed * 1.2) * (2.0 if action == &"idle" else 0.6)
		sprite.scale *= 1.0 + sin(elapsed * 1.6) * 0.005
		var reaction: float = sin(progress * PI) if action == &"jump" else 0.0
		sprite.position.y -= reaction * 12.0
	var new_texture: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame) if sprite.sprite_frames != null else null
	if enabled and old_texture != null and new_texture != old_texture and (action != _last_action or (new_texture is AtlasTexture and old_texture is AtlasTexture)):
		transition.begin(sprite, old_texture, old_transform, old_global, old_outline)
	transition.tick(sprite, _delta, enabled)
	_last_action = action
