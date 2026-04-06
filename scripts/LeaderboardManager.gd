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
		
	# FORCE A RESORT EVERY TIME WE LOAD (Fixes old bad data!)
	sort_leaderboard()

func save_leaderboard():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_var(leaderboard_data)
	file.close()

func submit_score(name: String, score: int) -> void:
	leaderboard_data.append({ "name": name, "score": score })
	sort_leaderboard()
	save_leaderboard()

# Creates a dedicated sorting function to guarantee order
func sort_leaderboard():
	# In Godot 4, you can use a lambda function directly inside sort_custom
	leaderboard_data.sort_custom(func(a, b): return int(a["score"]) > int(b["score"]))
	
	# Trim to max entries AFTER sorting
	if leaderboard_data.size() > MAX_ENTRIES:
		leaderboard_data = leaderboard_data.slice(0, MAX_ENTRIES)
