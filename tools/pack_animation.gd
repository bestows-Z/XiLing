extends SceneTree
## 将透明逐帧 PNG 打包成运行时图集；保留每个像素及 alpha，不重画角色。
## godot --headless --path . --script tools/pack_animation.gd -- INPUT_DIR OUTPUT.png COLUMNS
func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size()!=3 or not args[2].is_valid_int() or args[2].to_int()<1:
		push_error("Usage: INPUT_DIR OUTPUT.png COLUMNS")
		quit(1)
		return
	var names: PackedStringArray = DirAccess.get_files_at(args[0])
	var images: Array[Image] = []
	names.sort()
	var size: Vector2i = Vector2i.ZERO
	for name: String in names:
		if not name.ends_with(".png"): continue
		var image: Image = Image.load_from_file(args[0].path_join(name))
		if image==null or image.is_empty() or (size!=Vector2i.ZERO and image.get_size()!=size):
			push_error("Missing or differently sized frame: "+name)
			quit(1)
			return
		size = image.get_size()
		image.convert(Image.FORMAT_RGBA8)
		images.append(image)
	var columns: int = args[2].to_int()
	if images.is_empty() or images.size()%columns!=0:
		push_error("Frame count must be nonzero and divisible by columns")
		quit(1)
		return
	var rows: int = images.size()/columns
	var sheet: Image = Image.create(size.x*columns,size.y*rows,false,Image.FORMAT_RGBA8)
	sheet.fill(Color.TRANSPARENT)
	for index: int in range(images.size()):
		sheet.blit_rect(images[index],Rect2i(Vector2i.ZERO,size),Vector2i(index%columns,index/columns)*size)
	var result: Error = sheet.save_png(args[1])
	print("Packed %d frames (%d×%d), %s"%[images.size(),columns,rows,error_string(result)])
	quit(0 if result==OK else 1)
