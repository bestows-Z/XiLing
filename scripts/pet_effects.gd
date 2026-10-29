extends Node2D
## 完整的 20 秒泡泡小游戏；所有特效由 Godot 绘制。
signal bubble_popped
signal game_finished(score: int)
var playing: bool = false
var remaining: float = 0.0
var score: int = 0
var bubbles: Array[Dictionary] = []
var hearts: Array[Dictionary] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	z_index = 10

func start_game() -> void:
	playing = true
	remaining = 20.0
	score = 0
	bubbles.clear()
	for index: int in range(6):
		_spawn()

func stop_game() -> void:
	if not playing:
		return
	playing = false
	bubbles.clear()
	game_finished.emit(score)
	queue_redraw()

func _spawn() -> void:
	bubbles.append({"position": Vector2(_rng.randf_range(35, 325), _rng.randf_range(180, 420)), "radius": _rng.randf_range(12, 20), "speed": _rng.randf_range(14, 30)})

func pop_at(point: Vector2) -> bool:
	for index: int in range(bubbles.size() - 1, -1, -1):
		var bubble: Dictionary = bubbles[index]
		if point.distance_to(bubble["position"]) <= float(bubble["radius"]) + 3.0:
			bubbles.remove_at(index)
			score += 1
			love(point)
			bubble_popped.emit()
			if playing:
				_spawn()
			return true
	return false

func love(point: Vector2) -> void:
	hearts.append({"position": point, "life": 1.2})

func input_points() -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for bubble: Dictionary in bubbles:
		for index: int in range(12):
			points.append((bubble["position"] as Vector2) + Vector2.from_angle(TAU * index / 12.0) * (float(bubble["radius"]) + 4.0))
	return points

func _process(delta: float) -> void:
	var had_visuals: bool = playing or not hearts.is_empty()
	if playing:
		remaining -= delta
		if remaining <= 0.0:
			stop_game()
		for bubble: Dictionary in bubbles:
			var point: Vector2 = bubble["position"]
			point.y -= float(bubble["speed"]) * delta
			if point.y < 65.0:
				point.y = 430.0
			bubble["position"] = point
	for index: int in range(hearts.size() - 1, -1, -1):
		hearts[index]["life"] = float(hearts[index]["life"]) - delta
		hearts[index]["position"] = (hearts[index]["position"] as Vector2) - Vector2(0, delta * 22.0)
		if float(hearts[index]["life"]) <= 0.0:
			hearts.remove_at(index)
	if had_visuals or playing or not hearts.is_empty():
		queue_redraw()

func _draw() -> void:
	for bubble: Dictionary in bubbles:
		var point: Vector2 = bubble["position"]
		var radius: float = bubble["radius"]
		draw_circle(point, radius, Color(0.5, 0.85, 1.0, 0.26))
		draw_arc(point, radius, 0, TAU, 32, Color("bceaff"), 2.0, true)
		draw_arc(point - Vector2(2, 2), radius * 0.65, PI, PI * 1.5, 12, Color.WHITE, 2.5, true)
	for heart: Dictionary in hearts:
		var point: Vector2 = heart["position"]
		var color: Color = Color(1.0, 0.48, 0.65, clampf(heart["life"], 0.0, 1.0))
		draw_circle(point + Vector2(-3, -2), 4, color)
		draw_circle(point + Vector2(3, -2), 4, color)
		draw_colored_polygon(PackedVector2Array([point + Vector2(-7, -1), point + Vector2(7, -1), point + Vector2(0, 8)]), color)
