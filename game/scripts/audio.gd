extends Node

var music: AudioStreamPlayer
var voices: Array[AudioStreamPlayer] = []
var sounds: Dictionary = {}
var cursor = 0

func _ready() -> void:
	for bus in ["Music","SFX"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count-1,bus)
	music = AudioStreamPlayer.new()
	music.bus = "Music"
	add_child(music)
	if ResourceLoader.exists("res://assets/audio/skyline.wav"):
		music.stream = load("res://assets/audio/skyline.wav")
		music.finished.connect(func(): music.play())
		if DisplayServer.get_name() != "headless": music.play()
	for i in range(8):
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		voices.append(player)
	for key in ["tap","drop","wood","metal","perfect","coin","rescue","lose","win"]:
		var path = "res://assets/audio/%s.wav" % key
		if ResourceLoader.exists(path): sounds[key] = load(path)

func apply_settings(settings: Dictionary) -> void:
	for pair in [["Music","music"],["SFX","sfx"]]:
		var index = AudioServer.get_bus_index(pair[0])
		AudioServer.set_bus_volume_db(index,linear_to_db(maxf(0.0001,float(settings[pair[1]]))))
		AudioServer.set_bus_mute(index,float(settings[pair[1]]) <= 0)

func play(key: String, pitch: float = 1.0) -> void:
	if DisplayServer.get_name() == "headless": return
	if not sounds.has(key): return
	var player = voices[cursor % voices.size()]
	cursor += 1
	player.stream = sounds[key]
	player.pitch_scale = clampf(pitch,0.75,1.5)
	player.play()

func shutdown() -> void:
	music.stop()
	music.stream = null
	for player in voices:
		player.stop()
		player.stream = null
	sounds.clear()

func _exit_tree() -> void:
	shutdown()
