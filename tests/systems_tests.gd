extends SceneTree
const Settings = preload("res://scripts/pet_settings.gd")
const Storage = preload("res://scripts/save_manager.gd")
const Brain = preload("res://scripts/pet_brain.gd")
const Interaction = preload("res://scripts/pet_interaction.gd")
const Effects = preload("res://scripts/pet_effects.gd")
var checks: int = 0
var failures: int = 0
var events: Array[StringName] = []
func check(value: bool, text: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(text)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var settings = Settings.new()
	settings.restore({"scale": NAN, "topmost": "yes", "max_fps": -9, "character": "../../bad", "skin": "none"})
	check(settings.values["scale"] == 1.0 and settings.values["topmost"] == true, "malformed settings have safe defaults")
	check(settings.values["max_fps"] == 24 and settings.values["character"] == "xiaoxi", "fps and profile values are constrained")
	settings.set_value("scale", 2.0)
	check(settings.values["scale"] == 1.5, "scale capped")
	settings.reset()
	check(settings.values == Settings.DEFAULTS, "settings reset")
	var save_path: String = "user://xiling-test-%d.cfg" % Time.get_ticks_usec()
	var storage = Storage.new(save_path)
	check(storage.load_state().is_empty(), "first run without save")
	var payload: Dictionary = {"settings": settings.values, "window_position": Vector2i(-123, 500), "statistics": {"pets": 4}}
	check(storage.save_state(payload) == OK, "initial save")
	check(storage.load_state() == payload, "settings, negative monitor coordinates and counters round trip")
	check(storage.save_state({"version": 2}) == OK, "second save and backup")
	var corrupt: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
	corrupt.store_string("this is not a config [")
	corrupt.close()
	check(storage.load_state() == payload and storage.recovered_backup, "corrupt current save recovers backup")
	var typed_bad: ConfigFile = ConfigFile.new()
	typed_bad.set_value("pet", "state", "broken")
	typed_bad.save(save_path)
	check(storage.load_state() == payload, "wrong state type recovers good backup")
	check(storage.save_state({"version": 3}) == OK, "save after recovery")
	var preserved: ConfigFile = ConfigFile.new()
	preserved.load(save_path + ".bak")
	check(preserved.get_value("pet", "state") == payload, "bad primary never overwrites good backup")
	var bad = Storage.new("user://nonexistent-%d/state.cfg" % Time.get_ticks_usec())
	check(bad.save_state(payload) != OK, "save failure returns an error without crashing")
	for suffix: String in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path + suffix))
	var brain = Brain.new()
	brain.clock_hour = 12
	brain.mood.energy = 90
	brain.mood.joy = 90
	brain.mood.affection = 60
	brain.mood.boredom = 90
	check(brain.behavior_scores().has(&"dance"), "happy energetic daytime includes play")
	brain.clock_hour = 1
	check(brain.behavior_scores().has(&"sleep") and not brain.behavior_scores().has(&"dance"), "night prioritizes quiet rest")
	brain.clock_hour = 12
	brain.proactive = false
	check(not brain.behavior_scores().has(&"wave"), "proactive permission filters attention actions")
	brain.proactive = true
	brain.request(&"dance")
	brain.tick(5)
	check(not brain.behavior_scores().has(&"dance"), "recent action cannot immediately repeat")
	var previous_affection: float = brain.mood.affection
	brain.tick(60)
	check(brain.mood.affection == previous_affection, "absence never decreases affection")
	brain.autonomous = false
	brain.tick(60)
	brain.request(&"sleep")
	brain.set_dragging(true)
	brain.set_dragging(false)
	check(brain.action == &"sleep", "rest resumes after interrupted drag")
	var input = Interaction.new()
	input.action_requested.connect(func(action: StringName) -> void: events.append(action))
	input.click(false)
	input.tick(0.1)
	input.click(true)
	input.tick(0.5)
	check(events == [&"wave"], "double click emits one wave without delayed pet")
	events.clear()
	for index: int in range(6):
		input.motion(Vector2(45 if index % 2 == 0 else -45, 0), true, false)
	check(events == [&"pet"], "back-and-forth hover strokes produce one pet with cooldown")
	events.clear()
	for index: int in range(5): input.click(false)
	check(events.has(&"surprised"), "rapid clicks give a non-punishing surprised reaction")
	var integrated = Interaction.new()
	var reaction_brain = Brain.new()
	integrated.action_requested.connect(reaction_brain.interact)
	for double: bool in [false, true, false, true, false]:
		integrated.click(double)
		integrated.tick(0.1)
		reaction_brain.tick(0.1)
	check(reaction_brain.action == &"surprised", "rapid reaction reaches brain despite earlier double-click cooldown")
	check(not reaction_brain.interact(&"surprised"), "rapid reaction has its own cooldown")
	var game = Effects.new()
	root.add_child(game)
	game.start_game()
	check(game.playing and game.bubbles.size() == 6, "bubble session starts with six targets")
	var target: Vector2 = game.bubbles[0]["position"]
	check(game.pop_at(target) and game.score == 1 and game.bubbles.size() == 6, "bubble pop scores and respawns")
	check(not game.pop_at(Vector2(-100, -100)), "off-target clicks do not score")
	game._process(21.0)
	check(not game.playing and game.bubbles.is_empty(), "bubble session ends and releases targets")
	game.start_game()
	game.stop_game()
	check(not game.playing, "player can stop the game")
	game.queue_free()
	var profile: Resource = load("res://characters/demo.tres")
	check(profile.identifier == "ocean_demo" and profile.original_image.is_empty(), "replacement character example needs no image")
	print("Systems tests: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
