extends Node

func show_damage(value: int, start_pos: Vector2):
	var label = Label.new()
	
	# Randomize the exact start position slightly so shotgun blasts don't perfectly overlap!
	var random_start_offset = Vector2(randf_range(-15.0, 15.0), randf_range(-15.0, 15.0))
	label.global_position = start_pos + random_start_offset
	label.z_index = 50 
	
	# --- 🎨 VISUAL ENHANCEMENTS ---
	# CRITICAL HIT THRESHOLD: 100 Damage or more!
	var is_crit = value >= 100 
	
	if is_crit:
		label.text = str(value) + "!"
		label.add_theme_font_size_override("font_size", 36)
		label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.1)) # Bright Gold
		label.add_theme_color_override("font_outline_color", Color(0.6, 0.1, 0.0)) # Dark Red Outline
		label.add_theme_constant_override("outline_size", 8)
	else:
		label.text = str(value)
		label.add_theme_font_size_override("font_size", 24)
		label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0)) # Pure White
		label.add_theme_color_override("font_outline_color", Color(0.3, 0.0, 0.0)) # Dark Red Outline
		label.add_theme_constant_override("outline_size", 6)
		
	# Add a Drop Shadow to make it pop off the background
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	
	# Add to the scene
	var current_scene = get_tree().current_scene
	if current_scene:
		current_scene.add_child(label)
		
	# Set pivot to the center so scaling and rotation happens from the middle
	label.pivot_offset = label.get_minimum_size() / 2.0
	label.position -= label.get_minimum_size() / 2.0
	
	# --- 🎬 PHYSICS & KINETIC ANIMATION ---
	var x_dir = randf_range(-1.0, 1.0)
	var target_x = label.position.x + (x_dir * randf_range(30.0, 60.0))
	var jump_height = randf_range(30.0, 50.0)
	var target_y = label.position.y - jump_height
	var random_rot = randf_range(-0.3, 0.3) # Give it a slight chaotic tilt
	
	# 1. THE POP (Explodes big, then settles)
	label.scale = Vector2.ZERO
	var pop_tween = create_tween()
	var max_scale = Vector2(1.5, 1.5) if is_crit else Vector2(1.3, 1.3)
	pop_tween.tween_property(label, "scale", max_scale, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop_tween.chain().tween_property(label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# 2. THE ARC (Bursts upwards and outwards, then slightly falls)
	var move_tween = create_tween().set_parallel(true)
	move_tween.tween_property(label, "position:x", target_x, 0.5).set_trans(Tween.TRANS_LINEAR)
	# Jump up
	move_tween.tween_property(label, "position:y", target_y, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Fall down slightly (Gravity)
	move_tween.chain().tween_property(label, "position:y", target_y + 15, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	# 3. THE TILT
	var rot_tween = create_tween()
	rot_tween.tween_property(label, "rotation", random_rot, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# 4. FADE & DESTROY
	var fade_tween = create_tween()
	fade_tween.tween_property(label, "modulate:a", 0.0, 0.2).set_delay(0.35)
	fade_tween.chain().tween_callback(label.queue_free)
