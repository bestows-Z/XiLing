extends RefCounted
## 原子替换并保留上次有效备份，失败只返回错误，不中断游戏。
const DEFAULT_PATH: String = "user://pet_state.cfg"
var path: String
var last_error: Error = OK
var recovered_backup: bool = false

func _init(save_path: String = DEFAULT_PATH) -> void:
	path = save_path

func load_state() -> Dictionary:
	recovered_backup = false
	for candidate: String in [path, path + ".bak"]:
		var config: ConfigFile = ConfigFile.new()
		var error: Error = config.load(candidate)
		if error != OK or not config.has_section_key("pet", "state"):
			continue
		var state: Variant = config.get_value("pet", "state", {})
		if state is Dictionary:
			recovered_backup = candidate.ends_with(".bak")
			return state
	return {}

func save_state(state: Dictionary) -> Error:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("pet", "state", state)
	config.set_value("format", "version", 2)
	var temp_path: String = path + ".tmp"
	last_error = config.save(temp_path)
	if last_error != OK:
		return last_error
	var absolute: String = ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		# 仅备份可解析的旧文件，避免损坏数据覆盖最后的好备份。
		var old: ConfigFile = ConfigFile.new()
		if old.load(path) == OK and old.has_section_key("pet", "state") and old.get_value("pet", "state") is Dictionary:
			last_error = DirAccess.copy_absolute(absolute, absolute + ".bak")
			if last_error != OK:
				return last_error
	last_error = DirAccess.rename_absolute(ProjectSettings.globalize_path(temp_path), absolute)
	return last_error
