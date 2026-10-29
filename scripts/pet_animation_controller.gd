extends RefCounted
## 表现层统一入口：原画两帧、程序关节、外部多帧资源共用同一行为状态。
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

func setup(target: AnimatedSprite2D, drawing: Node2D, adapter: RefCounted, character: Resource = null) -> void:
	sprite = target
	profile = character
	visual = drawing
	skin = adapter
	origin = target.position
	_rng.randomize()

func tick(delta: float, brain: RefCounted) -> void:
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

func apply(brain: RefCounted) -> void:
	var action: StringName = brain.action if enabled else &"idle"
	var progress: float = brain.progress() if enabled else 0.0
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
		return
	visual.hide()
	if skin.frames != null and skin.mode == &"custom":
		var chosen: StringName = action if skin.frames.has_animation(action) and skin.frames.get_frame_count(action) > 0 else &"idle"
		var total: float = skin.total_frame_duration(chosen)
		if skin.frames.get_animation_loop(chosen) and total > 0.0:
			progress = fposmod(brain.action_elapsed * skin.frames.get_animation_speed(chosen) / total, 1.0) if enabled else 0.0
	skin.apply(sprite, action, progress, (blinking and enabled) or action == &"sleep")
	if skin.mode == &"original" and enabled:
		sprite.position.y += sin(elapsed * 1.8) * 5.0
		sprite.scale *= 1.0 + sin(elapsed * 2.16) * 0.012
		# 原图只保留旧版整体反馈，不冒充精绘肢体动画。
		var reaction: float = sin(progress * PI) if action == &"jump" else 0.0
		sprite.position.y -= reaction * 18.0
		sprite.scale *= 1.0 + reaction * 0.06
		sprite.rotation = deg_to_rad(3.0) * reaction
