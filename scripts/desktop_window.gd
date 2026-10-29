extends RefCounted
## Owns OS window behavior; never manipulates the pet's pose.

var window: Window
var dragging: bool = false
var native_drag: bool = false
var moved: bool = false
var enabled: bool = true
var wayland: bool = false
var _press_mouse: Vector2i
var _press_window: Vector2i
var _outline_timer: float = 0.0
var _local_travel: Vector2 = Vector2.ZERO

func setup(target: Window, test_mode: bool = false) -> void:
	window = target
	enabled = DisplayServer.get_name() != "headless" and not test_mode
	wayland = DisplayServer.get_name().to_lower() == "wayland"
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
	if not moved and Vector2(distance).length() < 5.0:
		return false
	moved = true
	window.position = _press_window + distance
	return true

func handle_motion(relative: Vector2) -> void:
	if not dragging or not wayland or native_drag:
		return
	_local_travel += relative
	if _local_travel.length() >= 5.0 and DisplayServer.has_method("window_start_drag"):
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
	if not enabled or wayland:
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
