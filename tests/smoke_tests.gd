extends SceneTree

var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	check(scene != null, "Main scene loads without local art")
	var main: Node = scene.instantiate()
	root.add_child(main)
	await process_frame
	var pet: Node = main.get_node("Pet")
	var has_original: bool = FileAccess.file_exists("res://assets/pet/xiaoxi.png")
	check(pet.skin.mode == (&"original" if has_original else &"native"), "Local original is preferred; clean checkout has a working fallback")
	check(pet.visual.visible == not has_original, "Fallback visual appears only when original art is absent")
	if has_original:
		check(pet.sprite_frames != null, "Original artwork is loaded on the local project")
		var clicks_before: int = pet.runtime.statistics["pets"]
		pet.brain.autonomous = false
		var press: InputEventMouseButton = InputEventMouseButton.new()
		press.button_index = MOUSE_BUTTON_LEFT
		press.position = Vector2(180, 240)
		press.pressed = true
		pet._unhandled_input(press)
		check(pet._left_pending, "viewport-coordinate click hits the visible original artwork")
		press.pressed = false
		pet._unhandled_input(press)
		pet.interaction.tick(0.5)
		check(pet.brain.action == &"pet" and pet.runtime.statistics["pets"] == clicks_before + 1, "stationary click reaches feedback without a drag cooldown")
		pet.brain.reset()
	else:
		check(pet.sprite_frames == null, "No hard resource dependency on excluded textures")
	pet._select_skin(&"native")
	pet.brain.autonomous = false
	for action: StringName in [&"wave", &"jump", &"dance", &"sleep", &"curious", &"feed", &"pet"]:
		pet.brain.tick(2.0)
		check(pet.brain.request(action), "Request %s" % action)
		pet._update_visual()
		check(pet._window_outline().size() >= 3, "Input contour for %s" % action)
	pet.brain.reset()
	pet.brain.autonomous = false
	pet._queue_click(false)
	check(pet.brain.action == &"idle", "First click waits for double click")
	pet._queue_click(true)
	check(pet.brain.action == &"wave", "Double click waves without pet cooldown blocking")
	pet.brain.reset()
	pet._queue_click(false)
	pet._interact(&"jump")
	pet._process(0.25)
	pet._process(0.25)
	check(pet.brain.action == &"jump", "Deferred single click cannot interrupt right click")
	pet._queue_click(false)
	pet._toggle_menu()
	check(pet._single_click_wait < 0.0, "Opening menu cancels deferred single click")
	check(pet.menu.is_open(), "Menu opens")
	await process_frame
	await process_frame
	check(pet.menu.settings_window.size == Vector2i(400, 600), "Settings use an independent tall readable window")
	check(pet.menu.panel.theme.default_font_size >= 18, "Settings use readable18px text")
	check(pet.menu.hint.get_theme_font_size("font_size") >= 26, "Desktop feedback text is readable on Retina too")
	pet.menu.close()
	check(not pet.menu.is_open(), "Menu closes")
	pet._select_skin(&"original")
	if FileAccess.file_exists("res://assets/pet/xiaoxi.png"):
		check(pet.skin.mode == &"original", "Available local originals load only when requested")
		pet._select_skin(&"native")
		check(pet.skin.mode == &"native" and pet.visual.visible, "Return from local preview to native character")
	else:
		check(pet.skin.mode == &"native", "Missing local originals retain default")
	pet.brain.set_dragging(true)
	check(pet.brain.action == &"drag", "Drag pose")
	pet.brain.set_dragging(false)
	check(pet.brain.action != &"drag", "Drag release")
	pet.runtime.settings.set_value("character", "ocean_demo")
	check(pet.runtime.profile.display_name == "海风演示" and pet.skin.mode == &"native", "character resource changes name and optional visual sources")
	check(pet.menu._title_label.text.contains("海风演示"), "configured character name reaches UI")
	pet.controls.hide_pet()
	check(pet.controls.hidden and not main.visible and pet.desktop.suppressed, "hiding suppresses drawing instead of unsupported main-window hide")
	var hidden_key: InputEventKey = InputEventKey.new()
	hidden_key.keycode = KEY_B
	hidden_key.pressed = true
	pet._unhandled_key_input(hidden_key)
	check(not pet.effects.playing, "hidden pet never consumes gameplay keyboard input")
	pet.controls.show_pet()
	check(not pet.controls.hidden and main.visible and not pet.desktop.suppressed, "show restores drawing and input")
	main.queue_free()
	await process_frame
	print("Scene smoke: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
