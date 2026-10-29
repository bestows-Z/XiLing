extends Node
signal menu_requested
signal quit_requested
var indicator: StatusIndicator
var tray_menu: PopupMenu
var available: bool = false
var _window: Window
var _return_timer: float = 0.0

func setup(window: Window, test_mode: bool) -> void:
	_window = window
	if test_mode or OS.get_name() not in ["macOS", "Windows"] or not DisplayServer.has_feature(DisplayServer.FEATURE_STATUS_INDICATOR) or not NativeMenu.has_feature(NativeMenu.FEATURE_POPUP_MENU):
		return
	tray_menu = PopupMenu.new()
	tray_menu.name = "TrayMenu"
	tray_menu.prefer_native_menu = true
	tray_menu.add_item("显示小汐", 0)
	tray_menu.add_item("互动与设置", 1)
	tray_menu.add_item("隐藏小汐", 2)
	tray_menu.add_separator()
	tray_menu.add_item("退出汐灵", 3)
	tray_menu.id_pressed.connect(_select)
	add_child(tray_menu)
	indicator = StatusIndicator.new()
	var image: Image = preload("res://assets/icons/xiling.svg").get_image()
	image.resize(22, 22, Image.INTERPOLATE_LANCZOS)
	indicator.icon = ImageTexture.create_from_image(image)
	indicator.tooltip = "汐灵 XiLing"
	indicator.menu = NodePath("../TrayMenu")
	add_child(indicator)
	available = true

func _select(id: int) -> void:
	match id:
		0: show_pet()
		1:
			show_pet()
			menu_requested.emit()
		2: hide_pet()
		3: quit_requested.emit()

func show_pet() -> void:
	_return_timer = 0.0
	_window.show()
	_window.grab_focus()

func hide_pet() -> void:
	# 图标不可见或平台不支持时只能短暂隐藏，避免永久失联。
	var recoverable: bool = available and indicator != null and indicator.get_rect().size.length() > 0.0
	_return_timer = 0.0 if recoverable else 10.0
	_window.hide()

func _process(delta: float) -> void:
	if _return_timer > 0.0:
		_return_timer -= delta
		if _return_timer <= 0.0:
			show_pet()
