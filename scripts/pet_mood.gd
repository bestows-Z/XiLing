extends RefCounted
## Small, local needs model. Values describe game state, not human emotion.

var joy: float = 65.0:
	set(value):
		joy = _bounded(value, 65.0)
var energy: float = 80.0:
	set(value):
		energy = _bounded(value, 80.0)
var affection: float = 20.0:
	set(value):
		affection = _bounded(value, 20.0)


func _bounded(value: float, fallback: float) -> float:
	return clampf(value, 0.0, 100.0) if is_finite(value) else fallback


func tick(delta: float, sleeping: bool) -> void:
	if not is_finite(delta) or delta <= 0.0:
		return
	energy += delta * (2.4 if sleeping else -0.12)
	joy -= delta * (0.015 if sleeping else 0.045)
	affection -= delta * 0.003


func reward(kind: StringName) -> void:
	match kind:
		&"pet", &"wave":
			joy += 5.0
			affection += 1.2
		&"feed":
			energy += 12.0
			joy += 4.0
			affection += 0.6
		&"jump", &"dance":
			joy += 7.0
			energy -= 3.0
			affection += 0.8
		&"curious":
			joy += 2.0


func label() -> StringName:
	if energy < 25.0:
		return &"sleepy"
	return &"happy" if joy >= 65.0 else &"calm"


func snapshot() -> Dictionary:
	return {"joy": joy, "energy": energy, "affection": affection}


func restore(data: Dictionary) -> void:
	joy = _read_number(data, "joy", 65.0)
	energy = _read_number(data, "energy", 80.0)
	affection = _read_number(data, "affection", 20.0)


func _read_number(data: Dictionary, key: String, fallback: float) -> float:
	var value: Variant = data.get(key, fallback)
	if value is float or value is int:
		return _bounded(float(value), fallback)
	return fallback
