extends SceneTree

const Brain = preload("res://scripts/pet_brain.gd")
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	_test_priority_and_cooldown()
	_test_needs_and_persistence()
	_test_autonomous_decisions()
	_test_bad_time()
	print("Brain tests: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)


func _test_priority_and_cooldown() -> void:
	var brain = Brain.new()
	check(brain.request(&"jump"), "player can start a jump")
	check(not brain.request(&"dance"), "repeated player input is cooled down")
	check(not brain.request(&"wave", false), "autonomy cannot interrupt a player action")
	brain.tick(0.5)
	check(brain.progress() > 0.0 and brain.progress() < 1.0, "animation progress advances")
	check(brain.request(&"wave"), "player can interrupt after cooldown")
	brain.set_dragging(true)
	check(brain.action == &"drag", "drag takes priority")
	check(not brain.interact(&"feed"), "player action cannot interrupt drag")
	brain.tick(20.0)
	check(brain.action == &"drag", "drag does not expire")
	brain.set_dragging(false)
	check(brain.action == &"idle", "drag release returns to idle")
	brain.tick(1.0)
	check(not brain.request(&"missing"), "unknown actions are rejected")
	check(not brain.request(&"drag"), "drag must be entered through lifecycle API")


func _test_needs_and_persistence() -> void:
	var brain = Brain.new()
	brain.autonomous = false
	brain.mood.energy = 5.0
	brain.request(&"sleep")
	brain.tick(10.0)
	check(brain.mood.energy > 25.0, "sleep restores energy")
	check(brain.interact(&"wake") and brain.action == &"wake", "player can wake a sleeping pet")
	brain.tick(3.0)
	brain.interact(&"feed")
	check(brain.mood.energy > 30.0, "feeding restores energy")
	brain.restore({"mood": {"joy": 999.0, "energy": -9.0, "affection": NAN}, "autonomous": false})
	check(brain.mood.joy == 100.0 and brain.mood.energy == 0.0, "saved values are clamped")
	check(is_finite(brain.mood.affection), "non-finite saved values are rejected")
	check(brain.mood.label() == &"sleepy", "low energy changes mood label")
	var restored = Brain.new()
	restored.restore(brain.snapshot())
	check(restored.snapshot() == brain.snapshot(), "snapshot round trip")
	check(not restored.autonomous and restored.action == &"idle", "settings restore without stale actions")
	restored.restore({"mood": "bad", "autonomous": "false"})
	check(restored.autonomous, "invalid setting type uses safe default")
	brain.reset()
	check(brain.mood.energy == 80.0 and brain.autonomous, "reset restores initial values")


func _test_autonomous_decisions() -> void:
	var brain = Brain.new()
	brain.seed_rng(17)
	brain.clock_hour = 12
	var seen: Dictionary = {}
	for index in range(1200):
		brain.tick(0.5)
		seen[brain.action] = true
	check(seen.size() >= 4 and seen.has(&"idle") and seen.has(&"look"), "seeded autonomy reaches several actions")
	var tired = Brain.new()
	tired.mood.energy = 1.0
	tired.tick(8.0)
	check(tired.action == &"sleep", "exhausted pet autonomously rests")
	var paused = Brain.new()
	paused.autonomous = false
	paused.tick(60.0)
	check(paused.action == &"idle", "autonomy can be disabled")


func _test_bad_time() -> void:
	var brain = Brain.new()
	brain.request(&"jump")
	brain.tick(NAN)
	brain.tick(INF)
	brain.tick(-2.0)
	check(brain.action_elapsed == 0.0, "invalid delta never corrupts state")
	brain.tick(1e20)
	check(is_finite(brain.mood.energy) and brain.action == &"idle", "long frames complete safely")
