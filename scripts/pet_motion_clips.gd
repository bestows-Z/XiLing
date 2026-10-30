extends RefCounted
## 产品动作片段；同一个身体锚点对应同一桌面位置，手臂变化不参与居中。
const Strip = preload("res://scripts/sprite_strip.gd")
const WALK_DISTANCE: float = 200.0
const REVISED: Array[StringName] = [&"wave", &"dance", &"walk"]

static func append_to(frames: SpriteFrames) -> void:
	for action: StringName in REVISED:
		var walking: bool = action == &"walk"
		var path: String = "res://assets/pet/animations/%s-v3.png" % action
		var pictures: Array[Texture2D] = Strip.load_grid(path,Vector2i(8,8) if walking else Vector2i(8,6),false,[],true)
		if pictures.is_empty(): continue
		if frames.has_animation(action): frames.remove_animation(action)
		frames.add_animation(action)
		frames.set_animation_loop(action,action != &"wave")
		frames.set_animation_speed(action,1.0)
		for picture: Texture2D in pictures:
			picture.set_meta("motion_clip",true)
			# 挥手/舞蹈各2.4秒；走路以实际位移驱动，单独固定步幅。
			frames.add_frame(action,picture,2.4/pictures.size())

static func is_clip(frames: SpriteFrames, action: StringName) -> bool:
	return frames != null and frames.has_animation(action) and frames.get_frame_count(action)>0 and frames.get_frame_texture(action,0).get_meta("motion_clip",false)
