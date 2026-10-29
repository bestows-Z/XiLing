extends RefCounted
## 浮点绝对目标避免高分屏逐帧取整积累误差；速度由同一条时间曲线决定。
var position: Vector2 = Vector2.ZERO
var direction: float = 1.0
var distance: float = 0.0
var active: bool = false
var hover_paused: bool = false
var speed: float = 38.0
var _bounds: Rect2
var _time: float = 0.0
const EASE_TIME: float = 0.5

func begin(origin: Vector2, limits: Rect2, heading: float) -> void:
	_bounds = limits
	position = Vector2(clampf(origin.x, limits.position.x, limits.end.x), origin.y)
	direction = -1.0 if heading < 0.0 else 1.0
	distance = 0.0
	_time = 0.0
	active = limits.size.x > 0.0

func advance(delta: float) -> Vector2i:
	if not active or not is_finite(delta) or delta <= 0.0: return Vector2i(position.round())
	var step: float = minf(delta, 0.25)
	var travel: float = _integral(_time + step) - _integral(_time)
	_time += step
	var next: float = position.x + travel * direction
	if next > _bounds.end.x:
		next = _bounds.end.x - (next - _bounds.end.x)
		direction = -1.0
	elif next < _bounds.position.x:
		next = _bounds.position.x + (_bounds.position.x - next)
		direction = 1.0
	position.x = clampf(next, _bounds.position.x, _bounds.end.x)
	distance += travel
	return Vector2i(position.round())

func _integral(seconds: float) -> float:
	if seconds >= EASE_TIME: return speed * (seconds - EASE_TIME * 0.5)
	var u: float = seconds / EASE_TIME
	return speed * EASE_TIME * (pow(u, 3) - 0.5 * pow(u, 4))

func stop() -> void:
	active = false

func pause_for_hover(over_pet: bool, inside_window: bool) -> bool:
	if not inside_window: hover_paused = false
	elif over_pet: hover_paused = true
	return hover_paused
