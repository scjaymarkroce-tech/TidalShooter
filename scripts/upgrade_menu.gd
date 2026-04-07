extends Control

var options := []
var upgrade_manager = UpgradeManager.new()
@onready var player = get_parent().get_node("Player")

@onready var bg_dimmer = $Panel
@onready var title_label = $Label
@onready var cards = []

var is_animating := false 

# 🔊 SOUND VARIABLE
var yeyy_sound_player: AudioStreamPlayer

func _ready():
	visible = false
	
	# --- 🔊 SETUP YEYY SOUND DYNAMICALLY ---
	yeyy_sound_player = AudioStreamPlayer.new()
	yeyy_sound_player.stream = load("res://ADDED/A_MUSIC/yeyy.mp3")
	# MUST be ALWAYS so it plays while the game is paused!
	yeyy_sound_player.process_mode = Node.PROCESS_MODE_ALWAYS 
	add_child(yeyy_sound_player)
	
	# Grab the EXACT positions you set in the editor so we can return to them safely
	cards = [
		{
			"panel": $Panel2, "button": $Button1, 
			"base_p_pos": $Panel2.position, "base_b_pos": $Button1.position
		},
		{
			"panel": $Panel4, "button": $Button2, 
			"base_p_pos": $Panel4.position, "base_b_pos": $Button2.position
		},
		{
			"panel": $Panel3, "button": $Button3, 
			"base_p_pos": $Panel3.position, "base_b_pos": $Button3.position
		}
	]
	
	# Connect hover effects dynamically
	for i in range(cards.size()):
		var btn = cards[i]["button"]
		btn.mouse_entered.connect(func(): _on_card_hover(i, true))
		btn.mouse_exited.connect(func(): _on_card_hover(i, false))


func open_menu():
	if is_animating: return
	is_animating = true
	
	_reset_ui_to_base_values()
	
	get_tree().paused = true
	visible = true
	player.process_mode = Node.PROCESS_MODE_DISABLED
	
	# 🎵 UPGRADE MUSIC LOGIC: Stop battle music, play upgrade music
	var main_node = get_parent()
	if main_node.has_node("MainBGM"): main_node.get_node("MainBGM").stop()
	if main_node.has_node("BossBGM"): main_node.get_node("BossBGM").stop()
	if main_node.has_node("UpgradeBGM"): main_node.get_node("UpgradeBGM").play()
	
	# Fetch Upgrade Options
	options = upgrade_manager.get_upgrade_options()
	
	$Button1.text = options[0].capitalize()
	$Button2.text = options[1].capitalize()
	if options.size() > 2:
		$Button3.text = options[2].capitalize()
		$Panel3.visible = true
		$Button3.visible = true
	else:
		$Panel3.visible = false
		$Button3.visible = false

	# --- 🎬 CINEMATIC ENTRANCE (FADE IN ONLY) ---
	bg_dimmer.modulate.a = 0.0
	title_label.modulate.a = 0.0
	
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(bg_dimmer, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(title_label, "modulate:a", 1.0, 0.4).set_delay(0.1)
	
	# Fade in the Cards
	for i in range(cards.size()):
		var card = cards[i]
		if not card["panel"].visible: continue 
		
		# Start invisible
		card["panel"].modulate.a = 0.0
		card["button"].modulate.a = 0.0
		
		var delay = 0.15 + (i * 0.1) # Fast stagger
		tween.parallel().tween_property(card["panel"], "modulate:a", 1.0, 0.4).set_delay(delay)
		tween.parallel().tween_property(card["button"], "modulate:a", 1.0, 0.4).set_delay(delay)

	await get_tree().create_timer(0.6, true, false, true).timeout
	is_animating = false


# --- 🖱️ DYNAMIC HOVER EFFECTS (NUDGE UP & SOFT GLOW) ---
func _on_card_hover(idx: int, is_hovering: bool):
	if is_animating: return 
	
	var card = cards[idx]
	var tween = create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	if is_hovering:
		# Float up slightly (-15 pixels) and add a very gentle brightness (1.1 instead of 1.3)
		tween.tween_property(card["panel"], "position:y", card["base_p_pos"].y - 15, 0.15).set_trans(Tween.TRANS_SINE)
		tween.tween_property(card["panel"], "modulate", Color(1.1, 1.1, 1.1, 1.0), 0.15)
		
		tween.tween_property(card["button"], "position:y", card["base_b_pos"].y - 15, 0.15).set_trans(Tween.TRANS_SINE)
		tween.tween_property(card["button"], "modulate", Color(1.1, 1.1, 1.1, 1.0), 0.15)
	else:
		# Return to normal editor position and color
		tween.tween_property(card["panel"], "position:y", card["base_p_pos"].y, 0.15).set_trans(Tween.TRANS_SINE)
		tween.tween_property(card["panel"], "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)
		
		tween.tween_property(card["button"], "position:y", card["base_b_pos"].y, 0.15).set_trans(Tween.TRANS_SINE)
		tween.tween_property(card["button"], "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)


func _on_Button1_pressed(): _finish_upgrade(0)
func _on_Button2_pressed(): _finish_upgrade(1)
func _on_Button3_pressed():
	if options.size() > 2: _finish_upgrade(2)

func _finish_upgrade(idx: int):
	if is_animating: return
	is_animating = true
	
	# 🔊 PLAY THE "YEYY" SOUND EFFECT HERE!
	if yeyy_sound_player:
		yeyy_sound_player.play()
	
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	# 🎬 CINEMATIC OUTRO
	for i in range(cards.size()):
		var card = cards[i]
		if not card["panel"].visible: continue
		
		if i == idx:
			# ✨ THE CHOSEN ONE: Floats up high and gets a premium soft golden/warm tint
			tween.parallel().tween_property(card["panel"], "position:y", card["base_p_pos"].y - 40, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			# Replaced 3.0 with a soft, warm brightening (1.2 red, 1.15 green, 0.95 blue)
			tween.parallel().tween_property(card["panel"], "modulate", Color(1.2, 1.15, 0.95, 1.0), 0.3) 
			
			tween.parallel().tween_property(card["button"], "position:y", card["base_b_pos"].y - 40, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(card["button"], "modulate", Color(1.2, 1.15, 0.95, 1.0), 0.3) 
			
		else:
			# 🗑️ THE REJECTS: Fade away quickly into the dark
			tween.parallel().tween_property(card["panel"], "modulate:a", 0.0, 0.2)
			tween.parallel().tween_property(card["button"], "modulate:a", 0.0, 0.2)

	# Fade the title out
	tween.parallel().tween_property(title_label, "modulate:a", 0.0, 0.2)
	
	# Wait for the player to feel the impact of their choice
	await get_tree().create_timer(0.5, true, false, true).timeout
	
	# Final fade out of everything
	var exit_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	exit_tween.tween_property(cards[idx]["panel"], "modulate:a", 0.0, 0.2)
	exit_tween.parallel().tween_property(cards[idx]["button"], "modulate:a", 0.0, 0.2)
	exit_tween.parallel().tween_property(bg_dimmer, "modulate:a", 0.0, 0.2)

	await exit_tween.finished

	# Apply the actual upgrade mechanics
	var choice = options[idx]
	upgrade_manager.apply_upgrade(choice, player)
	
	_reset_ui_to_base_values()
	
	# 🎵 Stop the upgrade music (The reset() function will automatically start the next wave's music)
	if get_parent().has_node("UpgradeBGM"): 
		get_parent().get_node("UpgradeBGM").stop()
	
	player.process_mode = Node.PROCESS_MODE_INHERIT
	visible = false
	get_tree().paused = false
	is_animating = false
	
	get_parent()._on_upgrade_menu_closed()


# Reset all positions and colors back to what you built in the editor
func _reset_ui_to_base_values():
	title_label.modulate.a = 1.0
	
	for i in range(cards.size()):
		cards[i]["panel"].position = cards[i]["base_p_pos"]
		cards[i]["panel"].modulate = Color(1.0, 1.0, 1.0, 1.0)
		
		cards[i]["button"].position = cards[i]["base_b_pos"]
		cards[i]["button"].modulate = Color(1.0, 1.0, 1.0, 1.0)
