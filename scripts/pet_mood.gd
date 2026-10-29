extends RefCounted
## 属性均为 0..100；不累计离线惩罚，亲密度不会因离开而下降。
var joy: float = 65.0:
	set(value): joy = _bounded(value, 65.0)
var energy: float = 80.0:
	set(value): energy = _bounded(value, 80.0)
var affection: float = 20.0:
	set(value): affection = _bounded(value, 20.0)
var boredom: float = 10.0:
	set(value): boredom = _bounded(value, 10.0)
var curiosity: float = 65.0:
	set(value): curiosity = _bounded(value, 65.0)
var expression: StringName = &""
var expression_time: float = 0.0

func _bounded(value: float, fallback: float) -> float:
	return clampf(value, 0.0, 100.0) if is_finite(value) else fallback

func tick(delta: float, sleeping: bool) -> void:
	if not is_finite(delta) or delta <= 0.0:
		return
	var step: float = minf(delta, 60.0)
	if sleeping:
		energy += step * 2.4
		boredom -= step * 0.2
	else:
		boredom += step * 0.06
	# 兴奋逐渐平复，不会因为没人照看变得不开心。
	if joy > 65.0:
		joy = maxf(65.0, joy - step * 0.02)
	expression_time = maxf(0.0, expression_time - step)
	if expression_time <= 0.0:
		expression = &""

func reward(kind: StringName) -> void:
	boredom -= 8.0
	match kind:
		&"pet", &"wave", &"happy", &"shy":
			joy += 5.0
			affection += 1.2
		&"feed":
			energy += 12.0
			joy += 4.0
			affection += 0.6
		&"jump", &"dance", &"walk", &"bubbles":
			joy += 7.0
			energy -= 3.0
			affection += 0.8
		&"curious", &"look":
			curiosity += 2.0

func label() -> StringName:
	if expression_time > 0.0:
		return expression
	if energy < 25.0:
		return &"sleepy"
	return &"happy" if joy >= 75.0 else &"calm"

func snapshot() -> Dictionary:
	return {"joy": joy, "energy": energy, "affection": affection, "boredom": boredom, "curiosity": curiosity}

func restore(data: Dictionary) -> void:
	joy = _read_number(data, "joy", 65.0)
	energy = _read_number(data, "energy", 80.0)
	affection = _read_number(data, "affection", 20.0)
	boredom = _read_number(data, "boredom", 10.0)
	curiosity = _read_number(data, "curiosity", 65.0)
	expression = &""
	expression_time = 0.0

func _read_number(data: Dictionary, key: String, fallback: float) -> float:
	var value: Variant = data.get(key, fallback)
	return _bounded(float(value), fallback) if value is float or value is int else fallback
