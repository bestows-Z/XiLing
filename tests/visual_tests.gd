extends SceneTree

const Poses = preload("res://scripts/pose_library.gd")
const Visual = preload("res://scripts/pet_visual.gd")


func _initialize() -> void:
	var visual := Visual.new()
	var failures: Array[String] = []
	for action: StringName in Poses.ACTIONS:
		for frame: int in range(21):
			var progress: float = frame / 20.0
			visual.set_pose(action, progress, progress * 4.0, &"content", frame % 2 == 0)
			var outline: PackedVector2Array = visual.get_outline()
			if outline.size() < 4:
				failures.append("Missing outline: %s" % action)
			if not visual.hit_test(visual.pose["head"]):
				failures.append("Head cannot be clicked: %s" % action)
			for side: String in ["left", "right"]:
				for joint: String in ["hand", "foot"]:
					var point: Vector2 = visual.pose[side + "_" + joint]
					if not visual.hit_test(point) or not Geometry2D.is_point_in_polygon(point, outline):
						failures.append("Limb outside clickable outline: %s/%s/%s" % [action, side, joint])
			for point: Vector2 in outline:
				if not point.is_finite() or point.x < -175 or point.x > 175 or point.y < -250 or point.y > 215:
					failures.append("Pose outside 360x480 viewport: %s" % action)
			if visual.hit_test(Vector2(170, -230)):
				failures.append("Transparent corner accepts clicks")
	var crouch: Dictionary = Poses.sample(&"jump", 0.18, 0)
	var flight: Dictionary = Poses.sample(&"jump", 0.40, 0)
	var landing: Dictionary = Poses.sample(&"jump", 0.83, 0)
	if (crouch["left_hand"] as Vector2).distance_to(flight["left_hand"]) < 50:
		failures.append("Jump does not articulate the arms")
	if absf((crouch["left_knee"] as Vector2).x - (flight["left_knee"] as Vector2).x) < 8:
		failures.append("Jump does not articulate the knees")
	if (landing["body"] as Vector2).y <= 10:
		failures.append("Landing has no bent-knee recovery")
	var inhale: Dictionary = Poses.sample(&"idle", 0, PI / 4.32)
	var exhale: Dictionary = Poses.sample(&"idle", 0, PI * 3.0 / 4.32)
	if float(inhale["breath"]) - float(exhale["breath"]) < 0.02:
		failures.append("Chest breathing has no independent width variation")
	visual.set_pose(&"idle", 0, 0, &"calm", false)
	if visual.pose["eye"] != &"normal" or visual.pose["mouth"] != &"smile":
		failures.append("Calm expression is incorrect")
	visual.set_pose(&"idle", 0, 0, &"happy", false)
	if visual.pose["eye"] != &"happy" or visual.pose["mouth"] != &"happy":
		failures.append("Happy mood has no happy eyes and mouth")
	visual.set_pose(&"idle", 0, 0, &"sleepy", false)
	if visual.pose["eye"] != &"closed" or visual.pose["mouth"] != &"sleep":
		failures.append("Sleepy mood has no sleepy expression")
	visual.set_pose(&"idle", 0, 0, &"happy", true)
	if visual.pose["eye"] != &"closed":
		failures.append("Mood prevents blinking")
	visual.set_pose(&"sleep", 0, 0, &"happy", false)
	if visual.pose["eye"] != &"closed":
		failures.append("Happy mood reopens sleeping eyes")
	visual.free()
	for failure: String in failures:
		push_error(failure)
	print("Visual tests: %d failures; %d actions x 21 poses checked" % [failures.size(), Poses.ACTIONS.size()])
	quit(0 if failures.is_empty() else 1)
