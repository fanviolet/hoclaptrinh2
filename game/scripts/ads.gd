extends Node

signal changed
signal earned(amount: int)
const REWARD_COINS = 120
# Only Google's official demo inventory is enabled in this build.
const TEST_MODE = true
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
	if not Engine.has_singleton("AdmobPlugin"):
		set_status("unavailable")
		return
	sdk = Admob.new()
	sdk.is_real = false
	sdk.process_mode = Node.PROCESS_MODE_ALWAYS
	sdk.initialization_completed.connect(func(_info): sdk_ready=true; load_reward())
	sdk.rewarded_ad_loaded.connect(func(info,_response):
		ready_id=info.get_ad_id(); request_in_flight=false; set_status("ready"); print("HIGHSTACK_ADS: rewarded test ad loaded"))
	sdk.rewarded_ad_failed_to_load.connect(func(_info,_error): request_in_flight=false; set_status("failed"))
	sdk.rewarded_ad_user_earned_reward.connect(func(info,_reward): grant_reward(info.get_ad_id()))
	sdk.rewarded_ad_dismissed_full_screen_content.connect(func(info): close_ad(info.get_ad_id()))
	sdk.rewarded_ad_failed_to_show_full_screen_content.connect(func(info,_error): close_ad(info.get_ad_id()))
	add_child(sdk)
	sdk.set_request_configuration(sdk.create_request_configuration())
	set_status("loading")
	sdk.initialize()
	print("HIGHSTACK_ADS: native SDK available; Google test ads only")

func set_status(value: String) -> void:
	status = value
	changed.emit()

func load_reward() -> void:
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
	if ready_id.is_empty() or fullscreen or not sdk_ready: return false
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
