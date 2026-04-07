extends CanvasLayer

var highscore = 0
var player_score = 0
var btn_scales = {}
var bg_dimmer: ColorRect

# 🔊 SOUND VARIABLE
var click_sound_player: AudioStreamPlayer

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	click_sound_player = AudioStreamPlayer.new()
	click_sound_player.stream = load("res://ADDED/A_MUSIC/click.wav")
	click_sound_player.process_mode = Node.PROCESS_MODE_ALWAYS 
	add_child(click_sound_player)
	
	bg_dimmer = ColorRect.new()
	bg_dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_dimmer.color = Color(0.2, 0.0, 0.0, 0.0) 
	bg_dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg_dimmer)
	move_child(bg_dimmer, 0) 
	
	$Panel/SubmitButton.pressed.connect(_on_submit_pressed)
	$Panel/PlayAgainButton.pressed.connect(_on_play_again)
	$Panel/MainMenuButton.pressed.connect(_on_main_menu)
	
	var buttons = [$Panel/SubmitButton, $Panel/PlayAgainButton, $Panel/MainMenuButton]
	for btn in buttons:
		btn.pivot_offset = btn.size / 2.0
		btn_scales[btn] = btn.scale
		btn.mouse_entered.connect(func(): _hover_btn(btn, true))
		btn.mouse_exited.connect(func(): _hover_btn(btn, false))
		# WE REMOVED THE DYNAMIC SOUND CONNECTION HERE

func play_click_sound():
	if click_sound_player:
		click_sound_player.play()

func show_game_over(score: int, waves_survived: int):
	player_score = score
	highscore = load_highscore()
	
	$Panel/ScoreLabel.text = "SCORE: 0"
	$Panel/WavesSurvivedLabel.text = "WAVES SURVIVED: 0"
	$Panel/HighScoreLabel.text = "HIGH SCORE: %d" % highscore
	$Panel/HighScoreLabel.modulate = Color(1, 1, 1, 1) 
	$Panel/NameLineEdit.text = ""
	$Panel/SubmitButton.disabled = false
	
	show()
	$Panel.modulate.a = 0.0
	$Panel.position.y -= 100 
	
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(bg_dimmer, "color:a", 0.7, 0.5)
	tween.parallel().tween_property($Panel, "position:y", $Panel.position.y + 100, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property($Panel, "modulate:a", 1.0, 0.4)
	
	tween.tween_method(update_score_label, 0, player_score, 1.0).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_method(update_waves_label, 0, waves_survived, 1.0).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	if player_score > highscore and player_score > 0:
		tween.chain().tween_callback(play_high_score_celebration)

func update_score_label(value: int):
	$Panel/ScoreLabel.text = "SCORE: %d" % value

func update_waves_label(value: int):
	$Panel/WavesSurvivedLabel.text = "WAVES SURVIVED: %d" % value

func play_high_score_celebration():
	var hs_label = $Panel/HighScoreLabel
	hs_label.text = "🏆 NEW HIGH SCORE: %d! 🏆" % player_score
	
	var pulse = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_loops(3)
	pulse.tween_property(hs_label, "modulate", Color(1.0, 0.8, 0.2, 1.0), 0.15) 
	pulse.tween_property(hs_label, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)
	
	var shake = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	hs_label.pivot_offset = hs_label.size / 2.0
	shake.tween_property(hs_label, "scale", Vector2(1.2, 1.2), 0.2).set_trans(Tween.TRANS_BACK)
	shake.tween_property(hs_label, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_SINE)

func _hover_btn(btn: Button, is_hovering: bool):
	if btn.disabled: return
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if is_hovering:
		tween.tween_property(btn, "scale", btn_scales[btn] * 1.1, 0.1).set_trans(Tween.TRANS_SINE)
	else:
		tween.tween_property(btn, "scale", btn_scales[btn], 0.1).set_trans(Tween.TRANS_SINE)

# --- DATA LOGIC ---
func _on_submit_pressed():
	play_click_sound() # 🔊 Call sound manually
	
	var name = $Panel/NameLineEdit.text.strip_edges()
	if name == "": name = "PLAYER"
		
	if player_score > highscore:
		highscore = player_score
		save_highscore(player_score, name)
		
	$Panel/SubmitButton.disabled = true
	$Panel/SubmitButton.text = "SUBMITTED!"
	
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property($Panel/SubmitButton, "modulate", Color(0.5, 1.0, 0.5), 0.2)
	LeaderboardManager.submit_score(name, player_score) 

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
	else: return 0

func _on_play_again():
	play_click_sound() # 🔊 Call sound manually
	hide()
	get_tree().paused = false 
	await get_tree().create_timer(0.1).timeout # Wait for sound
	get_tree().call_deferred("reload_current_scene")

func _on_main_menu():
	play_click_sound() # 🔊 Call sound manually
	hide()
	get_tree().paused = false 
	await get_tree().create_timer(0.1).timeout # Wait for sound
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")   
