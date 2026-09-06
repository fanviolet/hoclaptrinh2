extends RefCounted

# An offline provider implements the same score-event boundary as a future server.
# Human mode must use authenticated, server-validated events, never client awards.
signal opponent_updated(height: float, score: int)
signal match_finished
const PROTOCOL_VERSION = 1
var remaining = 90.0
var opponent_height = 0.0
var opponent_score = 0
var difficulty = 1
var seed_value = 0
var next_move = 3.0
var running = false
var bot_rng = RandomNumberGenerator.new()

func start(seed_number: int, level: int) -> void:
	seed_value = seed_number
	difficulty = clampi(level,0,2)
	bot_rng.seed = seed_number + 741
	remaining = 90.0
	opponent_height = 0.0
	opponent_score = 0
	next_move = 3.0
	running = true

func tick(delta: float) -> void:
	if not running: return
	remaining = maxf(0.0,remaining-delta)
	next_move -= delta
	if next_move <= 0:
		next_move = bot_rng.randf_range(3.0,5.0) / (0.8 + difficulty*0.22)
		if bot_rng.randf() < 0.77 + difficulty*0.06:
			opponent_height += bot_rng.randf_range(0.25,0.9)
			opponent_score += int(bot_rng.randf_range(90,180))
		else:
			opponent_height = maxf(0.0,opponent_height-bot_rng.randf_range(0.2,0.8))
		opponent_updated.emit(opponent_height,opponent_score)
	if remaining <= 0:
		running = false
		match_finished.emit()

func human_connection_status() -> Dictionary:
	return {"available":false,"reason":"SERVER_NOT_CONFIGURED","protocol":PROTOCOL_VERSION}

func snapshot() -> Dictionary:
	return {"protocol":PROTOCOL_VERSION,"seed":seed_value,"remaining":remaining,
		"opponent_height":opponent_height,"opponent_score":opponent_score,"provider":"offline_bot"}
