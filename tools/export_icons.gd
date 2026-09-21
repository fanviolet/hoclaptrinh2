extends SceneTree

func _initialize() -> void:
	for key in ["launcher","launcher_foreground","launcher_background"]:
		var image = Image.load_from_file("res://assets/%s.svg" % key)
		if image == null: quit(1); return
		image.resize(192 if key == "launcher" else 432,192 if key == "launcher" else 432,Image.INTERPOLATE_LANCZOS)
		if image.save_png("res://assets/%s.png" % key) != OK: quit(1); return
	quit()
