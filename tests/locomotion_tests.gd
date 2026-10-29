extends SceneTree
const Locomotion = preload("res://scripts/pet_locomotion.gd")
var checks: int = 0
var failures: int = 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func _initialize() -> void:
	var endpoints: Array[float] = []
	for fps: int in [24, 60, 120]:
		var walk = Locomotion.new()
		walk.begin(Vector2(300, 200), Rect2(0, 0, 1000, 500), 1.0)
		for index: int in range(fps * 4): walk.advance(1.0 / fps)
		endpoints.append(walk.position.x)
		check(walk.distance > 100.0 and walk.position.y == 200, "walking changes horizontal position at %d FPS" % fps)
	check(absf(endpoints[0] - endpoints[2]) < 1.0, "24 and120 FPS traverse the same distance")
	var edge = Locomotion.new()
	edge.begin(Vector2(98, 40), Rect2(0, 0, 100, 100), 1)
	for index: int in range(60): edge.advance(1.0 / 60)
	check(edge.position.x < 98 and edge.direction < 0, "reaching the screen edge reverses direction instead of walking in place")
	check(edge.position.y == 40, "walking never changes the vertical window position")
	edge.stop()
	var stopped: Vector2 = edge.position
	edge.advance(1)
	check(edge.position == stopped, "paused walking has no hidden movement")
	edge.begin(Vector2(50, 40), Rect2(0, 0, 0, 100), 1)
	edge.advance(2)
	check(edge.position.x == 0 and not edge.active, "no horizontal room gives a stable stationary result")
	check(edge.pause_for_hover(true, true), "hovering latches a pause")
	check(edge.pause_for_hover(false, true), "a changed alpha silhouette cannot restart walking under a stationary pointer")
	check(not edge.pause_for_hover(false, false), "leaving the window releases the hover pause")
	print("Locomotion tests: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
