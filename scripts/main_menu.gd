extends Control

# Use get_node_or_null so the game DOES NOT CRASH if these are missing!
@onready var bg = get_node_or_null("bg")
@onready var door = get_node_or_null("Door")
@onready var title = get_node_or_null("Title")
@onready var cloud_template = get_node_or_null("CloudTemplate")

# Buttons
@onready var start_btn = get_node_or_null("StartButton")
@onready var quit_btn = get_node_or_null("QuitButton")
@onready var lead_btn = get_node_or_null("LeaderboardButton")
@onready var inst_btn = get_node_or_null("InstructionsButton")

# Popup Container
@onready var popup_rect = get_node_or_null("PopupRect")
@onready var popup_title = get_node_or_null("PopupRect/PopupTitle")
@onready var popup_content = get_node_or_null("PopupRect/PopupContent")
@onready var close_btn = get_node_or_null("PopupRect/CloseButton")

var is_starting_game := false
var original_title_pos: Vector2
var original_title_scale: Vector2

func _ready() -> void:
	if popup_rect: popup_rect.visible = false
	
	# 1. SETUP THE EPIC TITLE ENTRANCE (If Title exists)
	if title:
		original_title_pos = title.position
		original_title_scale = title.scale
		title.position.y -= 150
		title.scale = original_title_scale * 1.5
		title.modulate.a = 0.0
	
	# Hide buttons initially
	for btn in [start_btn, quit_btn, lead_btn, inst_btn]:
		if btn: btn.modulate.a = 0.0
	
	# 2. START THE CALM SCENE
	if door: door.play("default") 
	
	var intro_tween = create_tween().set_parallel(true)
	
	if title:
		intro_tween.tween_property(title, "position:y", original_title_pos.y, 3.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		intro_tween.tween_property(title, "scale", original_title_scale, 3.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		intro_tween.tween_property(title, "modulate:a", 1.0, 2.0)
		intro_tween.chain().tween_callback(start_title_pulse)
	
	# Buttons fade in
	var delay = 2.5
	for btn in [start_btn, lead_btn, inst_btn, quit_btn]:
		if btn:
			var fade_tween = create_tween()
			fade_tween.tween_property(btn, "modulate:a", 1.0, 0.5).set_delay(delay)
			delay += 0.2
	
	# 3. ☁️ START CLOUD SPAWNER (If Cloud exists)
	if cloud_template:
		var cloud_timer = Timer.new()
		cloud_timer.wait_time = 2.5
		cloud_timer.autostart = true
		cloud_timer.timeout.connect(spawn_cloud)
		add_child(cloud_timer)
		for i in range(4): spawn_cloud(true)
	
	# 4. CONNECT BUTTONS safely
	if start_btn: start_btn.pressed.connect(_on_start_button_pressed)
	if quit_btn: quit_btn.pressed.connect(_on_quit_button_pressed)
	if inst_btn: inst_btn.pressed.connect(func(): open_popup("INSTRUCTIONS", "WASD / Arrows to Move\nMouse to Aim & Shoot\nSpace to Dodge\n\nSurvive the waves and defeat the bosses!"))
	
	# THE TOP 3 LEADERBOARD CONNECTION
	if lead_btn: lead_btn.pressed.connect(func(): open_popup("LEADERBOARDS", get_top_3_leaderboard_text()))
	if close_btn: close_btn.pressed.connect(close_popup)


# --- ✨ ANIMATIONS ---
func start_title_pulse():
	if is_starting_game or not title: return
	var pulse = create_tween().set_loops().set_parallel(true)
	pulse.tween_property(title, "scale", original_title_scale * 1.03, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(title, "position:y", original_title_pos.y - 10, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.chain().tween_property(title, "scale", original_title_scale, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.parallel().tween_property(title, "position:y", original_title_pos.y, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# --- 📜 POPUP RECT LOGIC ---
func get_top_3_leaderboard_text() -> String:
	LeaderboardManager.load_leaderboard()
	var entries = LeaderboardManager.leaderboard_data
	var text = "   RANK          NAME          SCORE\n\n"
	
	for i in range(min(entries.size(), 3)):
		var entry = entries[i]
		text += "    %d.          %-12s      %d\n\n" % [i + 1, entry.get("name", "PLAYER"), entry.get("score", 0)]
		
	if entries.is_empty():
		text += "\n\n        NO SCORES YET!"
	return text

func open_popup(title_text: String, content_text: String):
	if is_starting_game or not popup_rect: return
	
	if popup_title: popup_title.text = title_text
	if popup_content: popup_content.text = content_text
	
	popup_rect.scale = Vector2.ZERO 
	popup_rect.visible = true
	var tween = create_tween()
	tween.tween_property(popup_rect, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func close_popup():
	if not popup_rect: return
	var tween = create_tween()
	tween.tween_property(popup_rect, "scale", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): popup_rect.visible = false)


# --- ☁️ HORIZONTAL CLOUDS ---
func spawn_cloud(random_start_pos := false):
	if not cloud_template or is_starting_game: return
	var cloud = cloud_template.duplicate()
	cloud.visible = true
	add_child(cloud)
	move_child(cloud, 1) 
	cloud.scale = cloud_template.scale * randf_range(0.8, 1.5)
	cloud.modulate.a = randf_range(0.6, 0.9) 
	
	var screen_width = get_viewport_rect().size.x
	var start_y = randf_range(10, 150) 
	var start_x = -200 
	if random_start_pos: start_x = randf_range(0, screen_width) 
	cloud.position = Vector2(start_x, start_y)
	
	var drift_time = randf_range(25.0, 50.0) 
	var target_x = screen_width + 200 
	var tween = create_tween()
	var distance_ratio = (target_x - cloud.position.x) / (target_x + 200)
	tween.tween_property(cloud, "position:x", target_x, drift_time * distance_ratio)
	tween.tween_callback(cloud.queue_free)


# --- 🚪 THE DOOR OPENING SEQUENCE ---
func _on_start_button_pressed() -> void:
	if is_starting_game: return
	is_starting_game = true
	
	if popup_rect: popup_rect.visible = false
	
	var ui_tween = create_tween().set_parallel(true)
	for btn in [start_btn, quit_btn, lead_btn, inst_btn]:
		if btn: ui_tween.tween_property(btn, "modulate:a", 0.0, 0.5)
	if title: ui_tween.tween_property(title, "modulate:a", 0.0, 0.5)
	
	await get_tree().create_timer(1.0).timeout
	
	if door: 
		door.play("open") 
		pivot_offset = door.position
		var zoom_tween = create_tween().set_parallel(true)
		zoom_tween.tween_property(self, "scale", Vector2(2.5, 2.5), 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await door.animation_finished
	
	var flash = ColorRect.new()
	flash.set_anchors_preset(PRESET_FULL_RECT)
	flash.color = Color(1, 1, 1, 0)
	flash.z_index = 100
	add_child(flash)
	
	var flash_tween = create_tween()
	flash_tween.tween_property(flash, "color:a", 1.0, 0.5) 
	flash_tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))

func _on_quit_button_pressed() -> void:
	get_tree().quit()
