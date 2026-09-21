extends Node

signal changed
signal earned(amount: int)
const REWARD_COINS = 120
# Publisher-supplied rewarded unit; Android emulators remain Google test devices.
const REWARDED_ID = "ca-app-pub-7928274342057259/8779093357"
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
	sdk.is_real = true
	sdk.android_real_rewarded_id = REWARDED_ID
	sdk.process_mode = Node.PROCESS_MODE_ALWAYS
	sdk.initialization_completed.connect(func(_info): sdk_ready=true; load_reward())
	sdk.rewarded_ad_loaded.connect(func(info,_response):
		request_in_flight=false
		if not consent_allowed: sdk.remove_rewarded_ad(info.get_ad_id()); return
		ready_id=info.get_ad_id(); set_status("ready"); print("HIGHSTACK_ADS: rewarded ad loaded"))
	sdk.rewarded_ad_failed_to_load.connect(func(_info,_error): request_in_flight=false; set_status("failed"))
	sdk.rewarded_ad_user_earned_reward.connect(func(info,_reward): grant_reward(info.get_ad_id()))
	sdk.rewarded_ad_dismissed_full_screen_content.connect(func(info): close_ad(info.get_ad_id()))
	sdk.rewarded_ad_failed_to_show_full_screen_content.connect(func(info,_error): close_ad(info.get_ad_id()))
	add_child(sdk)
	sdk.set_request_configuration(sdk.create_request_configuration())
	privacy = Engine.get_singleton("HighStackPrivacy")
	privacy.consent_finished.connect(on_consent_finished)
	request_privacy()
	print("HIGHSTACK_ADS: publisher rewarded unit configured")

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
		if not ready_id.is_empty(): sdk.remove_rewarded_ad(ready_id)
		ready_id = ""
		set_status("privacy_failed")
		return
	if not sdk_ready and not initializing:
		initializing = true
		sdk.initialize()
	else: load_reward()
	changed.emit()

func show_privacy_options() -> void:
	if privacy == null or privacy_busy or not privacy_required: return
	privacy_busy = true
	consent_allowed = false
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
	set_status("showing")
	sdk.show_rewarded_ad(showing_id)
	return true

func grant_reward(ad_id: String) -> void:
	if ad_id.is_empty() or ad_id != showing_id or rewarded_ids.has(ad_id): return
	rewarded_ids[ad_id] = true
	earned.emit(REWARD_COINS)

func close_ad(ad_id: String) -> void:
	fullscreen = false
	# Retain showing_id until the next show: SDK reward/dismiss callbacks can be reordered.
	if sdk != null: sdk.remove_rewarded_ad(ad_id)
	set_status("idle")
	load_reward()
