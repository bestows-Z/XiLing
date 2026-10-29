extends RefCounted
## Priority state machine: dragging > player action > autonomous action > idle.
## No networking or language model is involved; all decisions happen locally.

signal action_changed(action: StringName)

const Mood = preload("res://scripts/pet_mood.gd")
const DURATIONS: Dictionary = {
	&"idle": 0.0, &"wave": 2.2, &"jump": 1.2, &"dance": 4.0,
	&"sleep": 18.0, &"curious": 3.0, &"drag": 0.0,
	&"feed": 2.8, &"pet": 1.8,
}
const PLAYER_COOLDOWN: float = 0.4

var mood = Mood.new()
var action: StringName = &"idle"
var action_elapsed: float = 0.0
var action_duration: float = 0.0
var autonomous: bool = true
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _decision_timer: float = 5.0
var _interaction_cooldown: float = 0.0
var _player_active: bool = false
var _dragging: bool = false


func _init() -> void:
	_rng.randomize()


func seed_rng(value: int) -> void:
	_rng.seed = value
	_decision_timer = _rng.randf_range(4.0, 8.0)


func tick(delta: float) -> void:
	if not is_finite(delta) or delta <= 0.0:
		return
	# A stalled frame must not run a huge decision loop or apply hours of decay.
	var step: float = minf(delta, 60.0)
	_interaction_cooldown = maxf(_interaction_cooldown - step, 0.0)
	mood.tick(step, action == &"sleep")
	action_elapsed += step
	if _dragging:
		return
	if action != &"idle":
		if action_elapsed >= action_duration:
			_enter(&"idle", false)
		return
	_decision_timer -= step
	if autonomous and _decision_timer <= 0.0:
		_choose_action()


func request(action_name: StringName, player: bool = true) -> bool:
	if not DURATIONS.has(action_name) or action_name == &"drag":
		return false
	if _dragging or (not player and _player_active):
		return false
	if player and _interaction_cooldown > 0.0:
		return false
	if player:
		_interaction_cooldown = PLAYER_COOLDOWN
		mood.reward(action_name)
	_enter(action_name, player)
	return true


func interact(kind: StringName) -> bool:
	if kind == &"wake":
		return request(&"wave")
	return request(kind)


func set_dragging(active: bool) -> void:
	if _dragging == active:
		return
	_dragging = active
	_enter(&"drag" if active else &"idle", active)
	if not active:
		_interaction_cooldown = PLAYER_COOLDOWN


func progress() -> float:
	if action_duration <= 0.0 or not is_finite(action_elapsed):
		return 0.0
	return clampf(action_elapsed / action_duration, 0.0, 1.0)


func _enter(next_action: StringName, player: bool) -> void:
	action = next_action
	action_elapsed = 0.0
	action_duration = float(DURATIONS[next_action])
	_player_active = player and next_action != &"idle"
	if next_action == &"idle":
		_decision_timer = _rng.randf_range(4.0, 8.0)
	action_changed.emit(action)


func _choose_action() -> void:
	if mood.energy < 25.0:
		_enter(&"sleep", false)
		return
	var roll: float = _rng.randf()
	if roll < 0.25:
		_enter(&"curious", false)
	elif roll < 0.48:
		_enter(&"wave", false)
	elif roll < 0.66 and mood.energy > 40.0:
		_enter(&"dance", false)
	elif roll < 0.82 and mood.energy > 35.0:
		_enter(&"jump", false)
	elif roll < 0.90:
		_enter(&"sleep", false)
	else:
		_enter(&"idle", false)


func snapshot() -> Dictionary:
	return {"mood": mood.snapshot(), "autonomous": autonomous}


func restore(data: Dictionary) -> void:
	var saved_mood: Variant = data.get("mood", {})
	if saved_mood is Dictionary:
		mood.restore(saved_mood)
	var saved_autonomous: Variant = data.get("autonomous", true)
	autonomous = saved_autonomous if saved_autonomous is bool else true
	# Never restore an interrupted drag or an animation's stale timer.
	_dragging = false
	_interaction_cooldown = 0.0
	_enter(&"idle", false)


func reset() -> void:
	mood.restore({})
	autonomous = true
	_dragging = false
	_interaction_cooldown = 0.0
	_enter(&"idle", false)
