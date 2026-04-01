extends Control

func _ready():
	update_leaderboard()
	$MainPanel/MainMenuButton.pressed.connect(_on_main_menu_button_pressed)

func update_leaderboard():
	var entries = LeaderboardManager.leaderboard_data
	var text = "	RANK       			SCORE\n"
	for i in range(min(entries.size(), 10)):
		var entry = entries[i]
		text += "%2d.   	%-12s  			%5d\n" % [i + 1, entry.get("name", "???"), entry.get("score", 0)]
	$MainPanel/VBoxContainer/LeaderboardList.text = text

func _on_main_menu_button_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
