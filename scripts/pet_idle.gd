extends AnimatedSprite2D
## 场景协调器：行为、表现、输入、窗口、玩法与存档各自独立。
const Runtime = preload("res://scripts/pet_runtime.gd")
const Visual = preload("res://scripts/pet_visual.gd")
const Desktop = preload("res://scripts/desktop_window.gd")
const Menu = preload("res://scripts/pet_menu.gd")
const LocalSkin = preload("res://scripts/local_skin.gd")
const AnimationController = preload("res://scripts/pet_animation_controller.gd")
const Interaction = preload("res://scripts/pet_interaction.gd")
const Effects = preload("res://scripts/pet_effects.gd")
const Controls = preload("res://scripts/desktop_controls.gd")
var runtime = Runtime.new()
var brain = runtime.brain
var visual: Node2D
var desktop = Desktop.new()
var menu: CanvasLayer
var skin = LocalSkin.new()
var animator = AnimationController.new()
var interaction = Interaction.new()
var effects: Node2D
var controls: Node
var test_mode: bool = false
var _left_pending: bool = false
var _was_dragging: bool = false
var _double_click: bool = false
var _save_timer: float = 0.0
var _save_warning: bool = false
var _last_announced_activity: int = -1
var _single_click_wait: float:
	get: return interaction.pending_click

func _ready() -> void:
	test_mode = OS.get_cmdline_user_args().has("--test-mode") or DisplayServer.get_name() == "headless"
	runtime.load_state(test_mode)
	skin.configure(runtime.profile)
	visual = Visual.new()
	add_child(visual)
	animator.setup(self, visual, skin, runtime.profile)
	menu = Menu.new()
	add_child(menu)
	effects = Effects.new()
	get_parent().add_child.call_deferred(effects)
	controls = Controls.new()
	add_child(controls)
	controls.setup(get_window(), test_mode)
	controls.menu_requested.connect(_show_menu)
	controls.quit_requested.connect(_quit)
	controls.visibility_changed.connect(_set_hidden)
	menu.action_requested.connect(_interact)
	menu.skin_requested.connect(func(mode: StringName) -> void: runtime.settings.set_value("skin", String(mode)))
	menu.setting_changed.connect(runtime.settings.set_value)
	menu.reset_requested.connect(runtime.settings.reset)
	menu.hide_requested.connect(func() -> void: _cancel_drag(); effects.stop_game(); controls.hide_pet())
	menu.quit_requested.connect(_quit)
	interaction.action_requested.connect(_interact)
	effects.bubble_popped.connect(_bubble_popped)
	effects.game_finished.connect(func(score: int) -> void: menu.say("这次戳破了 %d 个泡泡！" % score, 4.0))
	desktop.setup(get_window(), test_mode)
	runtime.settings.changed.connect(_on_setting_changed)
	_apply_settings()
	desktop.restore_position(runtime.position)
	_select_skin(StringName(runtime.settings.values["skin"]))
	menu.configure_platform(desktop.wayland, controls.available)
	menu.set_character_name(runtime.profile.display_name)
	get_window().close_requested.connect(_quit)
	get_window().focus_exited.connect(_cancel_drag)
	get_window().dpi_changed.connect(func() -> void: desktop.keep_on_screen())
	brain.action_changed.connect(_on_action_changed)
	menu.say("小汐来啦！右键打开菜单 · 空格跳跃", 5.0)
	_update_visual()

func _process(delta: float) -> void:
	var step: float = clampf(delta, 0.0, 0.25)
	brain.tick(step)
	interaction.tick(step)
	if _left_pending:
		if desktop.update_drag():
			if not _was_dragging:
				interaction.cancel()
				brain.set_dragging(true)
				runtime.record(&"drag")
				_was_dragging = true
		elif not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_release_drag()
	_update_roaming(step)
	animator.tick(step * runtime.profile.animation_speed, brain)
	desktop.update_outline(_window_outline(), step, menu.is_open())
	_save_timer += step
	if _save_timer >= 10.0:
		_save_timer = 0.0
		_save_state()
		menu.refresh(brain.snapshot())

func _update_roaming(step: float) -> void:
	var inside_window: bool = get_viewport_rect().grow(12.0).has_point(get_global_mouse_position())
	var hover_pause: bool = desktop.locomotion.pause_for_hover(is_mouse_on_pet(), inside_window)
	var allowed: bool = brain.action == &"walk" and animator.enabled and runtime.settings.values["roaming"] and desktop.can_roam() and not menu.is_open() and not effects.playing and not controls.hidden and not hover_pause
	animator.walk_paused = not allowed
	if allowed:
		animator.walk_distance += desktop.step_roam(step, brain.roam_direction) / float(runtime.settings.values["scale"])
		animator.window_offset = Vector2(desktop.locomotion.position.x-get_window().position.x,0)/float(runtime.settings.values["scale"])
		brain.roam_direction = desktop.locomotion.direction
		animator.walk_direction = desktop.locomotion.direction
	else:
		desktop.stop_roam()
		animator.window_offset = Vector2.ZERO

func _update_visual() -> void:
	animator.apply(brain)

func _window_outline() -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	points.append_array(animator.transition.outline)
	var local_outline: PackedVector2Array = visual.get_outline() if skin.mode == &"native" else skin.outline
	if animator.rig != null and animator.rig.visible: local_outline = animator.rig.get_outline(local_outline)
	for point: Vector2 in local_outline:
		points.append(get_global_transform_with_canvas() * point)
	if effects != null:
		points.append_array(effects.input_points())
	if menu.hint.visible:
		var rect: Rect2 = menu.hint.get_global_rect().grow(3.0)
		points.append_array(PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]))
	if points.size() >= 3:
		points = Geometry2D.convex_hull(points)
	var final: Transform2D = get_viewport().get_final_transform()
	return final * points

func is_mouse_on_pet(viewport_point: Vector2 = Vector2.INF) -> bool:
	var point: Vector2 = to_local(get_global_mouse_position()) if viewport_point == Vector2.INF else get_global_transform_with_canvas().affine_inverse() * viewport_point
	if animator.rig != null and animator.rig.visible: return animator.rig.hit_test(point)
	return visual.hit_test(point) if skin.mode == &"native" else skin.hit_test(point)

func _unhandled_input(event: InputEvent) -> void:
	if controls.hidden: return
	if event is InputEventMouseMotion:
		if menu.is_open(): return
		if _left_pending: desktop.handle_motion(event.relative)
		interaction.motion(event.relative, is_mouse_on_pet(), _left_pending)
		return
	if not event is InputEventMouseButton: return
	if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and _left_pending:
		_release_drag()
		get_viewport().set_input_as_handled()
		return
	if not event.pressed or menu.is_open(): return
	if event.button_index == MOUSE_BUTTON_LEFT and effects.pop_at(event.position):
		interaction.cancel()
		get_viewport().set_input_as_handled()
		return
	if not is_mouse_on_pet(event.position): return
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			_left_pending = true
			_double_click = event.double_click
			if _double_click: interaction.cancel()
			desktop.begin_drag()
		MOUSE_BUTTON_RIGHT: _toggle_menu()
		_: return
	get_viewport().set_input_as_handled()

func _unhandled_key_input(event: InputEvent) -> void:
	if controls.hidden: return
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_M: _toggle_menu()
		KEY_ESCAPE:
			if effects.playing: effects.stop_game()
			elif menu.is_open(): menu.close()
			else: _toggle_menu()
		KEY_H: menu.say("轻点 / 来回抚摸 · 拖动搬家 · 右键菜单 · B 泡泡", 5.0)
		KEY_F: _interact(&"feed")
		KEY_D: _interact(&"dance")
		KEY_S: _interact(&"sleep")
		KEY_B: _interact(&"bubbles")
		KEY_SPACE: _interact(&"jump")
		KEY_A: runtime.settings.set_value("autonomous", not brain.autonomous)
		_: return
	get_viewport().set_input_as_handled()

func _release_drag() -> void:
	if not _left_pending: return
	var moved: bool = desktop.end_drag() or _was_dragging
	_left_pending = false
	_was_dragging = false
	if moved: brain.set_dragging(false)
	if not moved: _queue_click(_double_click)
	_double_click = false
	_save_state()

func _queue_click(double: bool) -> void:
	interaction.click(double)

func _cancel_drag() -> void:
	interaction.cancel()
	if not _left_pending: return
	_left_pending = false
	_was_dragging = false
	_double_click = false
	desktop.end_drag()
	brain.set_dragging(false)

func _interact(action: StringName) -> void:
	interaction.cancel()
	if action == &"bubbles":
		if effects.playing: effects.stop_game()
		else:
			effects.start_game()
			menu.say("点泡泡得分！B / Esc 随时结束", 5.0)
		return
	var chosen: StringName = &"wake" if action == &"sleep" and brain.action == &"sleep" else action
	if brain.interact(chosen):
		runtime.record(chosen)
		if chosen in [&"pet", &"feed"]: effects.love(Vector2(180, 120))
		_save_state()
		menu.refresh(brain.snapshot())

func _bubble_popped() -> void:
	runtime.record(&"bubbles")
	brain.mood.reward(&"bubbles")
	brain.since_interaction = 0.0

func trigger_reaction() -> void:
	_interact(&"jump")

func _on_action_changed(action: StringName) -> void:
	menu.refresh(brain.snapshot())
	if not brain.proactive and brain.since_interaction > 1.0: return
	if brain.is_autonomous_activity() and action != &"idle":
		if _last_announced_activity != brain.activity_serial:
			_last_announced_activity = brain.activity_serial
			menu.say(brain.thought, 5.0)
		return
	var words: Dictionary = {&"wave": ["嗨，今天也一起加油！", "海风给你捎来一声问好～"], &"jump": "嘿咻！", &"dance": "跟着海浪摇一摇～", &"sleep": "我眯一会儿……", &"wake": "睡醒啦～", &"curious": "在忙什么呀？", &"feed": ["谢谢，能量补充中！", "啊呜，收到小点心啦～"], &"pet": ["嘿嘿，好舒服～", "再摸摸头嘛～", "小汐收到你的关心啦！"], &"drag": "一起搬个家～", &"surprised": "哇，好多小点点！"}
	if words.has(action):
		var value: Variant = words[action]
		menu.say(value.pick_random() if value is Array else value)

func _set_hidden(value: bool) -> void:
	_cancel_drag()
	effects.stop_game()
	get_parent().visible = not value
	menu.suspended = value
	menu.close()
	if value: menu.hint.hide()
	desktop.set_hidden(value)

func _show_menu() -> void:
	_cancel_drag()
	if not menu.is_open(): menu.toggle(brain.snapshot())
	desktop.update_outline(_window_outline(), 1.0, true)

func _toggle_menu() -> void:
	_cancel_drag()
	menu.toggle(brain.snapshot())
	desktop.update_outline(_window_outline(), 1.0, menu.is_open())

func _apply_settings() -> void:
	var values: Dictionary = runtime.settings.values
	brain.autonomous = values["autonomous"]
	brain.proactive = values["proactive"]
	brain.quiet_night = values["quiet_night"]
	brain.set_activity_rate(values["activity_rate"])
	animator.enabled = values["animations"]
	Engine.max_fps = values["max_fps"]
	desktop.set_topmost(values["topmost"])
	desktop.set_scale(values["scale"])
	menu.refresh_settings(values)

func _on_setting_changed(key: String, _value: Variant) -> void:
	if key == "character":
		runtime.load_profile()
		menu.set_character_name(runtime.profile.display_name)
		skin.configure(runtime.profile)
		animator.profile = runtime.profile
		runtime.settings.values["skin"] = "auto"
		_select_skin(&"auto")
	elif key == "skin": _select_skin(StringName(runtime.settings.values["skin"]))
	_apply_settings()
	_save_state()

func _select_skin(mode: StringName) -> void:
	if mode == &"auto": skin.mode = &"original" if skin.load_original() else &"native"
	elif mode == &"native": skin.mode = mode
	elif mode == &"original":
		if not skin.load_original():
			menu.say("本机没有原画资源，保留当前角色。", 4.0)
			runtime.settings.values["skin"] = String(skin.mode)
	elif mode == &"custom":
		if skin.load_custom(): skin.mode = mode
		else:
			menu.say("未找到有效的本地动画皮肤。", 4.0)
			runtime.settings.values["skin"] = String(skin.mode)
	menu.set_skin_mode(skin.mode)
	_update_visual()

func _save_state() -> void:
	if test_mode: return
	var error: Error = runtime.save_state(get_window().position)
	if error != OK and not _save_warning:
		_save_warning = true
		menu.say("本次未能保存，桌宠仍可继续使用。", 5.0)
	elif error == OK: _save_warning = false

func _quit() -> void:
	_save_state()
	get_tree().quit()
