extends RefCounted

var failures: Array[String] = []
var checks = 0

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
		printerr("FAIL: "+description)
	else: print("PASS: "+description)

func run(game: Node) -> void:
	game.coins = 900
	game.skills = [0,0,0,0,0]
	game.rescue = {"stabilizer":2,"safety":2,"undo":2}
	game.settings.language = "vi"
	game.restart_run()
	check(game.Catalog.BLOCKS.size() == 13,"13 block types")
	check(game.audio.sounds.size() == 9 and game.audio.music.stream != null,"music and nine SFX imported")
	# The viewport anchor must be independent of aspect, tower height and tilt.
	game.set_physics_process(false)
	game.set_process(false)
	var original_size = game.get_viewport().size
	for viewport_size in [Vector2i(720,1280),Vector2i(720,1600),Vector2i(768,1024)]:
		game.get_viewport().size = viewport_size
		await game.get_tree().process_frame
		for h in [0.0,7.0,40.0,150.0]:
			game.top_point = Vector3(0,h,0)
			game.camera_goal = h
			game.height_m = h
			game.update_camera()
			var normalized_y = game.camera.unproject_position(game.top_point).y/game.get_viewport().get_visible_rect().size.y
			check(absf(normalized_y-2.0/3.0) < 0.004,"camera anchor %.3f at %.0fm / %s" % [normalized_y,h,str(viewport_size)])
	game.camera_goal = 2.0
	game.update_camera()
	var fixed_camera = game.camera.position
	for i in range(30):
		game.top_point = Vector3(-1 if i%2 else 1,2.0+sin(i)*0.03,0.5)
		game.update_camera(1.0/60)
	check(game.camera.position.is_equal_approx(fixed_camera),"camera ignores moving highest-corner jitter")
	game.camera_goal = 5.0
	var previous_camera = game.camera.position
	game.update_camera(1.0/60)
	check(game.camera.position.distance_to(previous_camera) <= 0.051,"camera rise is speed limited after settlement")
	for i in range(240): game.update_camera(1.0/60)
	check(absf(game.camera_height-5.0)<0.002,"camera eases toward settled height")
	game.get_viewport().size = original_size
	game.recalculate_height()
	game.set_physics_process(true)
	game.show_settings()
	var before = game.active.position
	await game.get_tree().create_timer(0.1).timeout
	check(game.get_tree().paused and game.active.position == before,"menus pause physics")
	game.close_modal()
	game.run_coins = 80
	game.bank_coins()
	game.bank_coins()
	check(game.coins == 980,"earned coins bank exactly once")
	game.buy_item("stabilizer",250)
	check(game.coins == 730 and game.rescue.stabilizer == 3,"store deducts price and grants item")
	game.close_modal()
	game.buy_item("undo",1)
	check(game.coins == 730,"store rejects incorrect prices")
	game.coins = 0
	game.buy_item("undo",500)
	check(game.coins == 0 and game.rescue.undo == 2,"store prevents negative balance")
	game.settings.music = 0.0
	game.audio.apply_settings(game.settings)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")),"music mute is independent")
	game.settings.language = "en"
	game.save_game()
	game.settings.language = "vi"
	game.load_save()
	check(game.settings.language == "en" and game.settings.music == 0.0,"settings survive save/reload")
	game.skills = [0,0,0,0,0]
	game.restart_run()
	# Every generated GLB is mandatory for the packaged build, and must match Y-up bounds.
	for i in range(game.Catalog.BLOCKS.size()):
		var spec = game.Catalog.BLOCKS[i]
		var model_path = "res://assets/models/%s.glb" % spec.id
		check(ResourceLoader.exists(model_path),"GLB exists: "+spec.id)
		var body = game.make_block(i)
		body.position = Vector3(10,2,0)
		var top = game.Catalog.highest_point(body)
		check(absf(top.y-(2+spec.size.y*0.5)) < 0.025,"collider height: "+spec.id)
		body.rotation.z = PI/2
		top = game.Catalog.highest_point(body)
		check(absf(top.y-(2+spec.size.x*0.5)) < 0.025,"tilted collider height: "+spec.id)
		body.queue_free()
	# Real rigid-body drop, contact and automatic settlement.
	await game.get_tree().physics_frame
	game.drop_active()
	for i in range(900):
		await game.get_tree().physics_frame
		if game.accepted.size() >= 1 or game.state != "running": break
	check(game.accepted.size() == 1 and game.height_m > 0.8,"real falling crate settles on base")
	game.next_index = 0
	for i in range(60): await game.get_tree().physics_frame
	game.manual_x = 0
	game.manual_z = 0
	await game.get_tree().physics_frame
	game.drop_active()
	for i in range(900):
		await game.get_tree().physics_frame
		if game.accepted.size() >= 2 or game.state != "running": break
	check(game.accepted.size() == 2 and game.height_m > 1.7,"second crate collides with first and forms tower")
	var before_undo = game.height_m
	game.use_undo()
	check(game.accepted.size() == 1 and game.height_m < before_undo,"undo removes top body and recalculates height")
	# The arch gap must not be filled by a bounding-box collider.
	game.set_physics_process(false)
	var arch = game.make_block(7)
	arch.position = Vector3(12,2,0)
	await game.get_tree().physics_frame
	var ray = PhysicsRayQueryParameters3D.create(Vector3(12,1.7,2),Vector3(12,1.7,-2))
	check(game.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(),"arch opening has no invisible collider")
	arch.queue_free()
	game.set_physics_process(true)
	game.restart_run()
	game.active.freeze = false
	game.active.position = Vector3(0,-3,0)
	game.safety_armed = true
	await game.get_tree().physics_frame
	await game.get_tree().physics_frame
	check(game.state == "running" and game.active.freeze and not game.safety_armed,"safety consumes one charge to rescue a fall")
	game.active.freeze = false
	game.active.position.y = -4
	await game.get_tree().physics_frame
	await game.get_tree().physics_frame
	check(game.state == "ended","uncaught fall ends run")
	game.close_modal()
	var rows = game.Ranking.top50(0)
	check(rows.size()==50,"Ranking starts with exactly 50 seeded records")
	var sorted_ok = true
	var names: Dictionary = {}
	for i in range(50):
		names[rows[i].name] = true
		if i>0 and rows[i].height>rows[i-1].height: sorted_ok=false
	check(sorted_ok and names.size()==50,"Ranking heights descending with unique player names")
	rows = game.Ranking.top50(200)
	check(rows.size()==50 and rows[0].id=="you" and rows[0].height==200,"personal best enters Top 50")
	check(game.Ranking.top50(NAN).size()==50,"Ranking rejects non-finite local height")
	game.show_ranking()
	check(game.modal_body.get_node("Podium").get_child_count()==3 and game.modal_body.get_node("LeaderboardRows").get_child_count()==47,"Leaderboard renders Top 3 plus 47 rows")
	game.close_modal()
	check(game.ui.theme.default_font != null,"rounded Vietnamese font installed")
	check(game.ui.has_node("LeftRail") and game.ui.has_node("RightRail"),"function buttons occupy both side rails")
	for key in ["coin","stabilizer","safety","undo","ranking","ads"]:
		check(game.icon(key)!=null,"item icon imported: "+key)
	var balance = game.coins
	game.ads.ready_id = "blocked_by_consent"
	game.ads.sdk_ready = true
	check(not game.ads.show_reward() and game.ads.ready_id == "blocked_by_consent","consent gate prevents even cached ads from showing")
	game.ads.ready_id = ""
	game.ads.sdk_ready = false
	game.ads.grant_reward("unrequested")
	check(game.coins==balance,"unrequested or unavailable ad grants no coins")
	game.ads.showing_id = "test_callback"
	game.ads.grant_reward("test_callback")
	game.ads.grant_reward("test_callback")
	check(game.coins==balance+120,"SDK reward callback grants exactly once")
	game.ads.close_ad("test_callback")
	check(game.coins==balance+120,"dismissal cannot grant coins")
	game.show_ads()
	check(game.watch_ad_button.disabled,"desktop cannot pretend to show a native ad")
	game.close_modal()
	print("HIGHSTACK_SMOKE: %d checks, %d failures" % [checks,failures.size()])
	var output = {"checks":checks,"failures":failures,"engine":Engine.get_version_info().string}
	var report = FileAccess.open("user://smoke-report.json",FileAccess.WRITE)
	if report: report.store_string(JSON.stringify(output,"  "))
	game.get_tree().quit(0 if failures.is_empty() else 1)
