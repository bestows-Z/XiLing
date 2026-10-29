extends RefCounted
## 决策评分 + 有限状态；拖动 > 玩家 > 自主。时钟可注入以便测试。
signal action_changed(action: StringName)
const Mood = preload("res://scripts/pet_mood.gd")
const DURATIONS: Dictionary = {&"idle": 0.0, &"wave": 3.0, &"jump": 1.6, &"dance": 4.8, &"sleep": 30.0, &"curious": 3.0, &"drag": 0.0, &"feed": 3.8, &"pet": 3.2, &"look": 3.0, &"happy": 2.5, &"angry": 2.0, &"surprised": 1.8, &"shy": 2.5, &"crouch": 1.8, &"takeoff": 0.7, &"land": 0.7, &"walk": 6.5, &"turn": 2.0, &"sit": 8.0, &"yawn": 3.0, &"wake": 3.0, &"stretch": 4.8, &"groom": 4.8}
const PLAYER_COOLDOWN: float = 0.4
var mood = Mood.new()
var action: StringName = &"idle"
var action_elapsed: float = 0.0
var action_duration: float = 0.0
var autonomous: bool = true
var proactive: bool = true
var quiet_night: bool = true
var clock_hour: int = -1
var since_interaction: float = 0.0
var personality: Dictionary = {"playfulness": 0.7, "sociability": 0.6, "curiosity": 0.7}
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _decision_timer: float = 35.0
var _interaction_cooldown: float = 0.0
var _player_active: bool = false
var _dragging: bool = false
var _recent: Array[StringName] = []
var _cooldowns: Dictionary = {}
var _resume: StringName = &"idle"
var _rapid_reaction_timer: float = 0.0
var goal: StringName = &"company"
var thought: String = "先看看你在做什么，再自己玩一会儿。"
var roam_direction: float = 1.0
var _plan: Array[StringName] = []
var _autonomous_activity: bool = false
var activity_rate: String = "natural"
var activity_serial: int = 0

func is_autonomous_activity() -> bool:
	return _autonomous_activity and not _dragging

func _init() -> void:
	_rng.randomize()

func seed_rng(value: int) -> void:
	_rng.seed = value
	_schedule_decision()

func tick(delta: float) -> void:
	if not is_finite(delta) or delta <= 0.0:
		return
	var step: float = minf(delta, 60.0)
	_interaction_cooldown = maxf(_interaction_cooldown - step, 0.0)
	since_interaction += step
	_rapid_reaction_timer = maxf(0.0, _rapid_reaction_timer - step)
	for key: StringName in _cooldowns:
		_cooldowns[key] = maxf(0.0, float(_cooldowns[key]) - step)
	mood.tick(step, action == &"sleep")
	action_elapsed += step
	if _dragging:
		return
	if action != &"idle":
		if action_elapsed >= action_duration:
			if _autonomous_activity and autonomous and not _plan.is_empty():
				_enter(_plan.pop_front(), false)
			else:
				_plan.clear()
				_autonomous_activity = false
				_enter(&"idle", false)
		return
	if mood.energy < 15.0: _decision_timer = minf(_decision_timer, 3.0)
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
		_plan.clear()
		_autonomous_activity = false
		goal = &"company"
		thought = "你来找我啦，先陪你玩！"
		_interaction_cooldown = PLAYER_COOLDOWN
		since_interaction = 0.0
		mood.reward(action_name)
	_enter(action_name, player)
	return true

func interact(kind: StringName) -> bool:
	if kind == &"surprised":
		if _dragging or _rapid_reaction_timer > 0.0: return false
		# 连点手势是完整事件，可打断普通单击冷却，但不能反复刷屏。
		_interaction_cooldown = 0.0
		_rapid_reaction_timer = 2.0
	return request(kind)

func set_dragging(active: bool) -> void:
	if _dragging == active:
		return
	if active:
		_plan.clear()
		_autonomous_activity = false
		_resume = action if action in [&"sleep", &"sit"] else &"idle"
	_dragging = active
	_enter(&"drag" if active else _resume, active)
	if not active:
		_resume = &"idle"
		_interaction_cooldown = PLAYER_COOLDOWN

func progress() -> float:
	return clampf(action_elapsed / action_duration, 0.0, 1.0) if action_duration > 0.0 and is_finite(action_elapsed) else 0.0

func _enter(next_action: StringName, player: bool) -> void:
	action = next_action
	action_elapsed = 0.0
	action_duration = float(DURATIONS[next_action])
	_player_active = player and next_action != &"idle"
	if next_action == &"idle":
		_schedule_decision()
	else:
		_cooldowns[next_action] = 180.0 if next_action in [&"jump", &"dance", &"stretch"] else 90.0
		_recent.append(next_action)
		if _recent.size() > 2:
			_recent.pop_front()
		if next_action in [&"angry", &"surprised", &"shy", &"happy"]:
			mood.expression = next_action
			mood.expression_time = action_duration
		if not player and next_action in [&"jump", &"dance", &"walk"]:
			mood.energy -= 2.0
	action_changed.emit(action)

func behavior_scores() -> Dictionary:
	var hour: int = clock_hour if clock_hour >= 0 else int(Time.get_time_dict_from_system()["hour"])
	var night: bool = quiet_night and (hour >= 23 or hour < 7)
	if mood.energy < 25.0:
		return {&"sleep": 100.0}
	var scores: Dictionary = {&"idle": 12.0, &"look": 10.0 + mood.curiosity * 0.15, &"sit": 7.0, &"groom": 10.0, &"stretch": 7.0, &"yawn": 5.0 + (100.0 - mood.energy) * 0.2}
	if night:
		scores[&"sleep"] = 60.0
		scores[&"sit"] = 25.0
	elif proactive:
		scores[&"curious"] = 10.0 + mood.boredom * 0.3 + _personality_value("curiosity") * 20.0
		scores[&"wave"] = 5.0 + _personality_value("sociability") * 20.0
		if mood.energy > 40.0:
			scores[&"dance"] = maxf(0.0, mood.joy - 45.0) * _personality_value("playfulness")
			scores[&"walk"] = 8.0 + mood.boredom * 0.15
			scores[&"jump"] = _personality_value("playfulness") * 15.0
	for key: StringName in scores.keys():
		if key != &"idle" and (_recent.has(key) or float(_cooldowns.get(key, 0.0)) > 0.0):
			scores.erase(key)
	return scores

func decision_delay_range() -> Vector2:
	var quiet: bool = since_interaction > 120.0
	match activity_rate:
		"quiet": return Vector2(60, 120) if quiet else Vector2(35, 65)
		"lively": return Vector2(25, 45) if quiet else Vector2(15, 25)
	return Vector2(45, 90) if quiet else Vector2(25, 45)

func _schedule_decision() -> void:
	var interval: Vector2 = decision_delay_range()
	_decision_timer = _rng.randf_range(interval.x, interval.y)

func set_activity_rate(value: String) -> void:
	if value == activity_rate or value not in ["quiet", "natural", "lively"]: return
	activity_rate = value
	_schedule_decision()

func _personality_value(key: String) -> float:
	var value: Variant = personality.get(key, 0.5)
	return clampf(float(value), 0.0, 1.0) if (value is float or value is int) and is_finite(float(value)) else 0.5

func _choose_action() -> void:
	var scores: Dictionary = behavior_scores()
	var total: float = 0.0
	for value: float in scores.values(): total += value
	var roll: float = _rng.randf() * total
	for candidate: StringName in scores:
		roll -= float(scores[candidate])
		if roll <= 0.0:
			_start_activity(candidate)
			return
	_enter(&"idle", false)

func _start_activity(candidate: StringName) -> void:
	_plan.clear()
	activity_serial += 1
	_autonomous_activity = candidate != &"idle"
	roam_direction = -1.0 if _rng.randf() < 0.5 else 1.0
	match candidate:
		&"sleep", &"yawn", &"sit":
			goal = &"rest"
			thought = "有点困了，找个舒服的地方眯一会儿。" if mood.energy < 40 else "现在很安静，坐下来歇一会儿。"
			if candidate == &"sleep":
				_plan.assign([&"sit", &"sleep", &"wake"])
				candidate = &"yawn"
		&"jump":
			goal = &"play"
			thought = "精力满满！蹲一下，再跳起来～"
			# jump 的精绘动画本身已经包含下蹲、腾空与落地，避免重复起落。
			_plan.assign([&"happy"])
		&"walk", &"curious":
			goal = &"explore"
			thought = "有点无聊，去旁边逛逛有什么新发现。"
			_plan.assign([&"walk", &"look"])
			candidate = &"curious"
		&"groom":
			goal = &"observe"
			thought = "整理一下头发和小鲸鱼发夹。"
		&"stretch":
			goal = &"rest"
			thought = "伸个懒腰，放松一下肩膀。"
		&"dance":
			goal = &"play"
			thought = "今天心情不错，自己跳一小段舞吧！"
			_plan.assign([&"happy"])
		&"wave":
			goal = &"company"
			thought = "想和你打个招呼，忙的话我就自己玩。"
		_:
			goal = &"observe"
			thought = "看看周围，再想想接下来做什么。"
	_enter(candidate, false)

func snapshot() -> Dictionary:
	return {"mood": mood.snapshot(), "autonomous": autonomous, "goal": String(goal), "thought": thought}

func restore(data: Dictionary) -> void:
	if data.get("mood", {}) is Dictionary:
		mood.restore(data.get("mood", {}))
	autonomous = data.get("autonomous", true) if data.get("autonomous", true) is bool else true
	_dragging = false
	_interaction_cooldown = 0.0
	_rapid_reaction_timer = 0.0
	_recent.clear()
	_cooldowns.clear()
	_plan.clear()
	_autonomous_activity = false
	var saved_goal: Variant = data.get("goal", "company")
	goal = StringName(saved_goal) if saved_goal in ["company", "rest", "play", "explore", "observe"] else &"company"
	var saved_thought: Variant = data.get("thought", "先看看你在做什么，再自己玩一会儿。")
	thought = saved_thought.left(100) if saved_thought is String else "先看看你在做什么，再自己玩一会儿。"
	since_interaction = 0.0
	_enter(&"idle", false)

func reset() -> void:
	mood.restore({})
	restore({})
