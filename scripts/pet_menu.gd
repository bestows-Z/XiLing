extends CanvasLayer
const UI_FONT = preload("res://assets/fonts/NotoSansSC-Regular.otf")
signal action_requested(action: StringName)
signal skin_requested(mode: StringName)
signal setting_changed(key: String, value: Variant)
signal reset_requested
signal hide_requested
signal quit_requested
var panel: PanelContainer
var status: Label
var hint: Label
var skin_selector: OptionButton
var autonomous_toggle: CheckButton
var _topmost_toggle: CheckButton
var _hint_time: float = 0.0
var _controls: Dictionary = {}
var _scale_label: Label
var suspended: bool = false
var _title_label: Label
var _hide_button: Button

func _ready() -> void:
	layer = 10
	panel = PanelContainer.new()
	panel.position = Vector2(14, 20)
	panel.size = Vector2(332, 438)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("eef8fffa")
	style.border_color = Color("94c9e4")
	style.set_border_width_all(2)
	style.set_corner_radius_all(22)
	style.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", style)
	var theme: Theme = Theme.new()
	theme.default_font = UI_FONT
	theme.default_font_size = 13
	for type_name: StringName in [&"Label", &"Button", &"CheckButton", &"OptionButton", &"TabBar"]:
		for color_name: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_selected_color", &"font_unselected_color"]:
			theme.set_color(color_name, type_name, Color("24445f"))
	var tab_panel: StyleBoxFlat = StyleBoxFlat.new()
	tab_panel.bg_color = Color("e4f2fc")
	tab_panel.set_content_margin_all(4)
	theme.set_stylebox("panel", "TabContainer", tab_panel)
	for state: StringName in [&"tab_selected", &"tab_unselected", &"tab_hovered"]:
		var tab_style: StyleBoxFlat = StyleBoxFlat.new()
		tab_style.bg_color = Color("c6e4f6") if state == &"tab_selected" else Color("e4f2fc")
		tab_style.set_content_margin_all(6)
		theme.set_stylebox(state, "TabBar", tab_style)
	for state: StringName in [&"normal", &"hover", &"pressed"]:
		var choice_style: StyleBoxFlat = StyleBoxFlat.new()
		choice_style.bg_color = Color("d4eafa") if state == &"normal" else Color("bedff4")
		choice_style.set_corner_radius_all(7)
		choice_style.set_content_margin_all(6)
		theme.set_stylebox(state, "OptionButton", choice_style)
	panel.theme = theme
	add_child(panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)
	var title: Label = Label.new()
	title.text = "汐灵  ·  小汐"
	_title_label = title
	title.add_theme_font_size_override("font_size", 22)
	column.add_child(title)
	status = Label.new()
	status.add_theme_font_size_override("font_size", 11)
	column.add_child(status)
	var tabs: TabContainer = TabContainer.new()
	tabs.custom_minimum_size = Vector2(0, 270)
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(tabs)
	var actions: VBoxContainer = _page(tabs, "互动")
	var grid: GridContainer = GridContainer.new()
	grid.columns = 3
	actions.add_child(grid)
	for entry: Array in [["摸摸", &"pet"], ["喂食 F", &"feed"], ["挥手", &"wave"], ["跳跃 空格", &"jump"], ["跳舞 D", &"dance"], ["睡 / 醒 S", &"sleep"]]:
		var action: StringName = entry[1]
		var button: Button = _button(entry[0])
		button.custom_minimum_size = Vector2(88, 34)
		button.pressed.connect(func() -> void: action_requested.emit(action); close())
		grid.add_child(button)
	var extra: OptionButton = OptionButton.new()
	var extras: Array[StringName] = [&"look", &"happy", &"angry", &"surprised", &"shy", &"crouch", &"takeoff", &"land", &"walk", &"turn", &"sit", &"yawn", &"wake"]
	extra.add_item("更多动作（原画需对应动画素材）")
	for text: String in ["左右张望", "开心", "生气表情", "惊讶", "害羞", "下蹲", "起跳", "落地", "原地行走", "转身示意", "坐下", "打哈欠", "苏醒"]:
		extra.add_item(text)
	extra.item_selected.connect(func(index: int) -> void:
		if index > 0:
			action_requested.emit(extras[index - 1])
			close()
			extra.select(0))
	actions.add_child(extra)
	var bubble: Button = _button("泡泡游戏 · 20秒 / 结束游戏")
	bubble.pressed.connect(func() -> void: action_requested.emit(&"bubbles"); close())
	actions.add_child(bubble)
	skin_selector = OptionButton.new()
	for text: String in ["兼容演示（无需立绘）", "原始鲸鱼娘立绘", "本地动画皮肤"]:
		skin_selector.add_item(text)
	skin_selector.item_selected.connect(func(index: int) -> void:
		var modes: Array[StringName] = [&"native", &"original", &"custom"]
		skin_requested.emit(modes[index]))
	actions.add_child(skin_selector)
	var help: Label = Label.new()
	help.text = "轻点摸摸 · 双击挥手 · 来回移动鼠标抚摸\n按住移动拖拽 · 右键 / M 菜单\n空格跳跃 · B 泡泡 · Esc 结束玩法 / 菜单"
	help.add_theme_font_size_override("font_size", 10)
	actions.add_child(help)
	var settings: VBoxContainer = _page(tabs, "设置")
	_scale_label = Label.new()
	settings.add_child(_scale_label)
	var scale_slider: HSlider = HSlider.new()
	scale_slider.min_value = 0.6
	scale_slider.max_value = 1.5
	scale_slider.step = 0.05
	scale_slider.value_changed.connect(func(value: float) -> void: setting_changed.emit("scale", value))
	_controls["scale"] = scale_slider
	settings.add_child(scale_slider)
	for entry: Array in [["窗口置顶", "topmost"], ["播放动画", "animations"], ["自主行为", "autonomous"], ["允许主动互动提示", "proactive"], ["夜间安静休息", "quiet_night"]]:
		var key: String = entry[1]
		var toggle: CheckButton = CheckButton.new()
		toggle.text = entry[0]
		toggle.toggled.connect(func(value: bool) -> void: setting_changed.emit(key, value))
		_controls[key] = toggle
		settings.add_child(toggle)
	autonomous_toggle = _controls["autonomous"]
	_topmost_toggle = _controls["topmost"]
	var fps: OptionButton = OptionButton.new()
	for value: int in [24, 30, 60, 120]: fps.add_item("最大帧率：%d" % value, value)
	fps.item_selected.connect(func(index: int) -> void: setting_changed.emit("max_fps", fps.get_item_id(index)))
	_controls["max_fps"] = fps
	settings.add_child(fps)
	var character: OptionButton = OptionButton.new()
	character.add_item("角色配置：小汐（原画优先）")
	character.add_item("角色配置：海风（演示性格）")
	character.item_selected.connect(func(index: int) -> void: setting_changed.emit("character", "xiaoxi" if index == 0 else "ocean_demo"))
	_controls["character"] = character
	settings.add_child(character)
	var reset: Button = _button("恢复默认设置（保留陪伴记录）")
	reset.pressed.connect(func() -> void: reset_requested.emit())
	settings.add_child(reset)
	var footer: HBoxContainer = HBoxContainer.new()
	column.add_child(footer)
	var back: Button = _button("返回")
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back.pressed.connect(close)
	footer.add_child(back)
	_hide_button = _button("隐藏")
	_hide_button.pressed.connect(func() -> void: close(); hide_requested.emit())
	footer.add_child(_hide_button)
	var quit_button: Button = _button("退出")
	quit_button.pressed.connect(func() -> void: quit_requested.emit())
	footer.add_child(quit_button)
	panel.hide()
	hint = Label.new()
	hint.position = Vector2(18, 8)
	hint.size = Vector2(324, 38)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.add_theme_font_override("font", UI_FONT)
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color("f3fbff"))
	hint.add_theme_color_override("font_outline_color", Color("24445f"))
	hint.add_theme_constant_override("outline_size", 5)
	add_child(hint)

func _page(tabs: TabContainer, title: String) -> VBoxContainer:
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.name = title
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(scroll)
	var column: VBoxContainer = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 5)
	scroll.add_child(column)
	return column

func _button(text: String) -> Button:
	var button: Button = Button.new()
	button.text = text
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("d9edfa")
	style.set_corner_radius_all(9)
	style.set_content_margin_all(7)
	button.add_theme_stylebox_override("normal", style)
	return button

func is_open() -> bool:
	return panel != null and panel.visible

func toggle(data: Dictionary) -> void:
	if is_open(): close()
	else:
		refresh(data)
		panel.show()

func close() -> void:
	panel.hide()

func refresh(data: Dictionary) -> void:
	var mood: Dictionary = data.get("mood", {})
	status.text = "心情 %d · 精力 %d · 亲密 %d · 无聊 %d" % [int(mood.get("joy", 0)), int(mood.get("energy", 0)), int(mood.get("affection", 0)), int(mood.get("boredom", 0))]

func refresh_settings(data: Dictionary) -> void:
	for key: String in _controls:
		var control: Control = _controls[key]
		if control is CheckButton: control.set_pressed_no_signal(data[key])
		elif key == "scale": control.set_value_no_signal(data[key])
		elif key == "max_fps":
			for index: int in range(control.item_count):
				if control.get_item_id(index) == int(data[key]): control.select(index)
		elif key == "character": control.select(0 if data[key] == "xiaoxi" else 1)
	_scale_label.text = "桌宠大小：%d%%" % int(float(data["scale"]) * 100.0)

func configure_platform(wayland: bool, tray_available: bool = false) -> void:
	_topmost_toggle.disabled = wayland
	if wayland: _topmost_toggle.text = "置顶由桌面环境决定"
	_hide_button.text = "隐藏" if tray_available else "隐藏10秒"
	_hide_button.disabled = wayland
	if wayland: _hide_button.tooltip_text = "Wayland 请使用系统窗口控制，或通过 XWayland 运行。"

func say(message: String, duration: float = 3.0) -> void:
	hint.text = message
	_hint_time = duration

func _process(delta: float) -> void:
	_hint_time = maxf(0.0, _hint_time - delta)
	hint.visible = _hint_time > 0.0 and not is_open() and not suspended

func set_skin_mode(mode: StringName) -> void:
	var modes: Array[StringName] = [&"native", &"original", &"custom"]
	skin_selector.select(maxi(0, modes.find(mode)))

func set_character_name(value: String) -> void:
	_title_label.text = "汐灵  ·  " + value
