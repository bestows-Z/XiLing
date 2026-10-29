extends AnimatedSprite2D
## Coordinates independent behavior, visual, desktop, menu and save adapters.
## Main/Pet remains AnimatedSprite2D for optional licensed frame-based skins.

const Brain = preload("res://scripts/pet_brain.gd")
const Visual = preload("res://scripts/pet_visual.gd")
const Desktop = preload("res://scripts/desktop_window.gd")
const Menu = preload("res://scripts/pet_menu.gd")
const LocalSkin = preload("res://scripts/local_skin.gd")
const SAVE_PATH: String = "user://pet_state.cfg"

var brain = Brain.new()
var visual: Node2D
var desktop = Desktop.new()
var menu: CanvasLayer
var skin = LocalSkin.new()
var elapsed: float = 0.0
var blinking: bool = false
var test_mode: bool = false
var _blink_timer: float = 3.0
var _blink_remaining: float = 0.0
var _save_timer: float = 0.0
var _left_pending: bool = false
var _was_dragging: bool = false
var _double_click: bool = false
var _single_click_wait: float = -1.0
var _base_position: Vector2
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	_base_position = position
	test_mode = OS.get_cmdline_user_args().has("--test-mode") or DisplayServer.get_name() == "headless"
	_rng.randomize()
	if not test_mode:
		_load_state()
	# Keep the user's original artwork as the local default.
	skin.load_original()
	visual = Visual.new()
	add_child(visual)
	menu = Menu.new()
	add_child(menu)
	menu.action_requested.connect(_interact)
	menu.skin_requested.connect(_select_skin)
	menu.autonomous_changed.connect(func(active: bool) -> void: brain.autonomous = active; _save_state())
	menu.topmost_changed.connect(desktop.set_topmost)
	menu.quit_requested.connect(_quit)
	desktop.setup(get_window(), test_mode)
	menu.configure_platform(desktop.wayland)
	menu.set_skin_mode(skin.mode)
	get_window().close_requested.connect(_quit)
	get_window().focus_exited.connect(_cancel_drag)
	brain.action_changed.connect(_on_action_changed)
	menu.say("汐灵来啦！右键跳跃 · M 打开菜单", 5.0)
	_update_visual()

func _process(delta: float) -> void:
	var step: float = minf(delta, 0.25)
	elapsed += step
	brain.tick(step)
	if _single_click_wait >= 0.0:
		_single_click_wait -= step
		if _single_click_wait < 0.0:
			_interact(&"pet")
	_update_blink(step)
	if _left_pending:
		if desktop.update_drag():
			if not _was_dragging:
				brain.set_dragging(true)
				_was_dragging = true
				_single_click_wait = -1.0
		elif not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_release_drag()
	_update_visual()
	var outline: PackedVector2Array = _window_outline()
	desktop.update_outline(outline, step, menu.is_open())
	_save_timer += step
	if _save_timer >= 10.0:
		_save_timer = 0.0
		_save_state()
		menu.refresh(brain.snapshot())

func _update_visual() -> void:
	if skin.mode == &"native":
		position = _base_position
		rotation = 0.0
		scale = Vector2.ONE
		visual.visible = true
		sprite_frames = null
		visual.set_pose(brain.action, brain.progress(), elapsed, brain.mood.label(), blinking)
	else:
		visual.visible = false
		rotation = 0.0
		var action_progress: float = brain.progress()
		if skin.frames != null and skin.mode == &"custom":
			var chosen: StringName = brain.action if skin.frames.has_animation(brain.action) and skin.frames.get_frame_count(brain.action) > 0 else &"idle"
			var count: int = skin.frames.get_frame_count(chosen)
			if skin.frames.get_animation_loop(chosen) and count > 0:
				action_progress = fposmod(brain.action_elapsed * skin.frames.get_animation_speed(chosen) / count, 1.0)
		skin.apply(self, brain.action, action_progress, blinking or brain.action == &"sleep")
		position = _base_position
		if skin.mode == &"original":
			position.y += sin(elapsed * 1.8) * 5.0
			scale *= 1.0 + sin(elapsed * 2.16) * 0.012
			# Static local artwork retains the legacy whole-sprite reaction only.
			var reaction: float = sin(brain.progress() * PI) if brain.action == &"jump" else 0.0
			position.y -= reaction * 18.0
			scale *= 1.0 + reaction * 0.06
			rotation = deg_to_rad(3.0) * reaction

func _update_blink(delta: float) -> void:
	if blinking:
		_blink_remaining -= delta
		if _blink_remaining <= 0.0:
			blinking = false
			_blink_timer = _rng.randf_range(3.0, 6.0)
	else:
		_blink_timer -= delta
		if _blink_timer <= 0.0:
			blinking = true
			_blink_remaining = 0.12

func _window_outline() -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var local_outline: PackedVector2Array = visual.get_outline() if skin.mode == &"native" else skin.outline
	var canvas: Transform2D = get_global_transform_with_canvas()
	for point: Vector2 in local_outline:
		points.append(canvas * point)
	if menu.hint.visible:
		var rect: Rect2 = menu.hint.get_global_rect().grow(3.0)
		points.append_array(PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]))
		points = Geometry2D.convex_hull(points)
	return points

func is_mouse_on_pet() -> bool:
	var point: Vector2 = to_local(get_global_mouse_position())
	if skin.mode == &"native":
		return visual.hit_test(point)
	return skin.hit_test(point)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and _left_pending:
		desktop.handle_motion(event.relative)
		return
	if not event is InputEventMouseButton:
		return
	if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and _left_pending:
		_release_drag()
		get_viewport().set_input_as_handled()
		return
	if not event.pressed or menu.is_open() or not is_mouse_on_pet():
		return
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			_left_pending = true
			_double_click = event.double_click
			if _double_click:
				_single_click_wait = -1.0
			desktop.begin_drag()
		MOUSE_BUTTON_RIGHT:
			if event.shift_pressed:
				_toggle_menu()
			else:
				_interact(&"jump")
		_:
			return
	get_viewport().set_input_as_handled()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_M:
			_toggle_menu()
		KEY_ESCAPE:
			if menu.is_open():
				menu.close()
			else:
				_toggle_menu()
		KEY_H:
			menu.say("轻点摸摸 · 拖动搬家 · 右键跳跃 · M 菜单", 5.0)
		KEY_F:
			_interact(&"feed")
		KEY_D:
			_interact(&"dance")
		KEY_S:
			_interact(&"sleep")
		KEY_SPACE:
			_interact(&"jump")
		KEY_A:
			brain.autonomous = not brain.autonomous
			menu.say("自主活动已开启" if brain.autonomous else "自主活动已暂停")
			_save_state()
		_:
			return
	get_viewport().set_input_as_handled()

func _release_drag() -> void:
	if not _left_pending:
		return
	var moved: bool = desktop.end_drag() or _was_dragging
	_left_pending = false
	_was_dragging = false
	brain.set_dragging(false)
	if not moved:
		_queue_click(_double_click)
	_double_click = false

func _queue_click(double: bool) -> void:
	if double:
		_single_click_wait = -1.0
		_interact(&"wave")
	else:
		# Wait for the second press before rewarding a single click.
		_single_click_wait = 0.45

func _cancel_drag() -> void:
	_single_click_wait = -1.0
	if not _left_pending:
		return
	_single_click_wait = -1.0
	_left_pending = false
	_was_dragging = false
	_double_click = false
	desktop.end_drag()
	brain.set_dragging(false)

func _interact(action: StringName) -> void:
	_single_click_wait = -1.0
	var chosen: StringName = action
	if chosen == &"sleep" and brain.action == &"sleep":
		chosen = &"wake"
	if brain.interact(chosen):
		_save_state()
		menu.refresh(brain.snapshot())

func trigger_reaction() -> void:
	_interact(&"jump")

func _on_action_changed(action: StringName) -> void:
	var words: Dictionary = {&"wave": "嗨，今天也一起加油！", &"jump": "嘿咻！", &"dance": "跟着海浪摇一摇～", &"sleep": "我眯一会儿……", &"curious": "在忙什么呀？", &"feed": "谢谢，能量补充中！", &"pet": "嘿嘿，好舒服～", &"drag": "一起搬个家～"}
	if words.has(action):
		menu.say(words[action])

func _toggle_menu() -> void:
	_cancel_drag()
	menu.toggle(brain.snapshot())
	desktop.update_outline(_window_outline(), 1.0, menu.is_open())

func _select_skin(mode: StringName) -> void:
	if mode == &"native":
		skin.mode = mode
	elif mode == &"original":
		if not skin.load_original():
			menu.close()
			menu.say("本机没有原画资源，继续使用当前角色。", 4.0)
			menu.set_skin_mode(skin.mode)
			return
	elif mode == &"custom":
		if not skin.load_custom():
			menu.close()
			menu.say("未找到可用的本地动画皮肤。", 4.0)
			menu.set_skin_mode(skin.mode)
			return
		skin.mode = mode
	menu.set_skin_mode(skin.mode)
	_update_visual()

func _save_state() -> void:
	if test_mode:
		return
	var config: ConfigFile = ConfigFile.new()
	config.set_value("pet", "state", brain.snapshot())
	config.save(SAVE_PATH)

func _load_state() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		var data: Variant = config.get_value("pet", "state", {})
		if data is Dictionary:
			brain.restore(data)

func _quit() -> void:
	_save_state()
	get_tree().quit()
