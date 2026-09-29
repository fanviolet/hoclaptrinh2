extends Node

signal changed
signal earned(amount: int)
const REWARD_COINS = 120
# Publisher-supplied rewarded unit; Android emulators remain Google test devices.
const REWARDED_ID = "ca-app-pub-7928274342057259/4248869130"
const APP_OPEN_ID = "ca-app-pub-7928274342057259/8668294599"
const APP_OPEN_TEST_ID = "ca-app-pub-3940256099942544/9257395921"
const OPEN_MAX_AGE_MS = 4*60*60*1000
const OPEN_COOLDOWN_MS = 120000
var app_open_loaded_at = -1
var app_open_loading = false
var app_open_showing = false
var last_fullscreen_at = -OPEN_COOLDOWN_MS
var test_ads = false
var privacy: Object
var consent_allowed = false
var privacy_required = false
var initializing = false
var privacy_busy = false
var sdk: Node
var status = "desktop"
var ready_id = ""
var showing_id = ""
var rewarded_ids: Dictionary = {}
var fullscreen = false
var sdk_ready = false
var request_in_flight = false
var request_serial = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.get_name() != "Android": return
	if not Engine.has_singleton("AdmobPlugin") or not Engine.has_singleton("HighStackPrivacy"):
		set_status("unavailable")
		return
	sdk = Admob.new()
	test_ads = bool(ProjectSettings.get_setting("highstack/ads/test_mode",false))
	sdk.is_real = not test_ads
	sdk.auto_show_on_resume = false
	sdk.remove_rewarded_ads_after_displayed = false
	sdk.android_real_rewarded_id = REWARDED_ID
	sdk.process_mode = Node.PROCESS_MODE_ALWAYS
	sdk.initialization_completed.connect(func(_info): sdk_ready=true; load_reward(); load_app_open())
	sdk.rewarded_ad_loaded.connect(func(info,_response):
		request_in_flight=false
		if not consent_allowed: sdk.remove_rewarded_ad(info.get_ad_id()); return
		ready_id=info.get_ad_id(); set_status("ready"); print("HIGHSTACK_ADS: rewarded ad loaded"))
	sdk.rewarded_ad_failed_to_load.connect(func(_info,error):
		request_in_flight=false; set_status("failed")
		print("HIGHSTACK_REWARDED_ERROR: %d %s" % [error.get_code(),error.get_message()]))
	sdk.rewarded_ad_user_earned_reward.connect(func(info,_reward): grant_reward(info.get_ad_id()))
	sdk.rewarded_ad_dismissed_full_screen_content.connect(func(info): close_ad(info.get_ad_id()))
	sdk.rewarded_ad_failed_to_show_full_screen_content.connect(func(info,_error): close_ad(info.get_ad_id()))
	add_child(sdk)
	sdk.set_request_configuration(sdk.create_request_configuration())
	privacy = Engine.get_singleton("HighStackPrivacy")
	privacy.consent_finished.connect(on_consent_finished)
	privacy.app_open_loaded.connect(func():
		app_open_loading=false; app_open_loaded_at=Time.get_ticks_msec(); print("HIGHSTACK_APP_OPEN: loaded"))
	privacy.app_open_failed.connect(func(code,message):
		app_open_loading=false; app_open_loaded_at=-1; print("HIGHSTACK_APP_OPEN_ERROR: %d %s" % [code,message]))
	privacy.app_open_closed.connect(close_app_open)
	request_privacy()
	print("HIGHSTACK_ADS: publisher rewarded unit configured")
	print("HIGHSTACK_ADS: Rewarded unit=%s qa=%s" % [REWARDED_ID,test_ads])
	print("HIGHSTACK_ADS: App Open unit=%s qa=%s" % [APP_OPEN_ID,test_ads])

func request_privacy() -> void:
	if privacy == null or privacy_busy: return
	privacy_busy = true
	set_status("privacy")
	privacy.request_consent()

func on_consent_finished(allowed: bool, required: bool, error: String) -> void:
	privacy_busy = false
	consent_allowed = allowed
	privacy_required = required
	print("HIGHSTACK_PRIVACY: allowed=%s options=%s error=%s" % [allowed,required,error])
	if not allowed:
		invalidate_app_open()
		if not ready_id.is_empty(): sdk.remove_rewarded_ad(ready_id)
		ready_id = ""
		set_status("privacy_failed")
		return
	if not sdk_ready and not initializing:
		initializing = true
		sdk.initialize()
	else: load_reward(); load_app_open()
	changed.emit()

func show_privacy_options() -> void:
	if privacy == null or privacy_busy or not privacy_required: return
	privacy_busy = true
	consent_allowed = false
	invalidate_app_open()
	if not ready_id.is_empty(): sdk.remove_rewarded_ad(ready_id)
	ready_id = ""
	set_status("privacy")
	privacy.show_privacy_options()

func set_status(value: String) -> void:
	status = value
	changed.emit()

func load_reward() -> void:
	if not consent_allowed:
		request_privacy()
		return
	if not sdk_ready or request_in_flight or ready_id != "" or fullscreen: return
	request_in_flight = true
	request_serial += 1
	var serial = request_serial
	set_status("loading")
	sdk.load_rewarded_ad(sdk.create_rewarded_ad_request())
	# A stuck/offline request must leave a retry route and never grant a reward.
	get_tree().create_timer(30.0).timeout.connect(func():
		if request_in_flight and serial == request_serial: request_in_flight=false; set_status("failed"))

func show_reward() -> bool:
	if ready_id.is_empty() or fullscreen or not sdk_ready or not consent_allowed: return false
	showing_id = ready_id
	ready_id = ""
	fullscreen = true
	last_fullscreen_at = Time.get_ticks_msec()
	set_status("showing")
	sdk.show_rewarded_ad(showing_id)
	return true

func grant_reward(ad_id: String) -> void:
	if ad_id.is_empty() or ad_id != showing_id or rewarded_ids.has(ad_id): return
	rewarded_ids[ad_id] = true
	earned.emit(REWARD_COINS)
	print("HIGHSTACK_REWARDED: granted once")

func close_ad(ad_id: String) -> void:
	fullscreen = false
	last_fullscreen_at = Time.get_ticks_msec()
	# Retain showing_id until the next show: SDK reward/dismiss callbacks can be reordered.
	if sdk != null: sdk.remove_rewarded_ad(ad_id)
	set_status("idle")
	load_reward()

func invalidate_app_open() -> void:
	app_open_loaded_at = -1
	app_open_loading = false
	if privacy != null: privacy.clear_app_open()

func load_app_open() -> void:
	if privacy == null or not sdk_ready or not consent_allowed or privacy_busy or fullscreen or app_open_loading: return
	if app_open_fresh(): return
	app_open_loading = true
	privacy.load_app_open(APP_OPEN_TEST_ID if test_ads else APP_OPEN_ID)

func app_open_fresh() -> bool:
	return app_open_loaded_at >= 0 and Time.get_ticks_msec()-app_open_loaded_at < OPEN_MAX_AGE_MS

func try_app_open(entry_allowed: bool) -> bool:
	if not entry_allowed or privacy == null or not sdk_ready or not consent_allowed or privacy_busy or fullscreen: return false
	if Time.get_ticks_msec()-last_fullscreen_at < OPEN_COOLDOWN_MS: return false
	if not app_open_fresh():
		load_app_open()
		return false
	app_open_loaded_at = -1
	app_open_showing = true
	fullscreen = true
	last_fullscreen_at = Time.get_ticks_msec()
	print("HIGHSTACK_APP_OPEN: show at foreground entry")
	privacy.show_app_open()
	return true

func close_app_open() -> void:
	if not app_open_showing: return
	app_open_showing = false
	fullscreen = false
	last_fullscreen_at = Time.get_ticks_msec()
	print("HIGHSTACK_APP_OPEN: closed")
	load_app_open()
