extends Node3D

const BLOCKS := [
	{"id":"crate","label":"Thùng gỗ","size":Vector3(1.15,0.95,1.15),"mass":1.20,"model":"res://assets/models/crate.glb"},
	{"id":"book","label":"Quyển sách","size":Vector3(1.55,0.30,0.95),"mass":0.75,"model":"res://assets/models/book.glb"},
	{"id":"brick","label":"Viên gạch","size":Vector3(1.10,0.48,0.62),"mass":1.55,"model":"res://assets/models/brick.glb"},
	{"id":"plank","label":"Thanh gỗ","size":Vector3(1.95,0.24,0.52),"mass":0.85,"model":"res://assets/models/plank.glb"},
	{"id":"can","label":"Lon kim loại","size":Vector3(0.72,1.10,0.72),"mass":0.95,"model":"res://assets/models/can.glb","cylinder":true},
	{"id":"barrel","label":"Thùng tròn","size":Vector3(0.95,1.20,0.95),"mass":1.10,"model":"res://assets/models/barrel.glb","cylinder":true},
	{"id":"carton","label":"Hộp carton","size":Vector3(1.20,0.82,0.92),"mass":0.72,"model":"res://assets/models/carton.glb"}
]
const SKILL_NAMES := ["Grip","Shock Absorber","Balanced Core","Light Wood","Perfect Bonus"]
const SKILL_COSTS := [500,1200,2500,5000,8000]
const RANKS := [
	[0,"Bronze"],[400,"Silver"],[1000,"Gold"],[1900,"Platinum"],[3100,"Diamond"],[4700,"Master"],[6800,"Grandmaster"],[9500,"Legend"]
]

var rng := RandomNumberGenerator.new()
var camera: Camera3D
var active: RigidBody3D
var active_spec: Dictionary
var accepted: Array[RigidBody3D] = []
var elapsed := 0.0
var drop_age := 0.0
var settle_time := 0.0
var manual_x := 0.0
var game_state := "running"
var mode := "casual"
var height_m := 0.0
var score := 0
var run_coins := 0
var coins := 900
var rank_points := 0
var combo := 0
var revive_used := false
var safety_armed := false
var rescue := {"stabilizer":1,"safety":1,"undo":1}
var skills := [0,0,0,0,0]
var best_score := 0
var best_height := 0.0
var status_label: Label
var height_label: Label
var score_label: Label
var coin_label: Label
var item_label: Label
var rank_label: Label
var modal: PanelContainer
var modal_title: Label
var modal_body: VBoxContainer
var result_panel: PanelContainer
var result_text: Label
var gameplay_buttons: Array[Button] = []
var mascot: Node3D

func _ready() -> void:
	rng.randomize()
	load_save()
	build_world()
	build_ui()
	spawn_block()
	update_ui()

func build_world() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("#78c8ff")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("#d9f1ff")
	e.ambient_light_energy = 0.85
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48,-28,0)
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25,145,0)
	fill.light_energy = 0.45
	fill.light_color = Color("#b9d7ff")
	add_child(fill)

	camera = Camera3D.new()
	camera.position = Vector3(7.2,6.2,9.3)
	camera.fov = 47.0
	camera.current = true
	add_child(camera)
	camera.look_at(Vector3(0,2.2,0))

	var base := StaticBody3D.new()
	base.name = "Base"
	var base_mesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 2.65
	cylinder.bottom_radius = 2.9
	cylinder.height = 0.55
	cylinder.radial_segments = 48
	base_mesh.mesh = cylinder
	base_mesh.position.y = 0.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#f4f6ff")
	mat.roughness = 0.42
	mat.metallic = 0.04
	base_mesh.material_override = mat
	base.add_child(base_mesh)
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 2.65
	shape.height = 0.55
	col.shape = shape
	base.add_child(col)
	base.position.y = -0.28
	add_child(base)

	for i in range(18):
		var deco := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(rng.randf_range(0.6,1.4),rng.randf_range(1.5,5.5),rng.randf_range(0.6,1.4))
		deco.mesh = box
		var angle := TAU * float(i)/18.0
		var rad := rng.randf_range(9.0,14.0)
		deco.position = Vector3(cos(angle)*rad,box.size.y*0.5-0.3,sin(angle)*rad)
		var dm := StandardMaterial3D.new()
		dm.albedo_color = Color.from_hsv(float(i)/18.0,0.28,0.92)
		dm.roughness = 0.8
		deco.material_override = dm
		add_child(deco)

	mascot = create_mascot()
	mascot.position = Vector3(3.7,0.15,0.4)
	mascot.rotation_degrees.y = -18
	add_child(mascot)

func create_mascot() -> Node3D:
	if ResourceLoader.exists("res://assets/models/mascot.glb"):
		var ps = load("res://assets/models/mascot.glb")
		if ps is PackedScene:
			return ps.instantiate()
	var root := Node3D.new()
	var body := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.55
	sphere.height = 1.35
	body.mesh = sphere
	body.position.y = 0.85
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("#ff9a4a")
	m.roughness = 0.55
	body.material_override = m
	root.add_child(body)
	return root

func build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)

	var top := HBoxContainer.new()
	top.position = Vector2(18,18)
	top.size = Vector2(684,68)
	top.add_theme_constant_override("separation",12)
	root.add_child(top)
	height_label = make_pill(top,"0.0 m")
	score_label = make_pill(top,"0 pts")
	coin_label = make_pill(top,"🪙 0")
	rank_label = make_pill(top,"Bronze")

	status_label = Label.new()
	status_label.position = Vector2(18,95)
	status_label.size = Vector2(684,42)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size",20)
	status_label.add_theme_color_override("font_color",Color("#17334b"))
	root.add_child(status_label)

	item_label = Label.new()
	item_label.position = Vector2(18,1130)
	item_label.size = Vector2(684,36)
	item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_label.add_theme_font_size_override("font_size",17)
	item_label.add_theme_color_override("font_color",Color.WHITE)
	root.add_child(item_label)

	var row := HBoxContainer.new()
	row.position = Vector2(18,1180)
	row.size = Vector2(684,78)
	row.add_theme_constant_override("separation",9)
	root.add_child(row)
	add_action(row,"◀",func(): shift_active(-0.28))
	add_action(row,"↶",func(): rotate_active(-15.0))
	add_action(row,"DROP",drop_active,true)
	add_action(row,"↷",func(): rotate_active(15.0))
	add_action(row,"▶",func(): shift_active(0.28))

	var side := VBoxContainer.new()
	side.position = Vector2(18,155)
	side.size = Vector2(170,390)
	side.add_theme_constant_override("separation",8)
	root.add_child(side)
	add_small(side,"🧲 Stabilizer",use_stabilizer)
	add_small(side,"🛟 Safety",arm_safety)
	add_small(side,"🏗 Undo",use_undo)
	add_small(side,"🛒 Shop",show_shop)
	add_small(side,"🪵 Skills",show_skills)
	add_small(side,"🏆 Rank",show_rank)
	add_small(side,"⇄ Mode",toggle_mode)

	modal = PanelContainer.new()
	modal.position = Vector2(85,250)
	modal.size = Vector2(550,690)
	modal.visible = false
	root.add_child(modal)
	var mv := VBoxContainer.new()
	mv.add_theme_constant_override("separation",14)
	modal.add_child(mv)
	modal_title = Label.new()
	modal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_title.add_theme_font_size_override("font_size",30)
	mv.add_child(modal_title)
	modal_body = VBoxContainer.new()
	modal_body.add_theme_constant_override("separation",10)
	mv.add_child(modal_body)
	var close := Button.new()
	close.text = "ĐÓNG"
	close.custom_minimum_size.y = 58
	close.pressed.connect(func(): modal.visible=false)
	mv.add_child(close)

	result_panel = PanelContainer.new()
	result_panel.position = Vector2(80,350)
	result_panel.size = Vector2(560,480)
	result_panel.visible = false
	root.add_child(result_panel)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation",14)
	result_panel.add_child(rv)
	var title := Label.new()
	title.text = "TOWER DOWN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",36)
	rv.add_child(title)
	result_text = Label.new()
	result_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_text.add_theme_font_size_override("font_size",22)
	rv.add_child(result_text)
	var revive := Button.new()
	revive.text = "▶ DEMO REWARDED AD — CỨU 1 LẦN"
	revive.custom_minimum_size.y = 62
	revive.pressed.connect(rewarded_revive)
	rv.add_child(revive)
	var again := Button.new()
	again.text = "CHƠI LẠI"
	again.custom_minimum_size.y = 62
	again.pressed.connect(restart_run)
	rv.add_child(again)

func make_pill(parent: Control, text_value: String) -> Label:
	var l := Label.new()
	l.text = text_value
	l.custom_minimum_size = Vector2(154,54)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size",18)
	l.add_theme_color_override("font_color",Color("#132b3b"))
	parent.add_child(l)
	return l

func add_action(parent: Control, text_value: String, cb: Callable, primary := false) -> void:
	var b := Button.new()
	b.text = text_value
	b.custom_minimum_size = Vector2(120 if not primary else 154,72)
	b.add_theme_font_size_override("font_size",24 if primary else 20)
	b.pressed.connect(cb)
	parent.add_child(b)
	gameplay_buttons.append(b)

func add_small(parent: Control, text_value: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text_value
	b.custom_minimum_size = Vector2(166,52)
	b.add_theme_font_size_override("font_size",15)
	b.pressed.connect(cb)
	parent.add_child(b)

func _process(delta: float) -> void:
	elapsed += delta
	if mascot:
		mascot.rotation_degrees.y = -18.0 + sin(elapsed*1.6)*5.0
	if game_state != "running":
		return
	if active:
		if active.freeze:
			var auto_x := sin(elapsed*1.55)*1.25
			var auto_z := cos(elapsed*0.83)*0.42
			active.position.x = clamp(auto_x + manual_x,-2.0,2.0)
			active.position.z = auto_z
		else:
			drop_age += delta
			if active.position.y < -2.7 or abs(active.position.x) > 5.5 or abs(active.position.z) > 5.5:
				handle_failure()
				return
			if drop_age > 0.35 and active.get_contact_count() > 0 and active.linear_velocity.length() < 0.14 and active.angular_velocity.length() < 0.22:
				settle_time += delta
				if settle_time > 0.42:
					accept_active()
			else:
				settle_time = 0.0
	for b in accepted:
		if is_instance_valid(b) and b.position.y < -2.7:
			handle_failure()
			return
	update_camera(delta)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("drop"):
		drop_active()
	elif event.is_action_pressed("rotate_left"):
		rotate_active(-15)
	elif event.is_action_pressed("rotate_right"):
		rotate_active(15)
	elif event.is_action_pressed("move_left"):
		shift_active(-0.25)
	elif event.is_action_pressed("move_right"):
		shift_active(0.25)

func update_camera(delta: float) -> void:
	var target_y := max(2.7,height_m+1.75)
	camera.position.y = lerp(camera.position.y,target_y+3.0,delta*1.7)
	var look := Vector3(0,target_y,0)
	var desired := camera.global_transform.looking_at(look,Vector3.UP)
	camera.global_transform.basis = camera.global_transform.basis.slerp(desired.basis,clamp(delta*2.5,0.0,1.0))

func spawn_block() -> void:
	if game_state != "running": return
	active_spec = BLOCKS[rng.randi_range(0,BLOCKS.size()-1)].duplicate(true)
	active = RigidBody3D.new()
	active.name = "Active_%s" % active_spec.id
	active.mass = float(active_spec.mass)
	active.freeze = true
	active.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	active.contact_monitor = true
	active.max_contacts_reported = 10
	active.linear_damp = 0.14 + skills[1]*0.07
	active.angular_damp = 0.18 + skills[1]*0.08
	active.continuous_cd = true
	active.position = Vector3(0,max(height_m+4.8,5.2),0)
	active.set_meta("size",active_spec.size)
	active.set_meta("kind",active_spec.id)
	if active_spec.id in ["crate","plank"] and skills[3] > 0:
		active.mass *= max(0.58,1.0-skills[3]*0.06)
	var pm := PhysicsMaterial.new()
	pm.friction = 0.62 + (skills[0]*0.08 if active_spec.id in ["crate","plank"] else 0.0)
	pm.bounce = 0.03
	active.physics_material_override = pm
	if skills[2] > 0:
		active.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
		active.center_of_mass = Vector3(0,-0.04*skills[2],0)
	add_child(active)
	add_block_visual(active,active_spec)
	add_block_collision(active,active_spec)
	manual_x = 0.0
	drop_age = 0.0
	settle_time = 0.0
	status_label.text = "%s · căn vị trí rồi DROP" % active_spec.label

func add_block_visual(body: RigidBody3D, spec: Dictionary) -> void:
	if ResourceLoader.exists(spec.model):
		var ps = load(spec.model)
		if ps is PackedScene:
			var inst = ps.instantiate()
			body.add_child(inst)
			return
	var mi := MeshInstance3D.new()
	if spec.get("cylinder",false):
		var cm := CylinderMesh.new()
		cm.top_radius = spec.size.x*0.5
		cm.bottom_radius = spec.size.x*0.5
		cm.height = spec.size.y
		cm.radial_segments = 24
		mi.mesh = cm
	else:
		var bm := BoxMesh.new()
		bm.size = spec.size
		mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color_for_kind(spec.id)
	mat.roughness = 0.48
	mi.material_override = mat
	body.add_child(mi)

func add_block_collision(body: RigidBody3D, spec: Dictionary) -> void:
	var cs := CollisionShape3D.new()
	if spec.get("cylinder",false):
		var sh := CylinderShape3D.new()
		sh.radius = spec.size.x*0.49
		sh.height = spec.size.y*0.98
		cs.shape = sh
	else:
		var sh := BoxShape3D.new()
		sh.size = spec.size*0.97
		cs.shape = sh
	body.add_child(cs)

func color_for_kind(kind: String) -> Color:
	match kind:
		"crate": return Color("#d79547")
		"book": return Color("#5e8cff")
		"brick": return Color("#e36754")
		"plank": return Color("#b97a3e")
		"can": return Color("#c5d2df")
		"barrel": return Color("#d99a54")
		_: return Color("#e9bd72")

func drop_active() -> void:
	if game_state != "running" or not active or not active.freeze: return
	active.freeze = false
	active.apply_torque_impulse(Vector3(rng.randf_range(-0.035,0.035),0,rng.randf_range(-0.035,0.035)))
	status_label.text = "Giữ vững…"

func shift_active(dx: float) -> void:
	if active and active.freeze and game_state == "running":
		manual_x = clamp(manual_x+dx,-1.25,1.25)

func rotate_active(deg: float) -> void:
	if active and active.freeze and game_state == "running":
		active.rotate_y(deg_to_rad(deg))

func accept_active() -> void:
	if not active: return
	var placement := placement_quality(active)
	accepted.append(active)
	var size: Vector3 = active.get_meta("size")
	var top := active.position.y + size.y*0.5
	var gained := max(0.0,top-height_m)
	height_m = max(height_m,top)
	var bonus := 0
	if placement == "PERFECT":
		combo += 1
		bonus = 80 + combo*20
		run_coins += 8 + int(skills[4]*1.5)
		status_label.text = "PERFECT ×%d ✨" % combo
	elif placement == "GOOD":
		combo = 0
		bonus = 35
		run_coins += 4
		status_label.text = "GOOD!"
	else:
		combo = 0
		bonus = 10
		run_coins += 2
		status_label.text = "Ổn — lên tiếp!"
	score += int(gained*120.0)+60+bonus
	run_coins += int(gained*8.0)
	active = null
	update_ui()
	get_tree().create_timer(0.34).timeout.connect(spawn_block)

func placement_quality(body: RigidBody3D) -> String:
	if accepted.is_empty(): return "GOOD"
	var prev := accepted[-1]
	var d := Vector2(body.position.x-prev.position.x,body.position.z-prev.position.z).length()
	if d < 0.11 and body.rotation.length() < 0.18: return "PERFECT"
	if d < 0.42: return "GOOD"
	return "NORMAL"

func handle_failure() -> void:
	if safety_armed and mode == "casual" and active:
		safety_armed = false
		active.freeze = true
		active.linear_velocity = Vector3.ZERO
		active.angular_velocity = Vector3.ZERO
		active.position = Vector3(0,max(height_m+4.8,5.2),0)
		drop_age = 0.0
		status_label.text = "Safety Platform đã cứu khối!"
		update_ui()
		return
	game_state = "ended"
	for b in gameplay_buttons: b.disabled = true
	best_score = max(best_score,score)
	best_height = max(best_height,height_m)
	coins += run_coins
	if mode == "ranked":
		var rp_gain := clamp(int(score/240.0)-20,0,180)
		rank_points += rp_gain
	result_text.text = "Cao %.1f m\n%d điểm\n+%d coin\n%s" % [height_m,score,run_coins,current_rank()]
	result_panel.visible = true
	save_game()

func rewarded_revive() -> void:
	if mode == "ranked" or revive_used: return
	revive_used = true
	result_panel.visible = false
	game_state = "running"
	for b in gameplay_buttons: b.disabled = false
	if active and is_instance_valid(active):
		active.queue_free()
		active = null
	if not accepted.is_empty():
		var b := accepted.pop_back()
		if is_instance_valid(b): b.queue_free()
	recalculate_height()
	coins += 35
	status_label.text = "Rewarded rescue demo: tiếp tục!"
	spawn_block()
	update_ui()

func use_stabilizer() -> void:
	if mode == "ranked" or game_state != "running": return
	if rescue.stabilizer <= 0:
		status_label.text = "Hết Stabilizer — mua trong Shop"
		return
	rescue.stabilizer -= 1
	for b in accepted:
		if is_instance_valid(b):
			b.linear_velocity = Vector3.ZERO
			b.angular_velocity = Vector3.ZERO
			b.sleeping = true
	status_label.text = "Stabilizer: tháp đã được khóa dao động"
	save_game(); update_ui()

func arm_safety() -> void:
	if mode == "ranked" or game_state != "running": return
	if safety_armed:
		status_label.text = "Safety Platform đang sẵn sàng"
		return
	if rescue.safety <= 0:
		status_label.text = "Hết Safety Platform — mua trong Shop"
		return
	rescue.safety -= 1
	safety_armed = true
	status_label.text = "Safety Platform đã kích hoạt cho lần rơi kế tiếp"
	save_game(); update_ui()

func use_undo() -> void:
	if mode == "ranked" or game_state != "running" or accepted.is_empty(): return
	if rescue.undo <= 0:
		status_label.text = "Hết Undo Crane — mua trong Shop"
		return
	rescue.undo -= 1
	var b := accepted.pop_back()
	if is_instance_valid(b): b.queue_free()
	score = max(0,score-50)
	recalculate_height()
	status_label.text = "Undo Crane: đã gỡ khối trên cùng"
	save_game(); update_ui()

func recalculate_height() -> void:
	height_m = 0.0
	for b in accepted:
		if is_instance_valid(b):
			var s: Vector3 = b.get_meta("size")
			height_m = max(height_m,b.position.y+s.y*0.5)

func show_shop() -> void:
	show_modal("SHOP")
	add_modal_button("Stabilizer +1 · 250 coin",func(): buy_rescue("stabilizer",250))
	add_modal_button("Safety Platform +1 · 400 coin",func(): buy_rescue("safety",400))
	add_modal_button("Undo Crane +1 · 500 coin",func(): buy_rescue("undo",500))
	add_modal_button("▶ Demo rewarded ad · +120 coin",func(): coins+=120; save_game(); update_ui(); status_label.text="Đã nhận 120 coin (demo ad)")
	add_modal_button("Coin Pack 3,000 · DEMO IAP",func(): coins+=3000; save_game(); update_ui())

func buy_rescue(key: String, cost: int) -> void:
	if coins < cost:
		status_label.text = "Không đủ coin"
		return
	coins -= cost
	rescue[key] += 1
	save_game(); update_ui(); show_shop()

func show_skills() -> void:
	show_modal("WOOD SKILLS")
	for i in range(SKILL_NAMES.size()):
		var lv := skills[i]
		var cost := SKILL_COSTS[min(lv,SKILL_COSTS.size()-1)]
		var text := "%s · Lv%d/5" % [SKILL_NAMES[i],lv]
		if lv < 5: text += " · %d coin" % cost
		else: text += " · MAX"
		add_modal_button(text,func(idx=i): upgrade_skill(idx))

func upgrade_skill(i: int) -> void:
	if skills[i] >= 5: return
	var cost := SKILL_COSTS[skills[i]]
	if coins < cost:
		status_label.text = "Không đủ coin để nâng skill"
		return
	coins -= cost
	skills[i] += 1
	save_game(); update_ui(); show_skills()

func show_rank() -> void:
	show_modal("RANKED · %s" % current_rank())
	var names := ["Linh · Rival","An · Rival","Minh · Rival","Khoa · Rival","Vy · Rival"]
	for i in range(5):
		var l := Label.new()
		l.text = "%d. %s   %d RP" % [i+1,names[i],max(0,rank_points+180-i*95)]
		l.add_theme_font_size_override("font_size",20)
		modal_body.add_child(l)
	var you := Label.new()
	you.text = "YOU · %d RP" % rank_points
	you.add_theme_font_size_override("font_size",23)
	modal_body.add_child(you)

func show_modal(title_text: String) -> void:
	for c in modal_body.get_children(): c.queue_free()
	modal_title.text = title_text
	modal.visible = true

func add_modal_button(text_value: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text_value
	b.custom_minimum_size.y = 58
	b.add_theme_font_size_override("font_size",18)
	b.pressed.connect(cb)
	modal_body.add_child(b)

func toggle_mode() -> void:
	mode = "ranked" if mode == "casual" else "casual"
	status_label.text = "RANKED: boost/item/ad revive bị tắt" if mode == "ranked" else "CASUAL: skills & rescue hoạt động"
	restart_run()

func restart_run() -> void:
	result_panel.visible = false
	modal.visible = false
	for b in gameplay_buttons: b.disabled = false
	if active and is_instance_valid(active): active.queue_free()
	active = null
	for b in accepted:
		if is_instance_valid(b): b.queue_free()
	accepted.clear()
	height_m = 0.0
	score = 0
	run_coins = 0
	combo = 0
	revive_used = false
	safety_armed = false
	game_state = "running"
	camera.position = Vector3(7.2,6.2,9.3)
	spawn_block(); update_ui()

func update_ui() -> void:
	if not height_label: return
	height_label.text = "%.1f m" % height_m
	score_label.text = "%d pts" % score
	coin_label.text = "🪙 %d" % coins
	rank_label.text = "%s%s" % [current_rank()," · R" if mode == "ranked" else ""]
	item_label.text = "🧲 %d   🛟 %d%s   🏗 %d" % [rescue.stabilizer,rescue.safety," ✓" if safety_armed else "",rescue.undo]

func current_rank() -> String:
	var name := "Bronze"
	for r in RANKS:
		if rank_points >= int(r[0]): name = str(r[1])
	return name

func load_save() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://highstack.cfg") == OK:
		coins = int(cfg.get_value("player","coins",900))
		rank_points = int(cfg.get_value("player","rank_points",0))
		best_score = int(cfg.get_value("player","best_score",0))
		best_height = float(cfg.get_value("player","best_height",0.0))
		skills = cfg.get_value("player","skills",[0,0,0,0,0])
		rescue = cfg.get_value("player","rescue",{"stabilizer":1,"safety":1,"undo":1})

func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("player","coins",coins)
	cfg.set_value("player","rank_points",rank_points)
	cfg.set_value("player","best_score",best_score)
	cfg.set_value("player","best_height",best_height)
	cfg.set_value("player","skills",skills)
	cfg.set_value("player","rescue",rescue)
	cfg.save("user://highstack.cfg")
