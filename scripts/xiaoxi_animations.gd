extends RefCounted
## 真实绘制的动作关键帧；待机始终使用用户原始 PNG。
const EXPRESSIONS: String = "res://assets/pet/actions/expressions.png"
const MOTION: String = "res://assets/pet/actions/motion.png"
const Strip = preload("res://scripts/sprite_strip.gd")
const SEQUENCES: Array[StringName] = [&"wave", &"walk", &"jump", &"dance", &"pet", &"feed", &"sleep", &"curious", &"stretch", &"groom"]

static func append_to(frames: SpriteFrames) -> void:
	if not ResourceLoader.exists(EXPRESSIONS): return
	var sheet: Texture2D = load(EXPRESSIONS) as Texture2D
	var poses: Array[Texture2D] = []
	for index: int in range(8): poses.append(_cell(sheet, 4, 2, index))
	var idle: Texture2D = frames.get_frame_texture(&"idle", 0)
	var blink: Texture2D = frames.get_frame_texture(&"idle", mini(1, frames.get_frame_count(&"idle") - 1))
	_add(frames, &"wave", [idle, poses[0], poses[1], poses[0], poses[1], idle], [0.12, 0.2, 0.2, 0.2, 0.2, 0.08])
	_add(frames, &"jump", [idle, poses[2], poses[3], poses[2], idle], [0.08, 0.2, 0.42, 0.16, 0.14])
	_add(frames, &"crouch", [idle, poses[2]], [0.15, 0.85])
	_add(frames, &"takeoff", [poses[2], poses[3]], [0.3, 0.7])
	_add(frames, &"land", [poses[3], poses[2], idle], [0.2, 0.4, 0.4])
	_add(frames, &"pet", [idle, poses[4], blink, poses[4], idle], [0.1, 0.35, 0.12, 0.33, 0.1])
	_add(frames, &"feed", [idle, poses[5], blink, poses[5], idle], [0.1, 0.35, 0.15, 0.3, 0.1])
	_add(frames, &"sleep", [poses[6]], [1.0])
	_add(frames, &"wake", [poses[6], blink, idle], [0.3, 0.3, 0.4])
	_add(frames, &"curious", [idle, poses[7], idle, poses[7]], [0.12, 0.38, 0.12, 0.38])
	_add(frames, &"look", [poses[7], idle, poses[7]], [0.4, 0.2, 0.4])
	# 这些状态明确复用已绘制姿态，不声称拥有独立精绘资产。
	_add(frames, &"happy", [idle, poses[4], poses[1], idle], [0.1, 0.4, 0.4, 0.1])
	_add(frames, &"shy", [idle, poses[4], idle], [0.15, 0.7, 0.15])
	_add(frames, &"sit", [poses[2]], [1.0])
	_add(frames, &"yawn", [idle, blink, idle, blink], [0.25, 0.25, 0.25, 0.25])
	_add(frames, &"surprised", [idle, poses[3], idle], [0.15, 0.7, 0.15])
	_add(frames, &"drag", [poses[7]], [1.0])
	if not ResourceLoader.exists(MOTION): return
	var motion: Texture2D = load(MOTION) as Texture2D
	var walk_a: Texture2D = _cell(motion, 2, 2, 0)
	var walk_b: Texture2D = _cell(motion, 2, 2, 1)
	_add(frames, &"walk", [walk_a, walk_b, walk_a, walk_b], [0.25, 0.25, 0.25, 0.25])
	frames.set_animation_loop(&"walk", true)
	frames.set_animation_speed(&"walk", 1.6)
	_add(frames, &"dance", [idle, _cell(motion, 2, 2, 2), _cell(motion, 2, 2, 3), _cell(motion, 2, 2, 2), _cell(motion, 2, 2, 3), idle], [0.1, 0.2, 0.2, 0.2, 0.2, 0.1])
	for action: StringName in SEQUENCES:
		var strip: Array[Texture2D] = Strip.load_six("res://assets/pet/animations/%s.png" % action, action == &"sleep")
		if strip.size() != 6: continue
		if frames.has_animation(action): frames.remove_animation(action)
		_add(frames, action, strip, [1, 1, 1, 1, 1, 1])
		if action in [&"walk", &"sleep"]:
			frames.set_animation_loop(action, true)
			frames.set_animation_speed(action, 0.8 if action == &"sleep" else 4.0)
	for pair: Array in [[&"happy", &"pet"], [&"shy", &"pet"], [&"look", &"curious"], [&"wake", &"stretch"]]:
		if not frames.has_animation(pair[1]) or frames.get_frame_count(pair[1]) != 6: continue
		frames.remove_animation(pair[0])
		frames.add_animation(pair[0])
		frames.set_animation_loop(pair[0], false)
		for index: int in range(6): frames.add_frame(pair[0], frames.get_frame_texture(pair[1], index))

static func _cell(sheet: Texture2D, columns: int, rows: int, index: int) -> AtlasTexture:
	var texture: AtlasTexture = AtlasTexture.new()
	texture.atlas = sheet
	var cell: Vector2 = Vector2(sheet.get_size()) / Vector2(columns, rows)
	texture.region = Rect2(Vector2(index % columns, index / columns) * cell, cell)
	# 第一张图集右上角的腾空姿态下方有下一格发梢；裁掉该空白边缘。
	if columns == 4 and index == 3:
		texture.region.size.y -= 20.0
		texture.margin = Rect2(0, 0, 0, 20)
	return texture

static func _add(frames: SpriteFrames, name: StringName, textures: Array, durations: Array) -> void:
	frames.add_animation(name)
	frames.set_animation_loop(name, false)
	frames.set_animation_speed(name, 1.0)
	for index: int in range(textures.size()): frames.add_frame(name, textures[index], durations[index])
