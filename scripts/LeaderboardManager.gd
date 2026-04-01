extends Node

const SAVE_PATH := "user://leaderboard.save"
const MAX_ENTRIES := 10

var leaderboard_data: Array = []

func _ready():
	load_leaderboard()

func load_leaderboard():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		leaderboard_data = file.get_var()
		file.close()
	else:
		leaderboard_data = []

func save_leaderboard():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_var(leaderboard_data)
	file.close()

func submit_score(name: String, score: int) -> void:
	leaderboard_data.append({ "name": name, "score": score })
	leaderboard_data.sort_custom(_sort_scores)
	leaderboard_data = leaderboard_data.slice(0, MAX_ENTRIES)
	save_leaderboard()

func _sort_scores(a, b):
	return int(b["score"]) - int(a["score"])
	
