extends SceneTree
var checks: int = 0
var failures: int = 0
func _initialize() -> void: call_deferred("run")
func check(value: bool,message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func contrast(a: Color,b: Color) -> float:
	var x: float = a.srgb_to_linear().get_luminance()
	var y: float = b.srgb_to_linear().get_luminance()
	return (maxf(x,y)+0.05)/(minf(x,y)+0.05)
func run() -> void:
	var menu = load("res://scripts/pet_menu.gd").new()
	root.add_child(menu)
	await process_frame
	var theme: Theme = menu.panel.theme
	for type_name: StringName in [&"Button",&"CheckButton",&"OptionButton"]:
		for name: StringName in [&"font_hover_color",&"font_hover_pressed_color",&"font_focus_color",&"font_pressed_color"]:
			var color: Color = theme.get_color(name,type_name)
			check(contrast(color,theme.get_stylebox("hover_pressed",type_name).bg_color)>=4.5,"hover/pressed/focus text has readable contrast on "+String(type_name))
		check(theme.get_stylebox("hover_pressed",type_name).bg_color.get_luminance()>0.5,"checked-hover background remains light")
		check(theme.get_stylebox("focus",type_name).bg_color.a==0,"focus style does not cover label with an opaque fill")
	for button: OptionButton in [menu.skin_selector,menu._controls["max_fps"],menu._controls["activity_rate"]]:
		check(button.get_popup().theme==theme,"dropdown owns the explicit readable theme")
		check(contrast(theme.get_color("font_hover_color",&"PopupMenu"),theme.get_stylebox("hover",&"PopupMenu").bg_color)>=4.5,"dropdown hover text stays readable")
	menu.queue_free()
	await process_frame
	print("Menu theme tests: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
