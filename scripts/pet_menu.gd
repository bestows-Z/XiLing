extends CanvasLayer
## 独立窄长窗口：设置的字号与桌宠缩放无关。
const UI_FONT = preload("res://assets/fonts/NotoSansSC-Regular.otf")
signal action_requested(action: StringName)
signal skin_requested(mode: StringName)
signal setting_changed(key: String, value: Variant)
signal reset_requested
signal hide_requested
signal quit_requested
var settings_window: Window
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
var _scroll: ScrollContainer
var _ui_scale: float = 1.0

func _ready() -> void:
	layer = 10
	settings_window = Window.new()
	settings_window.title = "汐灵 · 互动与设置"
	settings_window.visible = false
	settings_window.force_native = DisplayServer.get_name() != "headless"
	settings_window.size = Vector2i(400, 600)
	settings_window.min_size = Vector2i(380, 400)
	settings_window.transient = true
	settings_window.wrap_controls = false
	settings_window.close_requested.connect(close)
	settings_window.window_input.connect(func(event: InputEvent) -> void:
		if event is InputEventKey and event.pressed and event.keycode in [KEY_ESCAPE, KEY_M]:
			settings_window.set_input_as_handled()
			get_viewport().set_input_as_handled()
			close())
	add_child(settings_window)
	panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settings_window.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", _style("f1f7fc", 14, 0))
	var theme: Theme = Theme.new()
	theme.default_font = UI_FONT
	theme.default_font_size = 18
	for type_name: StringName in [&"Label", &"Button", &"CheckButton", &"OptionButton"]:
		for color_name: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_selected_color"]:
			theme.set_color(color_name, type_name, Color("25465f"))
	for type_name: StringName in [&"Button", &"OptionButton"]:
		for state: StringName in [&"normal", &"hover", &"pressed", &"focus"]:
			theme.set_stylebox(state, type_name, _style("dceefb" if state == &"normal" else "bdddf2", 10, 10))
	panel.theme = theme
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	_title_label = Label.new()
	_title_label.text = "汐灵 · 小汐"
	_title_label.add_theme_font_size_override("font_size", 24)
	column.add_child(_title_label)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", 16)
	status.custom_minimum_size.y = 58
	column.add_child(status)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_scroll)
	var list: VBoxContainer = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 9)
	_scroll.add_child(list)
	_heading(list, "她的日常")
	for entry: Array in [["自主生活", "autonomous"], ["自己在桌面散步", "roaming"], ["主动表达想法", "proactive"], ["夜间安静休息", "quiet_night"]]:
		_add_toggle(list, entry[0], entry[1])
	autonomous_toggle = _controls["autonomous"]
	var rate: OptionButton = OptionButton.new()
	rate.custom_minimum_size.y = 40
	for label: String in ["活动节奏：自然 · 25–45秒", "活动节奏：安静 · 35–65秒", "活动节奏：活泼 · 15–25秒"]: rate.add_item(label)
	rate.item_selected.connect(func(index: int) -> void: setting_changed.emit("activity_rate", ["natural", "quiet", "lively"][index]))
	_controls["activity_rate"] = rate
	list.add_child(rate)
	_heading(list, "外观与窗口")
	_scale_label = Label.new()
	list.add_child(_scale_label)
	var scale_slider: HSlider = HSlider.new()
	scale_slider.custom_minimum_size.y = 40
	scale_slider.min_value = 0.6
	scale_slider.max_value = 1.5
	scale_slider.step = 0.05
	scale_slider.value_changed.connect(func(value: float) -> void: setting_changed.emit("scale", value))
	_controls["scale"] = scale_slider
	list.add_child(scale_slider)
	_add_toggle(list, "窗口置顶", "topmost")
	_topmost_toggle = _controls["topmost"]
	_add_toggle(list, "播放人物动画", "animations")
	var fps: OptionButton = OptionButton.new()
	fps.custom_minimum_size.y = 46
	for value: int in [24, 30, 60, 120]: fps.add_item("最大帧率：%d" % value, value)
	fps.item_selected.connect(func(index: int) -> void: setting_changed.emit("max_fps", fps.get_item_id(index)))
	_controls["max_fps"] = fps
	list.add_child(fps)
	skin_selector = OptionButton.new()
	skin_selector.custom_minimum_size.y = 46
	skin_selector.add_item("小汐 · 原画与动作帧")
	skin_selector.add_item("自定义本地动画")
	skin_selector.item_selected.connect(func(index: int) -> void: skin_requested.emit(&"original" if index == 0 else &"custom"))
	list.add_child(skin_selector)
	_heading(list, "陪她玩一会儿")
	var grid: GridContainer = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	list.add_child(grid)
	for entry: Array in [["摸摸", &"pet"], ["喂食 F", &"feed"], ["挥手", &"wave"], ["跳跃", &"jump"], ["跳舞 D", &"dance"], ["睡 / 醒", &"sleep"], ["散步", &"walk"], ["伸懒腰", &"stretch"], ["理头发", &"groom"]]:
		var action: StringName = entry[1]
		var button: Button = _button(entry[0])
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func() -> void: action_requested.emit(action); close())
		grid.add_child(button)
	var bubble: Button = _button("泡泡游戏 · 20 秒")
	bubble.pressed.connect(func() -> void: action_requested.emit(&"bubbles"); close())
	list.add_child(bubble)
	var help: Label = Label.new()
	help.text = "轻点摸摸 · 双击挥手 · 按住移动拖拽\n右键 / M 设置 · 空格跳跃 · B 泡泡"
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.add_theme_font_size_override("font_size", 18)
	list.add_child(help)
	var reset: Button = _button("恢复默认设置")
	reset.pressed.connect(func() -> void: reset_requested.emit())
	list.add_child(reset)
	var footer: HBoxContainer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 8)
	column.add_child(footer)
	var back: Button = _button("返回桌面")
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back.pressed.connect(close)
	footer.add_child(back)
	_hide_button = _button("隐藏")
	_hide_button.pressed.connect(func() -> void: close(); hide_requested.emit())
	footer.add_child(_hide_button)
	var quit_button: Button = _button("退出")
	quit_button.pressed.connect(func() -> void: quit_requested.emit())
	footer.add_child(quit_button)
	hint = Label.new()
	hint.position = Vector2(14, 4)
	hint.size = Vector2(332, 104)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.add_theme_font_override("font", UI_FONT)
	hint.add_theme_font_size_override("font_size", 28)
	hint.add_theme_color_override("font_color", Color("f3fbff"))
	hint.add_theme_color_override("font_outline_color", Color("24445f"))
	hint.add_theme_constant_override("outline_size", 5)
	add_child(hint)

func _style(color: String, margin: int, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(color)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(margin)
	return style

func _heading(parent: Control, text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 20)
	parent.add_child(label)

func _add_toggle(parent: Control, text: String, key: String) -> void:
	var row: PanelContainer = PanelContainer.new()
	row.add_theme_stylebox_override("panel", _style("ffffff", 5, 7))
	var toggle: CheckButton = CheckButton.new()
	toggle.text = text
	toggle.custom_minimum_size.y = 30
	toggle.toggled.connect(func(value: bool) -> void: setting_changed.emit(key, value))
	row.add_child(toggle)
	parent.add_child(row)
	_controls[key] = toggle

func _button(text: String) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size.y = 40
	return button

func is_open() -> bool:
	return settings_window != null and settings_window.visible

func toggle(data: Dictionary) -> void:
	if is_open(): close()
	else:
		refresh(data)
		if DisplayServer.get_name() != "headless":
			var owner_window: Window = get_window()
			var area: Rect2i = DisplayServer.screen_get_usable_rect(owner_window.current_screen)
			# macOS 的 Window.size 为物理像素，Retina 上必须补偿缩放才是可读的 18pt。
			_ui_scale = DisplayServer.screen_get_scale(owner_window.current_screen) if OS.get_name() == "macOS" else maxf(1.0, DisplayServer.screen_get_dpi(owner_window.current_screen) / 96.0)
			_ui_scale = clampf(_ui_scale, 1.0, 2.5)
			var logical_height: int = mini(600, maxi(400, int(area.size.y / _ui_scale) - 80))
			settings_window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
			settings_window.content_scale_size = Vector2i(400, logical_height)
			settings_window.min_size = Vector2i(Vector2(380, 400) * _ui_scale)
			settings_window.size = Vector2i(Vector2(400, logical_height) * _ui_scale)
			var desired: Vector2i = owner_window.position + Vector2i(-settings_window.size.x - 24, -140)
			settings_window.position = Vector2i(clampi(desired.x, area.position.x, maxi(area.position.x, area.end.x - settings_window.size.x)), clampi(desired.y, area.position.y + 30, maxi(area.position.y + 30, area.end.y - settings_window.size.y)))
		settings_window.show()
		settings_window.grab_focus()

func close() -> void:
	settings_window.hide()

func refresh(data: Dictionary) -> void:
	var mood: Dictionary = data.get("mood", {})
	status.text = "%s\n心情 %d · 精力 %d · 亲密 %d" % [data.get("thought", "今天也想和你一起度过。"), int(mood.get("joy", 65)), int(mood.get("energy", 80)), int(mood.get("affection", 20))]

func refresh_settings(data: Dictionary) -> void:
	for key: String in _controls:
		var control: Control = _controls[key]
		if control is CheckButton: control.set_pressed_no_signal(data[key])
		elif key == "scale": control.set_value_no_signal(data[key])
		elif key == "activity_rate": control.select(["natural", "quiet", "lively"].find(data[key]))
		elif key == "max_fps":
			for index: int in range(control.item_count):
				if control.get_item_id(index) == int(data[key]): control.select(index)
	_scale_label.text = "人物大小：%d%%" % int(float(data["scale"]) * 100.0)

func configure_platform(wayland: bool, tray_available: bool = false) -> void:
	_topmost_toggle.disabled = wayland
	_controls["roaming"].disabled = wayland
	if wayland: _topmost_toggle.text = "置顶由桌面环境决定"
	_hide_button.text = "隐藏" if tray_available else "隐藏10秒"
	_hide_button.disabled = wayland

func say(message: String, duration: float = 4.0) -> void:
	hint.text = message
	_hint_time = duration

func _process(delta: float) -> void:
	_hint_time = maxf(0.0, _hint_time - delta)
	hint.visible = _hint_time > 0.0 and not is_open() and not suspended

func set_skin_mode(mode: StringName) -> void:
	skin_selector.select(1 if mode == &"custom" else 0)

func set_character_name(value: String) -> void:
	_title_label.text = "汐灵 · " + value
