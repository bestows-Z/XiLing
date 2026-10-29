extends RefCounted
## 只在已有实画帧之间短暂淡化边缘；不生成或伪造中间动作图片。
var ghost: Sprite2D
var outline: PackedVector2Array = PackedVector2Array()
var _remaining: float = 0.0
const DURATION: float = 0.10
func begin(sprite: AnimatedSprite2D, texture: Texture2D, old_transform: Transform2D, old_global: Transform2D, old_outline: PackedVector2Array) -> void:
	if sprite.get_parent() == null or texture == null: return
	if ghost == null or not is_instance_valid(ghost):
		ghost = Sprite2D.new()
		ghost.name = "FrameTransition"
		sprite.get_parent().add_child(ghost)
	ghost.texture = texture
	ghost.transform = old_transform
	ghost.z_index = sprite.z_index
	ghost.show()
	outline = old_global * old_outline
	_remaining = DURATION

func tick(sprite: AnimatedSprite2D, delta: float, enabled: bool) -> void:
	_remaining = maxf(0.0, _remaining - maxf(0.0, delta)) if enabled else 0.0
	var alpha: float = smoothstep(0.0, 1.0, 1.0 - _remaining / DURATION)
	# 新帧保持不透明；旧帧覆盖淡出，避免两个半透明层让整个角色周期性变淡。
	sprite.modulate.a = 1.0
	if ghost != null and is_instance_valid(ghost):
		ghost.modulate.a = 1.0 - alpha
		ghost.visible = _remaining > 0.0
	if _remaining <= 0.0: outline = PackedVector2Array()

func finish(sprite: AnimatedSprite2D) -> void:
	_remaining = 0.0
	tick(sprite, 0.0, false)
