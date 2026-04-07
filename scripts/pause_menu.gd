extends CanvasLayer

@onready var main = get_node("/root/Main")

# We will store the original sizes of your buttons here for the hover animations
var btn_scales = {}

func _ready() -> void:
	# 🛡️ CRITICAL: This ensures the pause menu script keeps running even when the game is frozen!
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	hide()

	# --- SETUP JUICY HOVER ANIMATIONS ---
	# We search through the pause menu to find your buttons, no matter where you put them inside!
	var buttons = get_button_nodes(self)
	
	for btn in buttons:
		# Set the pivot to the center so they scale from the middle
		btn.pivot_offset = btn.size / 2.0
		btn_scales[btn] = btn.scale
		
		# Connect the hover signals
		btn.mouse_entered.connect(func(): _hover_btn(btn, true))
		btn.mouse_exited.connect(func(): _hover_btn(btn, false))


# ⌨️ INPUT HANDLING FOR ESCAPE KEY
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): # "ui_cancel" is Escape by default
		
		# Prevent pausing if Game Over or Upgrade Menu are currently active!
		if main.has_node("GameOver") and main.get_node("GameOver").visible: return
		if main.has_node("UpgradeMenu") and main.get_node("UpgradeMenu").visible: return
		
		if get_tree().paused and visible:
			resume_game()
		elif not get_tree().paused:
			pause_game()


func pause_game() -> void:
	get_tree().paused = true
	show()
	
	# Optional: Add a quick pop-in animation for the menu
	scale = Vector2(0.8, 0.8)
	#modulate.a = 0.0
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	#tween.tween_property(self, "modulate:a", 1.0, 0.2)


func resume_game() -> void:
	hide()
	get_tree().paused = false


# --- BUTTON CLICK FUNCTIONS ---
# (Make sure to connect your buttons to these in the Editor's Node Tab!)

func _on_continue_button_pressed() -> void:
	resume_game()


func _on_restart_wave_button_pressed() -> void:
	resume_game()
	
	# Optional: Reset the score to 0 when they restart a wave
	# ScoreManager.reset_score() 
	
	# This calls your exact reset() function in main.gd!
	main.reset() 


func _on_quit_button_pressed() -> void:
	resume_game()
	# Adjust this path if your main menu scene is named differently!
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


# --- HELPER FUNCTIONS FOR ANIMATIONS ---

func _hover_btn(btn: Button, is_hovering: bool):
	if btn.disabled: return
	
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if is_hovering:
		tween.tween_property(btn, "scale", btn_scales[btn] * 1.1, 0.1).set_trans(Tween.TRANS_SINE)
	else:
		tween.tween_property(btn, "scale", btn_scales[btn], 0.1).set_trans(Tween.TRANS_SINE)


# A clever little function that finds all the Buttons inside your Pause Menu automatically!
func get_button_nodes(node: Node) -> Array:
	var buttons = []
	for child in node.get_children():
		if child is Button:
			buttons.append(child)
		if child.get_child_count() > 0:
			buttons.append_array(get_button_nodes(child))
	return buttons
