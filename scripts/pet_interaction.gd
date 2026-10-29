extends RefCounted
## 可测试的手势识别，不依赖窗口或角色素材。
signal action_requested(action: StringName)
var pending_click: float = -1.0
var _time: float = 0.0
var _clicks: Array[float] = []
var _stroke_distance: float = 0.0
var _reversals: int = 0
var _direction: float = 0.0
var _pet_cooldown: float = 0.0
var _stroke_idle: float = 0.0

func tick(delta: float) -> void:
	_time += delta
	_pet_cooldown = maxf(0.0, _pet_cooldown - delta)
	_stroke_idle += delta
	if _stroke_idle > 1.0:
		_stroke_distance = 0.0
		_reversals = 0
		_direction = 0.0
	if pending_click >= 0.0:
		pending_click -= delta
		if pending_click < 0.0:
			action_requested.emit(&"pet")

func click(double: bool) -> void:
	_clicks.append(_time)
	while not _clicks.is_empty() and _time - _clicks[0] > 2.0:
		_clicks.pop_front()
	if _clicks.size() >= 5:
		cancel()
		_clicks.clear()
		action_requested.emit(&"surprised")
	elif double:
		cancel()
		action_requested.emit(&"wave")
	else:
		pending_click = 0.45

func motion(relative: Vector2, over_pet: bool, dragging: bool) -> void:
	if dragging or not over_pet or absf(relative.x) < 1.0:
		return
	_stroke_idle = 0.0
	var direction: float = signf(relative.x)
	if _direction != 0.0 and _direction != direction:
		_reversals += 1
	_direction = direction
	_stroke_distance += absf(relative.x)
	if _stroke_distance >= 120.0 and _reversals >= 2 and _pet_cooldown <= 0.0:
		cancel()
		action_requested.emit(&"pet")
		_pet_cooldown = 2.0
		_stroke_distance = 0.0
		_reversals = 0

func cancel() -> void:
	pending_click = -1.0
