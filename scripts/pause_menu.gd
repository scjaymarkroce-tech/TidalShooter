extends CanvasLayer

@onready var main = get_node("/root/Main")

var btn_scales = {}

# 🔊 SOUND VARIABLE
var click_sound_player: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	
	click_sound_player = AudioStreamPlayer.new()
	click_sound_player.stream = load("res://ADDED/A_MUSIC/click.wav")
	click_sound_player.process_mode = Node.PROCESS_MODE_ALWAYS 
	add_child(click_sound_player)

	var buttons = get_button_nodes(self)
	
	for btn in buttons:
		btn.pivot_offset = btn.size / 2.0
		btn_scales[btn] = btn.scale
		
		btn.mouse_entered.connect(func(): _hover_btn(btn, true))
		btn.mouse_exited.connect(func(): _hover_btn(btn, false))
		# WE REMOVED THE DYNAMIC SOUND CONNECTION HERE


func play_click_sound():
	if click_sound_player:
		click_sound_player.play()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if main.has_node("GameOver") and main.get_node("GameOver").visible: return
		if main.has_node("UpgradeMenu") and main.get_node("UpgradeMenu").visible: return
		
		if get_tree().paused and visible:
			resume_game()
		elif not get_tree().paused:
			pause_game()

func pause_game() -> void:
	get_tree().paused = true
	show()
	scale = Vector2(0.8, 0.8)
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func resume_game() -> void:
	hide()
	get_tree().paused = false


# --- BUTTON CLICK FUNCTIONS ---

func _on_continue_button_pressed() -> void:
	play_click_sound() # 🔊 Call sound manually
	resume_game()

func _on_restart_wave_button_pressed() -> void:
	play_click_sound() # 🔊 Call sound manually
	resume_game()
	main.reset() 

func _on_quit_button_pressed() -> void:
	play_click_sound() # 🔊 Call sound manually
	resume_game()
	
	# Wait 0.1s so the sound finishes before the scene gets destroyed!
	await get_tree().create_timer(0.1).timeout 
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _hover_btn(btn: Button, is_hovering: bool):
	if btn.disabled: return
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if is_hovering:
		tween.tween_property(btn, "scale", btn_scales[btn] * 1.1, 0.1).set_trans(Tween.TRANS_SINE)
	else:
		tween.tween_property(btn, "scale", btn_scales[btn], 0.1).set_trans(Tween.TRANS_SINE)

func get_button_nodes(node: Node) -> Array:
	var buttons = []
	for child in node.get_children():
		if child is Button:
			buttons.append(child)
		if child.get_child_count() > 0:
			buttons.append_array(get_button_nodes(child))
	return buttons
