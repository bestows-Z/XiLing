extends RefCounted
const Locomotion = preload("res://scripts/pet_locomotion.gd")
## Owns OS window behavior; never manipulates the pet's pose.

var window: Window
var dragging: bool = false
var native_drag: bool = false
var moved: bool = false
var enabled: bool = true
var wayland: bool = false
var suppressed: bool = false
var _press_mouse: Vector2i
var _press_window: Vector2i
var _outline_timer: float = 0.0
var _local_travel: Vector2 = Vector2.ZERO
var locomotion = Locomotion.new()
var embedded: bool = false

func setup(target: Window, test_mode: bool = false) -> void:
	window = target
	enabled = DisplayServer.get_name() != "headless" and not test_mode
	wayland = DisplayServer.get_name().to_lower() == "wayland"
	embedded = Engine.is_embedded_in_editor()
	if not enabled:
		return
	window.transparent = true
	window.transparent_bg = true
	window.borderless = true
	window.unresizable = true
	if not wayland:
		window.always_on_top = true
		keep_on_screen()

func begin_drag() -> void:
	if not enabled:
		return
	dragging = true
	moved = false
	native_drag = false
	_local_travel = Vector2.ZERO
	_press_mouse = DisplayServer.mouse_get_position()
	_press_window = window.position

func update_drag() -> bool:
	if not dragging:
		return false
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		end_drag()
		return false
	if wayland:
		return moved
	var distance: Vector2i = DisplayServer.mouse_get_position() - _press_mouse
	# 只把按下之后收到的实际移动事件作为拖动手势；全局坐标可受 DPI/光标跳转影响。
	if not moved and _local_travel.length() < 7.0:
		return false
	moved = true
	if DisplayServer.has_feature(DisplayServer.FEATURE_WINDOW_DRAG):
		if not native_drag:
			native_drag = true
			window.start_drag()
	else:
		window.position = _press_window + distance
	return true

func handle_motion(relative: Vector2) -> void:
	if not dragging or native_drag:
		return
	_local_travel += relative
	if wayland and _local_travel.length() >= 7.0 and DisplayServer.has_method("window_start_drag"):
		moved = true
		native_drag = true
		DisplayServer.call("window_start_drag", window.get_window_id())

func end_drag() -> bool:
	var was_moved: bool = moved
	dragging = false
	native_drag = false
	if enabled and not wayland:
		keep_on_screen()
	return was_moved

func can_roam() -> bool:
	return enabled and not wayland and not embedded and not suppressed and not dragging

func step_roam(delta: float, direction: float) -> float:
	if not can_roam(): return 0.0
	if not locomotion.active:
		var screen: int = DisplayServer.get_screen_from_rect(Rect2i(window.position, window.size))
		if screen < 0: screen = DisplayServer.get_primary_screen()
		var area: Rect2i = DisplayServer.screen_get_usable_rect(screen)
		var limits: Rect2 = Rect2(Vector2(area.position), Vector2(maxi(0, area.size.x - window.size.x), maxi(0, area.size.y - window.size.y)))
		locomotion.begin(Vector2(window.position), limits, direction)
	var before: Vector2i = window.position
	var before_distance: float = locomotion.distance
	var target: Vector2i = locomotion.advance(delta)
	if target != before: window.position = target
	# 步态使用连续路径；OS窗口的整数/Retina取整由画面内的小数偏移补偿。
	return locomotion.distance-before_distance

func stop_roam() -> void:
	locomotion.stop()

func keep_on_screen() -> void:
	if not enabled or wayland:
		return
	var screen: int = DisplayServer.get_screen_from_rect(Rect2i(window.position, window.size))
	if screen < 0:
		screen = DisplayServer.get_primary_screen()
	var area: Rect2i = DisplayServer.screen_get_usable_rect(screen)
	if area.size.x <= 0 or area.size.y <= 0:
		return
	var max_position: Vector2i = area.end - window.size
	window.position = Vector2i(
		clampi(window.position.x, area.position.x, maxi(area.position.x, max_position.x)),
		clampi(window.position.y, area.position.y, maxi(area.position.y, max_position.y))
	)

func update_outline(points: PackedVector2Array, delta: float, modal: bool = false) -> void:
	if not enabled or wayland or suppressed:
		return
	_outline_timer -= delta
	if _outline_timer > 0.0 and not modal:
		return
	_outline_timer = 0.04
	# Modal UI must remain clickable; empty means the whole window receives input.
	if modal or dragging:
		window.mouse_passthrough_polygon = PackedVector2Array()
	elif points.size() >= 3:
		window.mouse_passthrough_polygon = points

func set_topmost(active: bool) -> void:
	if enabled and not wayland:
		window.always_on_top = active

func set_scale(value: float) -> void:
	if not enabled:
		return
	window.content_scale_size = Vector2i(360, 480)
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.size = Vector2i(Vector2(360, 480) * clampf(value, 0.6, 1.5))
	keep_on_screen()

func restore_position(value: Variant) -> void:
	if enabled and not wayland and value is Vector2i:
		window.position = value
		keep_on_screen()

func set_hidden(value: bool) -> void:
	suppressed = value
	if not enabled or wayland: return
	window.mouse_passthrough = value
	window.unfocusable = value
	if value:
		# 主窗口不能 hide；空绘制配合窗外输入区域实现隐藏和全穿透。
		window.mouse_passthrough_polygon = PackedVector2Array([Vector2(-10, -10), Vector2(-9, -10), Vector2(-9, -9)])
	else:
		_outline_timer = 0.0
