extends Node3D

const Catalog = preload("res://scripts/catalog.gd")
const Sound = preload("res://scripts/audio.gd")
const Ranking = preload("res://scripts/ranking.gd")
const Ads = preload("res://scripts/ads.gd")
const SAVE_PATH = "user://highstack.cfg"
const SKILL_NAMES = [["Bám chắc","Grip"],["Giảm chấn","Shock absorber"],["Cân bằng","Balanced core"],["Gỗ nhẹ","Light wood"],["Thưởng Perfect","Perfect bonus"]]
const COSTS = [500,1200,2500,5000,8000]
var settings = {"music":0.45,"sfx":0.8,"language":"vi","shadows":true,"vibration":true,"motion":true}
var coins = 900
var skills = [0,0,0,0,0]
var rescue = {"stabilizer":1,"safety":1,"undo":1}
var owned_themes = ["day"]
var selected_theme = "day"
var best_score = 0
var best_height = 0.0
var save_path = SAVE_PATH
var rng = RandomNumberGenerator.new()
var camera: Camera3D
var sun: DirectionalLight3D
var environment: Environment
var audio: Node
var ads: Node
var coin_label: Label
var score_label: Label
var item_buttons: Dictionary = {}
var model_cache: Dictionary = {}
var camera_height = 0.0
var camera_goal = 0.0
var ads_status_label: Label
var watch_ad_button: Button
var privacy_button: Button
var active: RigidBody3D
var accepted: Array[RigidBody3D] = []
var ghost: MeshInstance3D
var mascot: Node3D
var world_decor: Node3D
var ui: Control
var modal: PanelContainer
var modal_title: Label
var modal_body: VBoxContainer
var hud: Label
var status: Label
var inventory: Label
var record_hud: Label
var root_column: VBoxContainer
var state = "running"
var height_m = 0.0
var height_record = 0.0
var score = 0
var run_coins = 0
var combo = 0
var paid_coins = 0
var safety_armed = false
var drop_age = 0.0
var settle_time = 0.0
var spawn_wait = 0.0
var elapsed = 0.0
var status_time = 0.0
var manual_x = 0.0
var manual_z = 0.0
var top_point = Vector3.ZERO
var next_index = 0
var drop_origin = Vector3.ZERO
var impact_cooldown = 0.0
var test_mode = false
var preview_count = 0

func t(vi: String, en: String) -> String:
	return vi if settings.language == "vi" else en

func _ready() -> void:
	test_mode = "--smoke" in OS.get_cmdline_user_args()
	if test_mode: save_path = "user://highstack-smoke.cfg"
	load_save()
	rng.randomize()
	for spec in Catalog.BLOCKS:
		var path = "res://assets/models/%s.glb" % spec.id
		if ResourceLoader.exists(path): model_cache[spec.id] = load(path)
	audio = Sound.new()
	add_child(audio)
	audio.apply_settings(settings)
	build_world()
	build_ui()
	ads = Ads.new()
	ads.earned.connect(on_ad_reward)
	ads.changed.connect(refresh_ad_menu)
	add_child(ads)
	restart_run()
	if test_mode: call_deferred("run_smoke")
	if "--capture" in OS.get_cmdline_user_args(): call_deferred("capture_preview")

func material(color: Color, rough: float = 0.4) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = rough
	return mat

func mesh_node(mesh: Mesh, pos: Vector3, mat: Material, parent: Node) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	node.material_override = mat
	parent.add_child(node)
	return node

func build_world() -> void:
	environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky = Sky.new()
	var sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("428fdd")
	sky_mat.sky_horizon_color = Color("f7dbb6")
	sky_mat.ground_bottom_color = Color("768bc3")
	sky_mat.ground_horizon_color = Color("f7dbb6")
	sky.sky_material = sky_mat
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("d3e7ff")
	environment.ambient_light_energy = 0.35
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var world = WorldEnvironment.new()
	world.environment = environment
	add_child(world)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42,-30,0)
	sun.light_energy = 0.85
	sun.shadow_enabled = settings.shadows
	sun.directional_shadow_max_distance = 60
	add_child(sun)
	var fill = DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20,140,0)
	fill.light_color = Color("acc9ff")
	fill.light_energy = 0.2
	add_child(fill)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.size = 7.8
	camera.current = true
	camera.far = 180
	add_child(camera)
	camera.position = Vector3(6,6,10)
	camera.look_at(Vector3.ZERO)
	var base = StaticBody3D.new()
	base.name = "Base"
	base.position.y = -0.3
	add_child(base)
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 2.45
	cylinder.bottom_radius = 2.65
	cylinder.height = 0.6
	cylinder.radial_segments = 64
	mesh_node(cylinder,Vector3.ZERO,material(Color("f2ece8")),base)
	var collider = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 2.45
	shape.height = 0.6
	collider.shape = shape
	base.add_child(collider)
	var pm = PhysicsMaterial.new()
	pm.friction = 0.9
	base.physics_material_override = pm
	var rim = TorusMesh.new()
	rim.inner_radius = 2.38
	rim.outer_radius = 2.5
	mesh_node(rim,Vector3(0,-0.02,0),material(Color("36c6ca")),self)
	var island = CylinderMesh.new()
	island.top_radius = 2.6
	island.bottom_radius = 0.65
	island.height = 2.4
	island.radial_segments = 10
	mesh_node(island,Vector3(0,-1.75,0),material(Color("7285a9"),0.8),self)
	world_decor = Node3D.new()
	add_child(world_decor)
	# Distant floating islands and soft cloud clusters remain readable at any tower height.
	var decor_rng = RandomNumberGenerator.new()
	decor_rng.seed = 2389
	for i in range(12):
		var pos = Vector3((-1 if i%2 else 1)*decor_rng.randf_range(3.6,6.0),decor_rng.randf_range(-6,8),-42)
		var rock = CylinderMesh.new()
		rock.top_radius = decor_rng.randf_range(0.5,1.1)
		rock.bottom_radius = 0.15
		rock.height = decor_rng.randf_range(0.8,2)
		rock.radial_segments = 7
		mesh_node(rock,pos,material(Color.from_hsv(0.48+i*0.008,0.3,0.68),0.8),world_decor)
		for j in range(3):
			var cloud = SphereMesh.new()
			cloud.radius = decor_rng.randf_range(0.3,0.65)
			cloud.height = cloud.radius*1.1
			mesh_node(cloud,pos+Vector3(j*0.4-0.4,1.1,0),material(Color("e2e8f7"),0.9),world_decor)
	var path = "res://assets/models/mascot.glb"
	if ResourceLoader.exists(path):
		mascot = load(path).instantiate()
		mascot.position = Vector3(-2.7,0,0)
		mascot.scale = Vector3.ONE*0.7
		add_child(mascot)
	ghost = MeshInstance3D.new()
	var ghost_mesh = CylinderMesh.new()
	ghost_mesh.top_radius = 0.45
	ghost_mesh.bottom_radius = 0.45
	ghost_mesh.height = 0.018
	ghost.mesh = ghost_mesh
	var ghost_mat = material(Color(0.2,1,0.85,0.45))
	ghost_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ghost_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ghost.material_override = ghost_mat
	ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ghost)
	apply_theme()

func style(bg: Color, radius: int = 18) -> StyleBoxFlat:
	var box = StyleBoxFlat.new()
	box.bg_color = bg
	box.set_corner_radius_all(radius)
	box.content_margin_left = 18
	box.content_margin_right = 18
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	return box

func build_ui() -> void:
	if is_instance_valid(ui):
		ui.get_parent().remove_child(ui)
		ui.queue_free()
	var layer = get_node_or_null("Interface")
	if layer == null:
		layer = CanvasLayer.new()
		layer.name = "Interface"
		layer.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(layer)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)
	var theme = Theme.new()
	var game_font = FontVariation.new()
	game_font.base_font = load("res://assets/fonts/Nunito.ttf")
	game_font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"):900}
	game_font.variation_embolden = 0.5
	theme.default_font = game_font
	theme.default_font_size = 23
	theme.set_stylebox("normal","Button",style(Color("17354f")))
	theme.set_stylebox("hover","Button",style(Color("245773")))
	theme.set_stylebox("pressed","Button",style(Color("158f99")))
	theme.set_stylebox("disabled","Button",style(Color("465564")))
	theme.set_stylebox("panel","PanelContainer",style(Color("102b43"),26))
	theme.set_color("font_color","Label",Color("eef6ff"))
	theme.set_color("font_color","Button",Color("eef6ff"))
	for kind in ["Label","Button","CheckButton"]:
		theme.set_color("font_outline_color",kind,Color("102139"))
		theme.set_constant("outline_size",kind,2)
	theme.set_color("font_shadow_color","Label",Color("07152a"))
	theme.set_constant("shadow_offset_y","Label",1)
	theme.set_constant("shadow_offset_x","Label",0)
	ui.theme = theme
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right"]: margin.add_theme_constant_override("margin_"+side,22)
	for side in ["top","bottom"]: margin.add_theme_constant_override("margin_"+side,28)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(margin)
	root_column = VBoxContainer.new()
	root_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_column.add_theme_constant_override("separation",12)
	margin.add_child(root_column)
	var header = HBoxContainer.new()
	root_column.add_child(header)
	var logo = label("HIGHSTACK",28)
	logo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(logo)
	logo.text = "HIGHSTACK 3D"
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.add_theme_font_size_override("font_size",44)
	logo.add_theme_font_override("font",load("res://assets/fonts/Bungee-Regular.ttf"))
	logo.add_theme_color_override("font_color",Color("ffdc74"))
	logo.add_theme_constant_override("outline_size",9)
	logo.add_theme_constant_override("shadow_offset_y",6)
	var panel = PanelContainer.new()
	root_column.add_child(panel)
	var stats = HBoxContainer.new()
	panel.add_child(stats)
	hud = stat_pill(stats,"height")
	score_label = stat_pill(stats,"star")
	coin_label = stat_pill(stats,"coin")
	record_hud = label("",19)
	record_hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_column.add_child(record_hud)
	status = label("",22)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size.y = 56
	root_column.add_child(status)
	var spacer = Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_column.add_child(spacer)
	inventory = label("",19)
	inventory.add_theme_color_override("font_color",Color("ffffff"))
	inventory.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_column.add_child(inventory)
	# Two side rails keep menus and boosters away from the center of play.
	item_buttons.clear()
	var left = side_rail(false)
	var right = side_rail(true)
	side_button(left,"store",t("Cửa hàng","Store"),show_store)
	side_button(left,"ranking",t("Xếp hạng","Top 50"),show_ranking)
	side_button(left,"skills",t("Kỹ năng","Skills"),show_skills)
	side_button(left,"ads",t("Nhận coin","Free coins"),show_ads)
	side_button(right,"settings",t("Cài đặt","Settings"),show_settings)
	item_buttons.stabilizer = side_button(right,"stabilizer",t("Giữ vững","Stabilize"),use_stabilizer)
	item_buttons.safety = side_button(right,"safety",t("Cứu rơi","Safety"),arm_safety)
	item_buttons.undo = side_button(right,"undo",t("Gỡ khối","Undo"),use_undo)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation",8)
	root_column.add_child(row)
	button(row,"↶",func(): rotate_active(-15))
	var drop = button(row,t("THẢ KHỐI","DROP"),drop_active)
	drop.custom_minimum_size = Vector2(280,82)
	drop.add_theme_stylebox_override("normal",style(Color("139e9e")))
	button(row,"↷",func(): rotate_active(15))
	var hint = label(t("Kéo để di chuyển • Xoay rồi thả","Drag to move • Rotate and drop"),20)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color",Color("ffffff"))
	root_column.add_child(hint)
	var shade = ColorRect.new()
	shade.name = "Shade"
	shade.color = Color(0.01,0.04,0.1,0.72)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.visible = false
	ui.add_child(shade)
	modal = PanelContainer.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.offset_left = 32
	modal.offset_right = -32
	modal.offset_top = 150
	modal.offset_bottom = -100
	modal.visible = false
	ui.add_child(modal)
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation",16)
	modal.add_child(column)
	modal_title = label("",28)
	modal_title.add_theme_font_override("font",load("res://assets/fonts/Bungee-Regular.ttf"))
	modal_title.add_theme_color_override("font_color",Color("ffdc74"))
	modal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(modal_title)
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	modal_body = VBoxContainer.new()
	modal_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modal_body.add_theme_constant_override("separation",12)
	scroll.add_child(modal_body)
	button(column,t("Đóng / Tiếp tục","Close / Resume"),close_modal)
	update_ui()

func icon(key: String) -> Texture2D:
	return load("res://assets/icons/%s.svg" % key)

func stat_pill(parent: Node, key: String) -> Label:
	var row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(row)
	var image = TextureRect.new()
	image.texture = icon(key)
	image.custom_minimum_size = Vector2(38,38)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(image)
	var value = label("0",28)
	row.add_child(value)
	return value

func side_rail(right: bool) -> VBoxContainer:
	var rail = VBoxContainer.new()
	rail.name = "RightRail" if right else "LeftRail"
	ui.add_child(rail)
	if right:
		rail.anchor_left = 1.0
		rail.anchor_right = 1.0
		rail.offset_left = -124
		rail.offset_right = -18
	else:
		rail.offset_left = 18
		rail.offset_right = 124
	rail.offset_top = 230
	rail.add_theme_constant_override("separation",12)
	return rail

func side_button(parent: Node, key: String, title: String, action: Callable) -> Button:
	var node = button(parent,"",action)
	node.custom_minimum_size = Vector2(106,100)
	node.tooltip_text = title
	var content = VBoxContainer.new()
	content.name = "Content"
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_child(content)
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_top = 5
	content.offset_bottom = -4
	content.add_theme_constant_override("separation",-3)
	var image = TextureRect.new()
	image.texture = icon(key)
	image.custom_minimum_size = Vector2(48,48)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(image)
	var caption = label(title,19)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(caption)
	if key in ["stabilizer","safety","undo"]:
		var count = label("1",15)
		count.name = "Count"
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count.mouse_filter = Control.MOUSE_FILTER_IGNORE
		count.add_theme_color_override("font_color",Color("ffdc7d"))
		content.add_child(count)
	return node

func label(text: String, font_size: int = 22) -> Label:
	var node = Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size",font_size)
	return node

func button(parent: Node, text: String, action: Callable) -> Button:
	var node = Button.new()
	node.text = text
	node.custom_minimum_size.y = 62
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.pressed.connect(func(): audio.play("tap"); action.call())
	parent.add_child(node)
	return node

func note(text: String) -> void:
	var node = label(text,21)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_body.add_child(node)

func message(vi: String, en: String) -> void:
	status.text = t(vi,en)
	status_time = 2.5

func show_modal(title: String) -> void:
	get_tree().paused = true
	ui.get_node("Shade").visible = true
	for child in modal_body.get_children():
		modal_body.remove_child(child)
		child.queue_free()
	modal_title.text = title
	modal.visible = true

func close_modal() -> void:
	modal.visible = false
	ui.get_node("Shade").visible = false
	get_tree().paused = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED and is_instance_valid(ui):
		bank_coins()
		save_game()
		if not ads.fullscreen and not ads.privacy_busy: show_settings()

func _physics_process(delta: float) -> void:
	if state != "running": return
	elapsed += delta
	impact_cooldown = maxf(0,impact_cooldown-delta)
	status_time = maxf(0,status_time-delta)
	recalculate_height()
	if mascot and settings.motion: mascot.rotation.y = sin(elapsed)*0.16
	if is_instance_valid(active):
		if active.freeze:
			active.position = Vector3(manual_x,height_m+3.0+active.get_meta("spec").size.y*0.5,manual_z)
			update_ghost()
		else:
			drop_age += delta
			if active.position.y < -2.0 or Vector2(active.position.x,active.position.z).length() > 5:
				if safety_armed:
					safety_armed = false
					active.freeze = true
					active.linear_velocity = Vector3.ZERO
					active.angular_velocity = Vector3.ZERO
					manual_x = 0
					manual_z = 0
					drop_age = 0
					audio.play("rescue")
				else:
					finish_run(true)
				return
			var resting = active.get_contact_count() > 0 and active.linear_velocity.length() < 0.16 and active.angular_velocity.length() < 0.2
			settle_time = settle_time+delta if resting else 0.0
			if settle_time >= 0.5: accept_active()
			elif drop_age > 14: finish_run(true)
	elif spawn_wait > 0:
		spawn_wait -= delta
		if spawn_wait <= 0: spawn_block()
	for body in accepted:
		if body.position.y < -2.0:
			finish_run(true)
			return
	update_ui()

func _unhandled_input(event: InputEvent) -> void:
	if modal.visible or state != "running": return
	if event is InputEventScreenDrag:
		move_active(event.relative)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		move_active(event.relative)
	elif event is InputEventKey and event.pressed:
		match event.physical_keycode:
			KEY_SPACE: drop_active()
			KEY_Q: rotate_active(-15)
			KEY_E: rotate_active(15)
			KEY_A: manual_x = clampf(manual_x-0.15,-2.2,2.2)
			KEY_D: manual_x = clampf(manual_x+0.15,-2.2,2.2)
			KEY_W: manual_z = clampf(manual_z-0.15,-1.8,1.8)
			KEY_S: manual_z = clampf(manual_z+0.15,-1.8,1.8)

func move_active(relative: Vector2) -> void:
	if not is_instance_valid(active) or not active.freeze: return
	# Screen-horizontal drags follow the camera's right vector on the base plane.
	manual_x = clampf(manual_x + (relative.x*camera.global_basis.x.x-relative.y*0.5)*0.011,-2.2,2.2)
	manual_z = clampf(manual_z + (relative.x*camera.global_basis.x.z+relative.y*0.8)*0.011,-1.8,1.8)

func _process(delta: float) -> void:
	if state == "running": update_camera(delta)

func update_camera(delta: float = 0.0) -> void:
	# Render-frame smoothing follows accepted height, never a moving collider corner.
	# A fixed X/Z anchor prevents side-to-side jumps when the highest corner changes.
	if delta <= 0.0:
		camera_height = camera_goal
	else:
		var desired = lerpf(camera_height,camera_goal,1.0-exp(-5.0*delta))
		camera_height = move_toward(camera_height,desired,3.0*delta)
	var view_size = get_viewport().get_visible_rect().size
	var vertical_span = camera.size * view_size.y / view_size.x
	var target = Vector3(0,camera_height,0) + camera.global_basis.y * (vertical_span/6.0)
	camera.position = target + camera.global_basis.z*24.0
	world_decor.global_transform = camera.global_transform

func recalculate_height() -> void:
	height_m = 0.0
	top_point = Vector3.ZERO
	for body in accepted:
		var point = Catalog.highest_point(body)
		if point.y > height_m:
			height_m = point.y
			top_point = point

func make_block(index: int) -> RigidBody3D:
	var spec = Catalog.BLOCKS[index]
	var body = RigidBody3D.new()
	body.set_meta("spec",spec)
	body.mass = spec.mass
	body.continuous_cd = true
	body.contact_monitor = true
	body.max_contacts_reported = 16
	body.linear_damp = 0.18
	body.angular_damp = 0.35
	body.freeze = true
	body.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	var wooden = spec.id in ["crate","plank","chair","barrel"]
	var pm = PhysicsMaterial.new()
	pm.friction = 0.78
	pm.bounce = 0.015
	if wooden:
		pm.friction += skills[0]*0.06
		body.linear_damp += skills[1]*0.045
		body.angular_damp += skills[1]*0.09
		body.mass *= 1.0-skills[3]*0.05
		body.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
		body.center_of_mass = Vector3(0,-minf(spec.size.y*0.2,skills[2]*0.025),0)
	body.physics_material_override = pm
	Catalog.add_colliders(body,spec)
	var path = "res://assets/models/%s.glb" % spec.id
	if model_cache.has(spec.id):
		body.add_child(model_cache[spec.id].instantiate())
	else:
		for collider in body.get_children():
			var mesh: Mesh
			if collider.shape is BoxShape3D:
				mesh = BoxMesh.new()
				mesh.size = collider.shape.size
			else:
				mesh = CylinderMesh.new()
				mesh.top_radius = collider.shape.radius
				mesh.bottom_radius = collider.shape.radius
				mesh.height = collider.shape.height
			mesh_node(mesh,collider.position,material(Color.from_hsv(index/13.0,0.55,0.95)),body)
	body.body_entered.connect(func(_other):
		if impact_cooldown <= 0 and not body.freeze:
			audio.play("metal" if spec.id in ["can","ufo"] else "wood",rng.randf_range(0.92,1.08))
			impact_cooldown = 0.1)
	add_child(body)
	return body

func spawn_block() -> void:
	if state != "running" or is_instance_valid(active): return
	active = make_block(next_index)
	next_index = rng.randi_range(0,Catalog.BLOCKS.size()-1)
	manual_x = top_point.x*0.5
	manual_z = top_point.z*0.5
	active.position = Vector3(manual_x,height_m+3.5,manual_z)
	drop_age = 0
	settle_time = 0

func update_ghost() -> void:
	var query = PhysicsRayQueryParameters3D.create(active.position,active.position-Vector3(0,1000,0))
	query.exclude = [active.get_rid()]
	var hit = get_world_3d().direct_space_state.intersect_ray(query)
	ghost.visible = not hit.is_empty()
	if ghost.visible: ghost.position = hit.position+Vector3(0,0.025,0)

func drop_active() -> void:
	if modal.visible or state != "running" or not is_instance_valid(active) or not active.freeze: return
	drop_origin = active.position
	active.freeze = false
	active.sleeping = false
	ghost.visible = false
	audio.play("drop")
	message("Đang rơi…","Dropping…")

func rotate_active(degrees: float) -> void:
	if modal.visible or state != "running" or not is_instance_valid(active) or not active.freeze: return
	active.rotate_y(deg_to_rad(degrees))

func accept_active() -> void:
	var previous = top_point
	var body = active
	accepted.append(body)
	active = null
	recalculate_height()
	camera_goal = height_m
	var gain = maxf(0.0,height_m-height_record)
	height_record = maxf(height_record,height_m)
	best_height = maxf(best_height,height_record)
	var tilt = acos(clampf(body.global_basis.y.dot(Vector3.UP),-1,1))
	var distance = Vector2(body.position.x-previous.x,body.position.z-previous.z).length()
	var perfect = distance < 0.18 and tilt < 0.12 and gain > 0.1
	combo = combo+1 if perfect else 0
	score += int(gain*120)+60+(80+combo*20 if perfect else 20)
	run_coins += int(gain*8)+ (8+skills[4]*2 if perfect else 4)
	if perfect:
		audio.play("perfect",1.0+minf(combo*0.03,0.3))
		message("HOÀN HẢO ×%d" % combo,"PERFECT ×%d" % combo)
		if settings.vibration: Input.vibrate_handheld(35)
	else:
		message("Vững rồi — lên tiếp!","Steady — keep going!")
	save_game()
	spawn_wait = 0.35

func finish_run(collapsed: bool) -> void:
	if state != "running": return
	state = "ended"
	ghost.visible = false
	bank_coins()
	best_height = maxf(best_height,height_record)
	best_score = maxi(best_score,score)
	save_game()
	audio.play("lose" if collapsed else "win")
	show_modal(t("Kết quả","Results"))
	note(t("Chiều cao: %.1f m\nĐiểm: %d\nCoin kiếm được: %d","Height: %.1f m\nScore: %d\nCoins earned: %d") % [height_record,score,run_coins])
	button(modal_body,t("Chơi lại","Play again"),restart_run)

func bank_coins() -> void:
	coins += maxi(0,run_coins-paid_coins)
	paid_coins = run_coins

func restart_run() -> void:
	bank_coins()
	close_modal()
	if is_instance_valid(active):
		remove_child(active)
		active.queue_free()
	active = null
	for body in accepted:
		remove_child(body)
		body.queue_free()
	accepted.clear()
	height_m = 0
	height_record = 0
	top_point = Vector3.ZERO
	score = 0
	run_coins = 0
	paid_coins = 0
	combo = 0
	safety_armed = false
	spawn_wait = 0
	state = "running"
	camera_goal = 0.0
	update_camera()
	next_index = 0
	spawn_block()
	update_ui()
	save_game()

func use_stabilizer() -> void:
	if not can_use_item("stabilizer") or accepted.is_empty(): return
	rescue.stabilizer -= 1
	for body in accepted:
		body.linear_velocity *= 0.05
		body.angular_velocity *= 0.05
		body.sleeping = true
	audio.play("rescue")
	save_game()

func arm_safety() -> void:
	if not can_use_item("safety") or safety_armed: return
	rescue.safety -= 1
	safety_armed = true
	audio.play("rescue")
	save_game()

func use_undo() -> void:
	if not can_use_item("undo") or accepted.is_empty(): return
	if is_instance_valid(active) and not active.freeze: return
	rescue.undo -= 1
	var body = accepted.pop_back()
	remove_child(body)
	body.queue_free()
	recalculate_height()
	camera_goal = height_m
	combo = 0
	audio.play("rescue")
	save_game()

func can_use_item(key: String) -> bool:
	if modal.visible or state != "running": return false
	if rescue[key] <= 0:
		message("Hết vật phẩm — ghé Cửa hàng","Out of items — visit Store")
		return false
	return true

func art(parent: Node, key: String, dimensions: Vector2) -> TextureRect:
	var picture = TextureRect.new()
	picture.texture = load("res://assets/illustrations/%s.svg" % key)
	picture.custom_minimum_size = dimensions
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(picture)
	return picture

func card(parent: Node, tint: Color = Color("234961")) -> VBoxContainer:
	var panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel",style(tint,18))
	parent.add_child(panel)
	var column = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",10)
	panel.add_child(column)
	return column

func show_store() -> void:
	bank_coins()
	show_modal(t("CỬA HÀNG","STORE"))
	var wallet = stat_pill(modal_body,"coin")
	wallet.text = t("%d coin","%d coins") % coins
	note(t("TRỢ THỦ XẾP THÁP","TOWER BOOSTERS"))
	for item in [
		["stabilizer",250,t("GIỮ VỮNG","STABILIZER"),t("Giảm rung lắc, giúp tháp đứng vững.","Calm the tower and steady your stack.")],
		["safety",400,t("CỨU RƠI","SAFETY"),t("Cứu khối rơi hụt để tiếp tục lượt chơi.","Rescue a missed block and keep playing.")],
		["undo",500,t("GỠ KHỐI","UNDO"),t("Gỡ khối trên cùng để xếp lại.","Remove the top block for another try.")]]:
		var content = card(modal_body)
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation",16)
		content.add_child(row)
		art(row,item[0],Vector2(138,142))
		var info = VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		info.add_child(label(item[2],24))
		var description = label(item[3],18)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(description)
		info.add_child(label(t("Đang có: %d","Owned: %d") % rescue[item[0]],18))
		var buy = button(info,t("MUA ×1  •  %d","BUY ×1  •  %d") % item[1],func(): buy_item(item[0],item[1]))
		buy.icon = icon("coin")
		buy.add_theme_constant_override("icon_max_width",26)
		buy.disabled = coins < item[1]
		buy.custom_minimum_size.y = 48
	note(t("BỘ SƯU TẬP BẦU TRỜI","SKY COLLECTION"))
	for item in [["day",0,t("BAN NGÀY","DAYLIGHT")],["sunset",650,t("HOÀNG HÔN","SUNSET")],["night",900,t("CỰC QUANG","AURORA")]]:
		var content = card(modal_body)
		art(content,item[0],Vector2(0,150))
		content.add_child(label(item[2],24))
		var owned = item[0] in owned_themes
		var active_theme = selected_theme == item[0]
		var caption = t("ĐANG DÙNG","EQUIPPED") if active_theme else (t("SỬ DỤNG","EQUIP") if owned else t("MUA • %d coin","BUY • %d coins") % item[1])
		var buy = button(content,caption,func(): buy_theme(item[0],item[1]))
		buy.disabled = active_theme or (not owned and coins < item[1])
	note(t("Xếp tháp hoặc xem quảng cáo để kiếm thêm coin.","Stack towers or watch ads to earn more coins."))

func buy_item(key: String, cost: int) -> void:
	var prices = {"stabilizer":250,"safety":400,"undo":500}
	if not prices.has(key) or cost != prices[key] or coins < cost: return
	coins -= cost
	rescue[key] += 1
	audio.play("coin")
	save_game()
	show_store()

func buy_theme(key: String, cost: int) -> void:
	var prices = {"day":0,"sunset":650,"night":900}
	if not prices.has(key) or prices[key] != cost: return
	if not key in owned_themes:
		if coins < cost: return
		coins -= cost
		owned_themes.append(key)
	selected_theme = key
	apply_theme()
	save_game()
	show_store()

func apply_theme() -> void:
	var sky_mat = environment.sky.sky_material
	match selected_theme:
		"sunset":
			sky_mat.sky_top_color = Color("78579d")
			sky_mat.sky_horizon_color = Color("ffbe96")
		"night":
			sky_mat.sky_top_color = Color("111c48")
			sky_mat.sky_horizon_color = Color("3ca7a9")
		_:
			sky_mat.sky_top_color = Color("428fdd")
			sky_mat.sky_horizon_color = Color("f7dbb6")
	sky_mat.ground_horizon_color = sky_mat.sky_horizon_color

func show_skills() -> void:
	show_modal(t("KỸ NĂNG GỖ","WOOD SKILLS"))
	note(t("Áp dụng cho các khối gỗ.","Applies to wooden blocks."))
	for i in range(skills.size()):
		var level = int(skills[i])
		var text = "%s  %d/5" % [t(SKILL_NAMES[i][0],SKILL_NAMES[i][1]),level]
		if level < 5: text += " • %d coin" % COSTS[level]
		var node = button(modal_body,text,func(): upgrade_skill(i))
		node.disabled = level >= 5 or coins < COSTS[mini(level,4)]

func upgrade_skill(index: int) -> void:
	var level = int(skills[index])
	if level >= 5 or coins < COSTS[level]: return
	coins -= COSTS[level]
	skills[index] += 1
	save_game()
	show_skills()

func show_settings() -> void:
	show_modal(t("CÀI ĐẶT","SETTINGS"))
	privacy_button = button(modal_body,t("Quyền riêng tư quảng cáo","Ad privacy choices"),func(): ads.show_privacy_options())
	privacy_button.visible = is_instance_valid(ads) and ads.privacy_required
	button(modal_body,t("Chơi lại lượt hiện tại","Restart current run"),restart_run)
	for pair in [["music",t("Nhạc nền","Music")],["sfx",t("Hiệu ứng âm thanh","Sound effects")]]:
		note(pair[1])
		var slider = HSlider.new()
		slider.min_value = 0
		slider.max_value = 1
		slider.step = 0.05
		slider.value = settings[pair[0]]
		slider.custom_minimum_size.y = 48
		slider.value_changed.connect(func(value): settings[pair[0]]=value; audio.apply_settings(settings); save_game())
		modal_body.add_child(slider)
	button(modal_body,"Ngôn ngữ / Language: "+("Tiếng Việt" if settings.language == "vi" else "English"),func():
		settings.language = "en" if settings.language == "vi" else "vi"
		save_game()
		build_ui()
		show_settings())
	for pair in [["shadows",t("Bóng đổ","Shadows")],["vibration",t("Rung","Vibration")],["motion",t("Chuyển động trang trí","Decorative motion")]]:
		var check = CheckButton.new()
		check.text = pair[1]
		check.button_pressed = settings[pair[0]]
		check.custom_minimum_size.y = 58
		check.toggled.connect(func(value): settings[pair[0]]=value; sun.shadow_enabled=settings.shadows; save_game())
		modal_body.add_child(check)
	note(t("Game tạm dừng khi mở menu. Kéo trên vùng chơi để di chuyển theo hai chiều; xoay bằng hai nút dưới cùng.","Menus pause the game. Drag in the play area to move in two directions; rotate with the bottom buttons."))

func show_ranking() -> void:
	show_modal(t("BẢNG XẾP HẠNG","LEADERBOARD"))
	var hero = card(modal_body,Color("24566b"))
	var hero_row = HBoxContainer.new()
	hero.add_child(hero_row)
	art(hero_row,"trophy",Vector2(100,100))
	var heading = VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_row.add_child(heading)
	heading.add_child(label("TOP 50",36))
	heading.add_child(label(t("CHINH PHỤC BẦU TRỜI","REACH FOR THE SKY"),20))
	var personal = label(t("Kỷ lục của bạn: %.2f m","Your best: %.2f m") % best_height,23)
	personal.add_theme_color_override("font_color",Color("ffdc7d"))
	hero.add_child(personal)
	var rows = Ranking.top50(best_height)
	var podium = HBoxContainer.new()
	podium.name = "Podium"
	podium.add_theme_constant_override("separation",8)
	modal_body.add_child(podium)
	for i in [1,0,2]:
		var entry = rows[i]
		var column = card(podium,[Color("705723"),Color("435b77"),Color("734d42")][i])
		column.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.get_parent().size_flags_stretch_ratio = 1.0
		var crown = label("#%d" % (i+1),30)
		crown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(crown)
		art(column,"avatar%d" % i,Vector2(0,82 if i==0 else 66))
		var name_label = label(t("Bạn","You") if entry.id == "you" else entry.name,18)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		column.add_child(name_label)
		var value = label("%.2f m" % entry.height,20)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(value)
	note(t("HẠNG     NGƯỜI CHƠI                      ĐỘ CAO","RANK      PLAYER                               HEIGHT"))
	var listing = VBoxContainer.new()
	listing.name = "LeaderboardRows"
	listing.add_theme_constant_override("separation",8)
	modal_body.add_child(listing)
	for i in range(3,rows.size()):
		var entry = rows[i]
		var column = card(listing,Color("246c78") if entry.id == "you" else Color("1c3e58"))
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation",10)
		column.add_child(row)
		var rank_label = label("%02d" % (i+1),22)
		rank_label.custom_minimum_size.x = 38
		row.add_child(rank_label)
		art(row,"avatar%d" % (i%3),Vector2(42,42))
		var player = label(t("Bạn","You") if entry.id == "you" else entry.name,21)
		player.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		player.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		row.add_child(player)
		row.add_child(label("%.2f m" % entry.height,22))

func show_ads() -> void:
	show_modal(t("NHẬN COIN","FREE COINS"))
	note(t("Xem hết quảng cáo thưởng để nhận 120 coin.","Complete a rewarded ad to earn 120 coins."))
	ads_status_label = label("",22)
	ads_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_body.add_child(ads_status_label)
	watch_ad_button = button(modal_body,t("Xem quảng cáo • +120 coin","Watch ad • +120 coins"),func(): ads.show_reward())
	watch_ad_button.icon = icon("ads")
	watch_ad_button.add_theme_constant_override("icon_max_width",40)
	button(modal_body,t("Thử tải lại","Retry loading"),func(): ads.load_reward())
	refresh_ad_menu()

func refresh_ad_menu() -> void:
	if is_instance_valid(privacy_button): privacy_button.visible = ads.privacy_required
	if not is_instance_valid(ads_status_label) or not is_instance_valid(watch_ad_button): return
	var messages = {
		"privacy":["Đang chuẩn bị lựa chọn quyền riêng tư…","Preparing privacy choices…"],
		"privacy_failed":["Chưa thể tải quảng cáo. Vui lòng thử lại sau.","Ads are not available yet. Please retry later."],
		"desktop":["Quảng cáo có trên APK Android.","Ads are available in the Android APK."],
		"unavailable":["Quảng cáo chưa sẵn sàng trên thiết bị này.","Ads are unavailable on this device."],
		"loading":["Đang tải quảng cáo…","Loading ad…"],
		"ready":["Quảng cáo đã sẵn sàng!","Ad ready!"],
		"showing":["Đang xem quảng cáo…","Ad in progress…"],
		"failed":["Chưa tải được. Kiểm tra kết nối và thử lại.","Could not load. Check your connection and retry."],
		"idle":["Đang chuẩn bị quảng cáo tiếp theo…","Preparing the next ad…"]}
	var pair = messages.get(ads.status,messages.failed)
	ads_status_label.text = t(pair[0],pair[1])
	watch_ad_button.disabled = ads.status != "ready"

func on_ad_reward(amount: int) -> void:
	coins += amount
	save_game()
	update_ui()
	message("Đã nhận %d coin!" % amount,"Received %d coins!" % amount)
	audio.play("coin")

func update_ui() -> void:
	if not is_instance_valid(hud): return
	hud.text = "%.1f m" % height_m
	score_label.text = str(score)
	coin_label.text = str(coins+maxi(0,run_coins-paid_coins))
	inventory.text = t("Vật phẩm sẵn sàng ở bên phải","Boosters ready on the right")
	for key in item_buttons:
		var node = item_buttons[key]
		node.get_node("Content/Count").text = str(rescue[key])+(" ✓" if key == "safety" and safety_armed else "")
		node.disabled = state != "running"
	record_hud.text = t("KỶ LỤC: %.1f m","BEST: %.1f m") % best_height
	if status_time <= 0 and is_instance_valid(active):
		var spec = active.get_meta("spec")
		var next = Catalog.BLOCKS[next_index]
		status.text = "%s • %s: %s" % [spec[settings.language],t("Tiếp","Next"),next[settings.language]]

func load_save() -> void:
	var config = ConfigFile.new()
	if config.load(save_path) != OK: return
	coins = maxi(0,int(config.get_value("player","coins",900)))
	best_score = maxi(0,int(config.get_value("player","best_score",0)))
	best_height = maxf(0,float(config.get_value("player","best_height",0)))
	var saved_skills = config.get_value("player","skills",skills)
	if saved_skills is Array and saved_skills.size() == 5:
		for i in range(5): skills[i] = clampi(int(saved_skills[i]),0,5)
	var saved_rescue = config.get_value("player","rescue",rescue)
	if saved_rescue is Dictionary:
		for key in rescue: rescue[key] = maxi(0,int(saved_rescue.get(key,1)))
	for key in settings:
		var value = config.get_value("settings",key,settings[key])
		if typeof(value) == typeof(settings[key]): settings[key] = value
	settings.music = clampf(settings.music,0,1)
	settings.sfx = clampf(settings.sfx,0,1)
	if settings.language not in ["vi","en"]: settings.language = "vi"
	var saved_themes = config.get_value("player","themes",["day"])
	if saved_themes is Array:
		for key in ["sunset","night"]:
			if key in saved_themes: owned_themes.append(key)
	var saved_theme = config.get_value("player","theme","day")
	if saved_theme in owned_themes: selected_theme = saved_theme

func save_game() -> void:
	var config = ConfigFile.new()
	for pair in [["coins",coins],["best_score",best_score],["best_height",best_height],["skills",skills],["rescue",rescue],["themes",owned_themes],["theme",selected_theme]]:
		config.set_value("player",pair[0],pair[1])
	for key in settings: config.set_value("settings",key,settings[key])
	var error = config.save(save_path+".tmp")
	if error == OK:
		error = DirAccess.rename_absolute(save_path+".tmp",save_path)
	if error != OK: push_warning("Could not persist game: %s" % error)

func run_smoke() -> void:
	var suite = preload("res://scripts/smoke_suite.gd").new()
	await suite.run(self)

func capture_preview() -> void:
	set_physics_process(false)
	set_process(false)
	if is_instance_valid(active):
		remove_child(active)
		active.queue_free()
	active = null
	var y = 0.0
	for index in [0,1,6,10,2]:
		var body = make_block(index)
		body.position.y = y+body.get_meta("spec").size.y*0.5
		y += body.get_meta("spec").size.y
		accepted.append(body)
	recalculate_height()
	spawn_block()
	active.position = Vector3(0,height_m+3.2,0)
	camera_goal = height_m
	update_camera()
	update_ui()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://../build/gameplay.png")
	show_store()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://../build/store.png")
	show_settings()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://../build/settings.png")
	show_ranking()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://../build/ranking.png")
	get_tree().quit()
