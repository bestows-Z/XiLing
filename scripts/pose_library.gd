extends RefCounted
## Joint poses for the original, code-drawn XiLing placeholder character.
## A custom renderer can consume the same dictionary without changing the brain.

const ACTIONS: Array[StringName] = [
	&"idle", &"wave", &"jump", &"dance", &"sleep", &"curious", &"drag", &"feed", &"pet",
	&"look", &"happy", &"angry", &"surprised", &"shy", &"crouch", &"takeoff", &"land", &"walk", &"turn", &"sit", &"yawn", &"wake"
]


static func sample(action: StringName, progress: float, elapsed: float) -> Dictionary:
	var t: float = clampf(progress, 0.0, 1.0)
	if action == &"crouch": return sample(&"jump", t * 0.20, elapsed)
	if action == &"takeoff": return sample(&"jump", 0.20 + t * 0.18, elapsed)
	if action == &"land": return sample(&"jump", 0.70 + t * 0.30, elapsed)
	var bob: float = sin(elapsed * 1.8) * 3.0
	var torso: Vector2 = Vector2(0.0, bob)
	var head_angle: float = sin(elapsed * 1.4) * 0.025
	var left_elbow: Vector2 = Vector2(-51, 31)
	var left_hand: Vector2 = Vector2(-45, 60)
	var right_elbow: Vector2 = Vector2(51, 31)
	var right_hand: Vector2 = Vector2(45, 60)
	var left_knee: Vector2 = Vector2(-20, 100)
	var right_knee: Vector2 = Vector2(20, 100)
	var left_foot: Vector2 = Vector2(-23, 132)
	var right_foot: Vector2 = Vector2(23, 132)
	var tail: float = sin(elapsed * 2.2) * 0.12
	var eye: StringName = &"normal"
	var mouth: StringName = &"smile"

	match action:
		&"wave":
			var reach: float = sin(t * PI)
			right_elbow = right_elbow.lerp(Vector2(59, -45), reach)
			right_hand = right_hand.lerp(Vector2(64 + sin(t * TAU * 3) * 12, -92), reach)
			head_angle += reach * -0.10
			mouth = &"happy"
		&"jump":
			# Four authored phases: crouch, takeoff, flight, and bent-knee landing.
			var crouch: float = 0.0
			var flight: float = 0.0
			var arms: float = 0.0
			if t < 0.20:
				crouch = sin(t / 0.20 * PI * 0.5)
			elif t < 0.38:
				var launch: float = (t - 0.20) / 0.18
				crouch = 1.0 - launch
				flight = sin(launch * PI * 0.5)
				arms = launch
			elif t < 0.70:
				var air: float = (t - 0.38) / 0.32
				flight = cos(air * PI * 0.5)
				arms = 1.0 - air * 0.3
			elif t < 0.85:
				crouch = sin((t - 0.70) / 0.15 * PI * 0.5)
				arms = 0.7 * (1.0 - (t - 0.70) / 0.15)
			else:
				crouch = 1.0 - (t - 0.85) / 0.15
			torso.y = bob + crouch * 19.0 - flight * 25.0
			left_elbow = left_elbow.lerp(Vector2(-65, -35), arms)
			right_elbow = right_elbow.lerp(Vector2(65, -35), arms)
			left_hand = left_hand.lerp(Vector2(-74, -77), arms)
			right_hand = right_hand.lerp(Vector2(74, -77), arms)
			left_knee += Vector2(-17 * crouch - 5 * flight, -3 * crouch - 17 * flight)
			right_knee += Vector2(17 * crouch + 5 * flight, -3 * crouch - 17 * flight)
			left_foot += Vector2(-13 * crouch - 8 * flight, -22 * flight)
			right_foot += Vector2(13 * crouch + 8 * flight, -22 * flight)
			mouth = &"happy" if flight > 0.15 else &"smile"
		&"dance":
			var beat: float = sin(t * TAU * 3.0)
			var other: float = cos(t * TAU * 3.0)
			torso += Vector2(beat * 7, -absf(other) * 4)
			left_elbow = Vector2(-64, -9 + beat * 19)
			right_elbow = Vector2(64, -9 - beat * 19)
			left_hand = Vector2(-78, -40 + beat * 24)
			right_hand = Vector2(78, -40 - beat * 24)
			left_knee += Vector2(-8, minf(beat, 0) * 19)
			right_knee += Vector2(8, -maxf(beat, 0) * 19)
			left_foot += Vector2(beat * 9, minf(beat, 0) * 24)
			right_foot += Vector2(beat * 9, -maxf(beat, 0) * 24)
			head_angle = beat * 0.10
			tail = other * 0.3
			mouth = &"happy"
		&"sleep":
			torso += Vector2(0, 12)
			head_angle = 0.15 + sin(elapsed * 1.1) * 0.025
			left_elbow = Vector2(-40, 43)
			right_elbow = Vector2(40, 43)
			left_hand = Vector2(-11, 45)
			right_hand = Vector2(11, 45)
			left_knee = Vector2(-38, 96)
			right_knee = Vector2(38, 96)
			left_foot = Vector2(-50, 119)
			right_foot = Vector2(50, 119)
			eye = &"closed"
			mouth = &"sleep"
		&"curious":
			head_angle = -0.20 * sin(t * PI)
			right_elbow = Vector2(50, 3)
			right_hand = Vector2(33, -32)
			tail += sin(t * PI) * 0.25
			mouth = &"small"
		&"drag":
			var sway: float = sin(elapsed * 6)
			left_elbow = Vector2(-61, -4)
			right_elbow = Vector2(61, -4)
			left_hand = Vector2(-78, -28 + sway * 7)
			right_hand = Vector2(78, -28 - sway * 7)
			left_knee += Vector2(-5, sway * 6)
			right_knee += Vector2(5, -sway * 6)
			left_foot += Vector2(-8, sway * 12)
			right_foot += Vector2(8, -sway * 12)
			mouth = &"small"
		&"feed":
			var eat: float = sin(t * PI)
			left_elbow = left_elbow.lerp(Vector2(-46, -4), eat)
			right_elbow = right_elbow.lerp(Vector2(46, -4), eat)
			left_hand = left_hand.lerp(Vector2(-12, -42), eat)
			right_hand = right_hand.lerp(Vector2(12, -42), eat)
			mouth = &"happy"
		&"pet":
			head_angle = sin(t * TAU * 2) * 0.08
			left_hand += Vector2(-7, -7)
			right_hand += Vector2(7, -7)
			eye = &"happy"
			mouth = &"happy"

		&"look", &"turn":
			var glance: float = sin(t * TAU)
			head_angle = glance * 0.15
			torso.x = glance * (8.0 if action == &"turn" else 2.0)
			left_elbow += Vector2(glance * 7.0, -absf(glance) * 5.0)
			right_elbow += Vector2(glance * 7.0, absf(glance) * 5.0)
		&"happy":
			left_hand = Vector2(-62, -22)
			right_hand = Vector2(62, -22)
			left_elbow = Vector2(-53, 10)
			right_elbow = Vector2(53, 10)
			eye = &"happy"
			mouth = &"happy"
		&"angry":
			left_elbow = Vector2(-53, 25)
			right_elbow = Vector2(53, 25)
			left_hand = Vector2(-28, 30)
			right_hand = Vector2(28, 30)
			eye = &"angry"
			mouth = &"sad"
		&"surprised":
			left_elbow = Vector2(-56, -12)
			right_elbow = Vector2(56, -12)
			left_hand = Vector2(-42, -45)
			right_hand = Vector2(42, -45)
			mouth = &"happy"
		&"shy":
			left_elbow = Vector2(-40, 0)
			right_elbow = Vector2(40, 0)
			left_hand = Vector2(-25, -48)
			right_hand = Vector2(25, -48)
			head_angle = 0.12
			eye = &"happy"
		&"walk":
			var stride: float = sin(t * TAU * 4.0)
			torso.x = sin(t * TAU) * 15.0
			left_knee += Vector2(stride * 14.0, -maxf(stride, 0) * 10.0)
			right_knee += Vector2(-stride * 14.0, minf(stride, 0) * 10.0)
			left_foot += Vector2(stride * 22.0, -maxf(stride, 0) * 24.0)
			right_foot += Vector2(-stride * 22.0, minf(stride, 0) * 24.0)
			left_hand.x -= stride * 14.0
			right_hand.x += stride * 14.0
		&"sit":
			torso.y += 22.0
			left_knee = Vector2(-39, 117)
			right_knee = Vector2(39, 117)
			left_foot = Vector2(-62, 130)
			right_foot = Vector2(62, 130)
			left_hand = Vector2(-29, 67)
			right_hand = Vector2(29, 67)
		&"yawn", &"wake":
			var stretch: float = sin(t * PI)
			left_elbow = left_elbow.lerp(Vector2(-59, -35), stretch)
			right_elbow = right_elbow.lerp(Vector2(59, -35), stretch)
			left_hand = left_hand.lerp(Vector2(-51, -80), stretch)
			right_hand = right_hand.lerp(Vector2(51, -80), stretch)
			head_angle = -stretch * 0.08
			eye = &"closed" if t < 0.65 else &"normal"
			mouth = &"happy" if action == &"yawn" else &"smile"

	return {
		"body": torso, "head": Vector2(0, -82) + torso,
		"breath": 1.0 + sin(elapsed * 2.16) * 0.012,
		"head_angle": head_angle, "tail_angle": tail,
		"left_shoulder": Vector2(-31, -3) + torso,
		"right_shoulder": Vector2(31, -3) + torso,
		"left_elbow": left_elbow + torso, "right_elbow": right_elbow + torso,
		"left_hand": left_hand + torso, "right_hand": right_hand + torso,
		"left_hip": Vector2(-17, 65) + torso,
		"right_hip": Vector2(17, 65) + torso,
		"left_knee": left_knee, "right_knee": right_knee,
		"left_foot": left_foot, "right_foot": right_foot,
		"eye": eye, "mouth": mouth
	}
