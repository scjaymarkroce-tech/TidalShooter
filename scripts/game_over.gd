extends CanvasLayer

var highscore = 0
var player_score = 0

func show_game_over(score: int, waves_survived: int):
	player_score = score
	$Panel/ScoreLabel.text = "SCORE: %d" % score
	$Panel/WavesSurvivedLabel.text = "WAVES SURVIVED: %d" % waves_survived

	highscore = load_highscore()
	$Panel/HighScoreLabel.text = "HIGH SCORE: %d" % highscore
	$Panel/NameLineEdit.text = ""
	$Panel/SubmitButton.disabled = false
	show()

func _ready():
	$Panel/SubmitButton.pressed.connect(_on_submit_pressed)
	$Panel/PlayAgainButton.pressed.connect(_on_play_again)
	$Panel/MainMenuButton.pressed.connect(_on_main_menu)

func _on_submit_pressed():
	var name = $Panel/NameLineEdit.text.strip_edges()
	if name == "":
		name = "PLAYER"
	# Save new personal highscore if beaten
	if player_score > highscore:
		highscore = player_score
		save_highscore(player_score, name)
		$Panel/HighScoreLabel.text = "HIGH SCORE: %d" % highscore
	$Panel/SubmitButton.disabled = true
	LeaderboardManager.submit_score(name, player_score)  # <-- Fixed here

func save_highscore(score: int, name: String) -> void:
	var data = {"name": name, "score": score}
	var file = FileAccess.open("user://highscore.save", FileAccess.WRITE)
	file.store_var(data)
	file.close()

func load_highscore() -> int:
	if FileAccess.file_exists("user://highscore.save"):
		var file = FileAccess.open("user://highscore.save", FileAccess.READ)
		var data = file.get_var()
		file.close()
		return int(data.get("score", 0))
	else:
		return 0

func _on_play_again():
	hide()
	get_tree().call_deferred("reload_current_scene")

func _on_main_menu():
	hide()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")   # adjust as needed
