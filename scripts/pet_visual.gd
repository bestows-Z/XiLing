extends Node2D
## Original procedural placeholder artwork. No raster or external art is required.
## Hit tests use the drawn polygons; the OS receives their enclosing convex hull.

const Poses = preload("res://scripts/pose_library.gd")
const INK := Color("274b6e")
const BLUE := Color("629dcc")
const PALE := Color("e6f6ff")
const HAIR := Color("78b9df")
const SKIN := Color("ffe1d8")

var pose: Dictionary = {}
var _shapes: Array[Dictionary] = []
var _outline := PackedVector2Array()
var _edge_points := PackedVector2Array()
var _action: StringName = &"idle"
var _mood: StringName = &"content"
var _blinking: bool = false


func _ready() -> void:
	if pose.is_empty():
		set_pose(&"idle", 0.0, 0.0, &"content", false)


func set_pose(action: StringName, progress: float, elapsed: float, mood: StringName, blinking: bool) -> void:
	_action = action
	_mood = mood
	_blinking = blinking
	pose = Poses.sample(action, progress, elapsed)
	_apply_expression()
	_shapes.clear()
	_edge_points.clear()
	_build_character()
	_outline = Geometry2D.convex_hull(_edge_points)
	queue_redraw()


func hit_test(local_point: Vector2) -> bool:
	for shape: Dictionary in _shapes:
		if Geometry2D.is_point_in_polygon(local_point, shape["points"]):
			return true
	return false


func get_outline() -> PackedVector2Array:
	return _outline.duplicate()


func _apply_expression() -> void:
	# Expressions are resolved once so both the renderer and skin adapters can
	# inspect them. Sleeping and blinking always keep the eyes closed.
	if _action == &"sleep" or _mood == &"sleepy":
		pose["eye"] = &"closed"
		pose["mouth"] = &"sleep"
	elif _mood == &"happy":
		pose["eye"] = &"happy"
		pose["mouth"] = &"happy"
	elif _mood == &"sad" or _mood == &"lonely":
		pose["mouth"] = &"sad"
	if _blinking:
		pose["eye"] = &"closed"


func _draw() -> void:
	for shape: Dictionary in _shapes:
		var points: PackedVector2Array = shape["points"]
		draw_colored_polygon(points, shape["color"])
		if shape["border"]:
			var closed: PackedVector2Array = points.duplicate()
			closed.append(points[0])
			draw_polyline(closed, INK, 2.0, true)


func _build_character() -> void:
	var b: Vector2 = pose["body"]
	var h: Vector2 = pose["head"]
	var breath: float = pose["breath"]
	var tail_origin: Vector2 = b + Vector2(45, 50)
	var tail_angle: float = pose["tail_angle"]
	# A whale fluke and long blue hair sit behind the articulated body.
	_poly(_transformed([Vector2(0, 0), Vector2(31, -7), Vector2(48, -30), Vector2(48, -9), Vector2(65, -13), Vector2(47, 5), Vector2(23, 13)], tail_origin, tail_angle), BLUE)
	_ellipse(h + Vector2(-39, 41), Vector2(23, 67), HAIR)
	_ellipse(h + Vector2(39, 41), Vector2(23, 67), HAIR)
	for side: String in ["left", "right"]:
		var hip: Vector2 = pose[side + "_hip"]
		var knee: Vector2 = pose[side + "_knee"]
		var foot: Vector2 = pose[side + "_foot"]
		_capsule(hip, knee, 10, PALE)
		_capsule(knee, foot - Vector2(0, 8), 8, PALE)
		_ellipse(knee, Vector2(8, 8), Color("cbe7f6"), false)
		_ellipse(foot, Vector2(17, 10), BLUE)
		_capsule(foot + Vector2(-8, 3), foot + Vector2(8, 3), 2, PALE, false)
	_capsule(b + Vector2(0, -33), b + Vector2(0, -4), 10, SKIN)
	# Short jacket, bell-shaped skirt and simple original wave trim.
	_poly(PackedVector2Array([b + Vector2(-30 * breath, -8), b + Vector2(30 * breath, -8), b + Vector2(39 * breath, 39), b + Vector2(-39 * breath, 39)]), PALE)
	_poly(PackedVector2Array([b + Vector2(-33, 31), b + Vector2(33, 31), b + Vector2(47, 73), b + Vector2(25, 80), b + Vector2(0, 76), b + Vector2(-25, 80), b + Vector2(-47, 73)]), BLUE)
	_capsule(b + Vector2(-30, 62), b + Vector2(30, 62), 3, PALE, false)
	_poly(PackedVector2Array([b + Vector2(-18, -7), b + Vector2(0, 10), b + Vector2(18, -7), b + Vector2(0, 27)]), BLUE)
	_ellipse(b + Vector2(0, 12), Vector2(5, 7), Color("f5ca73"))
	for side: String in ["left", "right"]:
		var shoulder: Vector2 = pose[side + "_shoulder"]
		var elbow: Vector2 = pose[side + "_elbow"]
		var hand: Vector2 = pose[side + "_hand"]
		_capsule(shoulder, elbow, 10, BLUE)
		_capsule(elbow, hand, 8, PALE)
		_ellipse(elbow, Vector2(7, 7), PALE, false)
		_ellipse(hand, Vector2(9, 10), SKIN)
	# Hood, side fins and pale forehead patch: no logo or borrowed insignia.
	_head_ellipse(Vector2(0, -6), Vector2(57, 62), BLUE)
	_head_poly([Vector2(-46, -30), Vector2(-76, -43), Vector2(-65, -12), Vector2(-48, -7)], BLUE)
	_head_poly([Vector2(46, -30), Vector2(76, -43), Vector2(65, -12), Vector2(48, -7)], BLUE)
	_head_ellipse(Vector2(0, -36), Vector2(24, 17), PALE)
	_head_ellipse(Vector2(0, 4), Vector2(45, 47), SKIN)
	_head_poly([Vector2(-45, -9), Vector2(-40, -30), Vector2(-19, -39), Vector2(5, -37), Vector2(39, -23), Vector2(45, 0), Vector2(27, -8), Vector2(18, 7), Vector2(7, -12), Vector2(-6, 0), Vector2(-15, -18), Vector2(-27, -6)], HAIR)
	_head_poly([Vector2(-43, -17), Vector2(-31, -9), Vector2(-35, 37), Vector2(-50, 24)], HAIR)
	_head_poly([Vector2(43, -17), Vector2(31, -9), Vector2(35, 37), Vector2(50, 24)], HAIR)
	_face()
	if _action == &"feed":
		var hands: Vector2 = ((pose["left_hand"] as Vector2) + (pose["right_hand"] as Vector2)) * 0.5
		_ellipse(hands + Vector2(0, -5), Vector2(12, 9), Color("f5ca73"))
		_ellipse(hands + Vector2(-4, -7), Vector2(2, 2), Color("b07d45"), false)
		_ellipse(hands + Vector2(4, -3), Vector2(2, 2), Color("b07d45"), false)


func _face() -> void:
	var eye: StringName = pose["eye"]
	for x: float in [-18.0, 18.0]:
		if eye == &"closed":
			_head_capsule(Vector2(x - 7, 10), Vector2(x + 7, 10), 1.8, INK)
		elif eye == &"happy":
			_head_capsule(Vector2(x - 7, 11), Vector2(x, 6), 1.8, INK)
			_head_capsule(Vector2(x, 6), Vector2(x + 7, 11), 1.8, INK)
		else:
			_head_ellipse(Vector2(x, 9), Vector2(7, 10), Color("fcfcff"), false)
			_head_ellipse(Vector2(x, 11), Vector2(4.5, 7), Color("3875a8"), false)
			_head_ellipse(Vector2(x + 1.5, 7.5), Vector2(2, 2.5), Color.WHITE, false)
		_head_ellipse(Vector2(x * 1.45, 23), Vector2(7, 3), Color("f1a9b6"), false)
	var mouth: StringName = pose["mouth"]
	if mouth == &"sad":
		_head_capsule(Vector2(-5, 30), Vector2(0, 27), 1.5, INK)
		_head_capsule(Vector2(0, 27), Vector2(5, 30), 1.5, INK)
	elif mouth == &"happy":
		_head_ellipse(Vector2(0, 29), Vector2(6, 6), Color("b75f79"))
	elif mouth == &"small" or mouth == &"sleep":
		_head_ellipse(Vector2(0, 29), Vector2(3, 4), Color("b75f79"), false)
	else:
		_head_capsule(Vector2(-5, 27), Vector2(0, 30), 1.5, INK)
		_head_capsule(Vector2(0, 30), Vector2(5, 27), 1.5, INK)


func _poly(points: PackedVector2Array, color: Color, border: bool = true) -> void:
	_shapes.append({"points": points, "color": color, "border": border})
	# Include the anti-aliased two-pixel outline in the native input region.
	for point: Vector2 in points:
		_edge_points.append(point + Vector2(-2, -2))
		_edge_points.append(point + Vector2(2, -2))
		_edge_points.append(point + Vector2(2, 2))
		_edge_points.append(point + Vector2(-2, 2))


func _ellipse(center: Vector2, radii: Vector2, color: Color, border: bool = true) -> void:
	var points := PackedVector2Array()
	for index: int in range(28):
		var angle: float = TAU * index / 28.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	_poly(points, color, border)


func _capsule(start: Vector2, end: Vector2, radius: float, color: Color, border: bool = true) -> void:
	var points := PackedVector2Array()
	var direction: float = (end - start).angle()
	for index: int in range(9):
		var angle: float = direction + PI * 0.5 + PI * index / 8.0
		points.append(start + Vector2.from_angle(angle) * radius)
	for index: int in range(9):
		var angle: float = direction - PI * 0.5 + PI * index / 8.0
		points.append(end + Vector2.from_angle(angle) * radius)
	_poly(points, color, border)


func _head_point(point: Vector2) -> Vector2:
	return (pose["head"] as Vector2) + point.rotated(pose["head_angle"])


func _head_poly(points: Array[Vector2], color: Color) -> void:
	var transformed := PackedVector2Array()
	for point: Vector2 in points:
		transformed.append(_head_point(point))
	_poly(transformed, color)


func _head_ellipse(center: Vector2, radii: Vector2, color: Color, border: bool = true) -> void:
	var points := PackedVector2Array()
	for index: int in range(28):
		var angle: float = TAU * index / 28.0
		points.append(_head_point(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y)))
	_poly(points, color, border)


func _head_capsule(start: Vector2, end: Vector2, radius: float, color: Color) -> void:
	_capsule(_head_point(start), _head_point(end), radius, color, false)


func _transformed(points: Array[Vector2], origin: Vector2, angle: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point: Vector2 in points:
		result.append(origin + point.rotated(angle))
	return result
