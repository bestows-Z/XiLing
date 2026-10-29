extends RefCounted
const Brain = preload("res://scripts/pet_brain.gd")
const Settings = preload("res://scripts/pet_settings.gd")
const Storage = preload("res://scripts/save_manager.gd")
var brain = Brain.new()
var settings = Settings.new()
var storage = Storage.new()
var profile: Resource
var position: Variant = null
var statistics: Dictionary = {"interactions": 0, "pets": 0, "feeds": 0, "drags": 0, "bubbles": 0}

func load_state(test_mode: bool) -> void:
	var data: Dictionary = {} if test_mode else storage.load_state()
	brain.restore(data)
	var saved: Variant = data.get("settings", {})
	settings.restore(saved if saved is Dictionary else {})
	if not data.has("settings"):
		settings.set_value("autonomous", brain.autonomous)
	position = data.get("window_position")
	var stats: Variant = data.get("statistics", {})
	if stats is Dictionary:
		for key: String in statistics:
			var value: Variant = stats.get(key, 0)
			statistics[key] = clampi(int(value), 0, 1000000000) if value is int else 0
	load_profile()

func load_profile() -> void:
	var path: String = "res://characters/demo.tres" if settings.values["character"] == "ocean_demo" else "res://characters/xiaoxi.tres"
	profile = load(path)
	brain.personality = profile.personality.duplicate(true)

func record(action: StringName) -> void:
	statistics["interactions"] = mini(1000000000, int(statistics["interactions"]) + 1)
	var key: String = {&"pet": "pets", &"feed": "feeds", &"drag": "drags", &"bubbles": "bubbles"}.get(action, "")
	if not key.is_empty(): statistics[key] = mini(1000000000, int(statistics[key]) + 1)

func save_state(window_position: Vector2i) -> Error:
	var data: Dictionary = brain.snapshot()
	data["settings"] = settings.values.duplicate(true)
	data["statistics"] = statistics.duplicate()
	data["window_position"] = window_position
	return storage.save_state(data)
