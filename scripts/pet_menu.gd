extends CanvasLayer
## In-window controls keep keyboard access available on all target platforms.

const UI_FONT = preload("res://assets/fonts/NotoSansSC-Regular.otf")

signal action_requested(action: StringName)
signal skin_requested(mode: StringName)
signal autonomous_changed(active: bool)
signal topmost_changed(active: bool)
signal quit_requested

var panel: PanelContainer
var status: Label
var hint: Label
var autonomous_toggle: CheckButton
var _hint_time: float = 0.0
var skin_selector: OptionButton
var _topmost_toggle: CheckButton

func _ready() -> void:
	layer = 10
	panel = PanelContainer.new()
	panel.position = Vector2(14, 20)
	panel.size = Vector2(332, 438)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("eef8fff7")
	style.border_color = Color("94c9e4")
	style.set_border_width_all(2)
	style.set_corner_radius_all(22)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style)
	var ui_theme: Theme = Theme.new()
	var ui_font: Font = UI_FONT
	ui_theme.default_font = ui_font
	for control_type: StringName in [&"Label", &"Button", &"CheckButton", &"OptionButton"]:
		ui_theme.set_color("font_color", control_type, Color("24445f"))
		ui_theme.set_color("font_hover_color", control_type, Color("24445f"))
		ui_theme.set_color("font_pressed_color", control_type, Color("24445f"))
	panel.theme = ui_theme
	add_child(panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)
	var title: Label = Label.new()
	title.text = "汐灵  ·  XiLing"
	title.add_theme_font_size_override("font_size", 23)
	title.add_theme_color_override("font_color", Color("24445f"))
	column.add_child(title)
	status = Label.new()
	status.add_theme_font_size_override("font_size", 13)
	status.add_theme_color_override("font_color", Color("42647e"))
	column.add_child(status)
	var grid: GridContainer = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	column.add_child(grid)
	for entry: Array in [["摸摸", &"pet"], ["喂食 F", &"feed"], ["挥手", &"wave"], ["跳跃 空格", &"jump"], ["跳舞 D", &"dance"], ["睡 / 醒 S", &"sleep"]]:
		var action: StringName = entry[1]
		var button: Button = _button(entry[0])
		button.custom_minimum_size = Vector2(90, 36)
		button.pressed.connect(func() -> void: action_requested.emit(action); close())
		grid.add_child(button)
	autonomous_toggle = CheckButton.new()
	autonomous_toggle.text = "自主活动"
	autonomous_toggle.toggled.connect(func(active: bool) -> void: autonomous_changed.emit(active))
	column.add_child(autonomous_toggle)
	_topmost_toggle = CheckButton.new()
	_topmost_toggle.text = "总在最前面"
	_topmost_toggle.button_pressed = true
	_topmost_toggle.toggled.connect(func(active: bool) -> void: topmost_changed.emit(active))
	column.add_child(_topmost_toggle)
	var skins: OptionButton = OptionButton.new()
	skin_selector = skins
	skins.add_item("兼容占位角色（缺少素材时）", 0)
	skins.add_item("原始鲸鱼娘立绘（本机默认）", 1)
	skins.add_item("本地动画皮肤", 2)
	skins.item_selected.connect(func(index: int) -> void:
		var modes: Array[StringName] = [&"native", &"original", &"custom"]
		skin_requested.emit(modes[index])
	)
	var select_style: StyleBoxFlat = StyleBoxFlat.new()
	select_style.bg_color = Color("d9edfa")
	select_style.set_corner_radius_all(9)
	select_style.content_margin_left = 8
	select_style.content_margin_top = 5
	select_style.content_margin_bottom = 5
	skins.add_theme_stylebox_override("normal", select_style)
	column.add_child(skins)
	var help: Label = Label.new()
	help.text = "左键轻点摸摸，按住移动拖拽\n双击挥手 · 右键跳跃\nShift + 右键 / M 菜单 · A 自主活动\nH 显示提示 · Esc 关闭菜单"
	help.add_theme_font_size_override("font_size", 11)
	help.add_theme_color_override("font_color", Color("42647e"))
	column.add_child(help)
	var footer: HBoxContainer = HBoxContainer.new()
	column.add_child(footer)
	var back: Button = _button("回到桌面")
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back.pressed.connect(close)
	footer.add_child(back)
	var quit_button: Button = _button("退出")
	quit_button.pressed.connect(func() -> void: quit_requested.emit())
	footer.add_child(quit_button)
	panel.hide()
	hint = Label.new()
	hint.position = Vector2(18, 8)
	hint.size = Vector2(324, 38)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.add_theme_font_override("font", ui_font)
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color("f3fbff"))
	hint.add_theme_color_override("font_outline_color", Color("24445f"))
	hint.add_theme_constant_override("outline_size", 5)
	add_child(hint)

func _button(text: String) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", Color("24445f"))
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("d9edfa")
	style.set_corner_radius_all(9)
	style.content_margin_left = 7
	style.content_margin_right = 7
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	button.add_theme_stylebox_override("normal", style)
	return button

func is_open() -> bool:
	return panel != null and panel.visible

func toggle(data: Dictionary) -> void:
	if is_open():
		close()
	else:
		refresh(data)
		panel.show()

func close() -> void:
	panel.hide()

func refresh(data: Dictionary) -> void:
	var mood_data: Dictionary = data.get("mood", {})
	status.text = "心情 %d  ·  精力 %d  ·  亲密 %d" % [int(mood_data.get("joy", 0)), int(mood_data.get("energy", 0)), int(mood_data.get("affection", 0))]
	autonomous_toggle.set_pressed_no_signal(data.get("autonomous", true))

func configure_platform(wayland: bool) -> void:
	_topmost_toggle.disabled = wayland
	if wayland:
		_topmost_toggle.text = "置顶由桌面环境决定"

func say(message: String, duration: float = 3.0) -> void:
	hint.text = message
	_hint_time = duration

func _process(delta: float) -> void:
	_hint_time = maxf(0.0, _hint_time - delta)
	hint.visible = _hint_time > 0.0 and not is_open()

func set_skin_mode(mode: StringName) -> void:
	if skin_selector == null:
		return
	var modes: Array[StringName] = [&"native", &"original", &"custom"]
	var selected: int = modes.find(mode)
	skin_selector.select(maxi(0, selected))
