extends RefCounted
signal changed(key: String, value: Variant)
const DEFAULTS: Dictionary = {"scale": 1.0, "topmost": true, "animations": true, "max_fps": 60, "autonomous": true, "proactive": true, "quiet_night": true, "skin": "auto", "character": "xiaoxi"}
var values: Dictionary = DEFAULTS.duplicate(true)

func set_value(key: String, value: Variant) -> void:
	if not DEFAULTS.has(key):
		return
	var clean: Variant = DEFAULTS[key]
	match key:
		"scale":
			if (value is float or value is int) and is_finite(float(value)):
				clean = clampf(float(value), 0.6, 1.5)
		"max_fps":
			if value is int or value is float:
				if is_finite(float(value)):
					clean = clampi(int(value), 24, 120)
		"skin":
			if value in ["auto", "original", "native", "custom"]:
				clean = value
		"character":
			if value in ["xiaoxi", "ocean_demo"]:
				clean = value
		_:
			if value is bool:
				clean = value
	values[key] = clean
	changed.emit(key, clean)

func restore(data: Dictionary) -> void:
	values = DEFAULTS.duplicate(true)
	for key: String in DEFAULTS:
		set_value(key, data.get(key, DEFAULTS[key]))

func reset() -> void:
	restore({})
