extends CharacterBody2D

@onready var main = get_node("/root/Main")
@onready var player = get_node("/root/Main/Player")
@onready var dash_line = $DashLine

var explosion_scene := preload("res://scenes/explosion.tscn")
var item_scene := preload("res://scenes/item.tscn")

signal hit_player

# Boss stats
var health: int = 1050  
var max_health: int = 1050
var speed: int = 70     
var alive := false # Starts false during warning
var is_spawning := true 
var phase := 1 
var is_transitioning := false 

const DROP_CHANCE : float = 1.0  
var direction := Vector2.ZERO

# Dash Combo System Variables
var is_dashing := false
var dash_speed := 1800
var dash_direction := Vector2.ZERO
var can_use_abilities := false
var dashes_left := 0 
var combo_in_progress := false 

# Animation tracking
var anim_run := "run"
var anim_attack := "attack"

# ✨ EPIC UI VARIABLES
var boss_ui_layer: CanvasLayer
var world_dimmer: ColorRect
var big_hp_bar: ProgressBar
var damage_catchup_bar: ProgressBar
var boss_name_label: Label

func _ready() -> void:
	visible = false
	set_physics_process(false)
	$Area2D.set_deferred("monitoring", false)
	
	if has_node("ProgressBar"): $ProgressBar.visible = false
	if dash_line: dash_line.visible = false
	
	$DashCooldownTimer.stop()
		
	show_warning_sequence()

func _exit_tree() -> void:
	if is_instance_valid(boss_ui_layer):
		boss_ui_layer.queue_free()
	Engine.time_scale = 1.0 


# --- 🎬 DRAMATIC BOSS INTRO ---
func show_warning_sequence():
	get_tree().paused = true
	
	var warning_layer = CanvasLayer.new()
	warning_layer.layer = 100
	main.add_child(warning_layer)
	
	var dark_bg = ColorRect.new()
	dark_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	dark_bg.color = Color(0.1, 0.0, 0.0, 0.6) 
	dark_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	warning_layer.add_child(dark_bg)
	
	var label = Label.new()
	label.text = "⚠️ WARNING ⚠️\nBOSS APPROACHING"
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position.y -= 50
	label.add_theme_font_size_override("font_size", 60)
	label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	label.add_theme_constant_override("outline_size", 12)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	warning_layer.add_child(label)
	
	var tween = create_tween().set_loops(3)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) 
	tween.tween_property(label, "modulate:a", 0.1, 0.25)
	tween.tween_property(label, "modulate:a", 1.0, 0.25)
	
	await get_tree().create_timer(1.5, true, false, true).timeout
	warning_layer.queue_free()
	
	get_tree().paused = false
	
	# 🎵 PLAY THE BOSS MUSIC NOW THAT THE WARNING IS DONE!
	if main.has_node("BossBGM"):
		main.get_node("BossBGM").play()
		
		
	start_actual_boss_fight()

func start_actual_boss_fight():
	is_spawning = false
	alive = true
	visible = true
	max_health = health
	set_physics_process(true)
	$Area2D.set_deferred("monitoring", true)
	
	direction = (player.position - position).normalized()
	$AnimatedSprite2D.play(anim_run)
	setup_epic_boss_ui()
	
	await get_tree().create_timer(3.0, true, false, true).timeout
	can_use_abilities = true
	$DashCooldownTimer.start()

# --- ✨ EPIC BOSS UI ---
func setup_epic_boss_ui():
	boss_ui_layer = CanvasLayer.new()
	boss_ui_layer.layer = 50 
	main.add_child(boss_ui_layer)
	
	world_dimmer = ColorRect.new()
	world_dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	world_dimmer.color = Color(0, 0, 0, 0.0) 
	world_dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_ui_layer.add_child(world_dimmer)
	
	damage_catchup_bar = ProgressBar.new()
	damage_catchup_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	damage_catchup_bar.offset_top = -100 
	damage_catchup_bar.offset_bottom = -70
	damage_catchup_bar.offset_left = 200
	damage_catchup_bar.offset_right = -200
	damage_catchup_bar.show_percentage = false
	damage_catchup_bar.max_value = max_health
	damage_catchup_bar.value = 0 
	damage_catchup_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var catchup_bg = StyleBoxFlat.new()
	catchup_bg.bg_color = Color(0.1, 0.05, 0.05, 0.9) 
	catchup_bg.border_width_bottom = 8
	catchup_bg.border_width_top = 8
	catchup_bg.border_width_left = 8
	catchup_bg.border_width_right = 8
	catchup_bg.border_color = Color(0.6, 0.6, 0.8, 1.0) # Iron/Steel color for sewer boss
	catchup_bg.corner_radius_top_left = 12
	catchup_bg.corner_radius_top_right = 12
	catchup_bg.corner_radius_bottom_left = 12
	catchup_bg.corner_radius_bottom_right = 12
	
	var catchup_fill = StyleBoxFlat.new()
	catchup_fill.bg_color = Color(1.0, 0.8, 0.2, 1.0) 
	catchup_fill.corner_radius_top_left = 6
	catchup_fill.corner_radius_top_right = 6
	catchup_fill.corner_radius_bottom_left = 6
	catchup_fill.corner_radius_bottom_right = 6
	
	damage_catchup_bar.add_theme_stylebox_override("background", catchup_bg)
	damage_catchup_bar.add_theme_stylebox_override("fill", catchup_fill)
	
	big_hp_bar = ProgressBar.new()
	big_hp_bar.set_anchors_preset(Control.PRESET_FULL_RECT) 
	big_hp_bar.show_percentage = false
	big_hp_bar.max_value = max_health
	big_hp_bar.value = 0 
	big_hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var empty_bg = StyleBoxEmpty.new() 
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.3, 0.8, 0.2, 1.0) 
	fill_style.corner_radius_top_left = 6
	fill_style.corner_radius_top_right = 6
	fill_style.corner_radius_bottom_left = 6
	fill_style.corner_radius_bottom_right = 6
	
	big_hp_bar.add_theme_stylebox_override("background", empty_bg)
	big_hp_bar.add_theme_stylebox_override("fill", fill_style)
	
	boss_name_label = Label.new()
	boss_name_label.text = "- THE SEWER TYRANT -"
	boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	boss_name_label.offset_top = -35 
	boss_name_label.add_theme_font_size_override("font_size", 28)
	boss_name_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0, 1.0)) 
	boss_name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	boss_name_label.add_theme_constant_override("outline_size", 8)
	boss_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	damage_catchup_bar.add_child(big_hp_bar)
	damage_catchup_bar.add_child(boss_name_label)
	boss_ui_layer.add_child(damage_catchup_bar)
	
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) 
	tween.tween_property(world_dimmer, "color:a", 0.4, 1.0) 
	tween.parallel().tween_property(damage_catchup_bar, "offset_top", 50, 1.0).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(damage_catchup_bar, "offset_bottom", 80, 1.0).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(big_hp_bar, "value", max_health, 1.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(damage_catchup_bar, "value", max_health, 1.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)


func _physics_process(_delta: float) -> void:
	if not alive or is_spawning or is_transitioning:
		return

	if is_dashing:
		velocity = dash_direction * dash_speed
		move_and_slide()
		if Engine.get_physics_frames() % 3 == 0:
			create_dash_ghost()
		return

	direction = (player.position - position).normalized()
	velocity = direction * speed
	move_and_slide()

	if velocity.x != 0:
		$AnimatedSprite2D.flip_h = velocity.x < 0


# --- DASH COMBO SYSTEM ---
func _on_dash_cooldown_timer_timeout() -> void:
	if not alive or not can_use_abilities or combo_in_progress or is_transitioning:
		return
	start_dash_combo()

func start_dash_combo():
	combo_in_progress = true 
	dashes_left = 2 if phase == 1 else 4
	prepare_single_dash()

func prepare_single_dash():
	if not alive or is_transitioning: return 
	
	dash_direction = (player.position - position).normalized()
	if dash_direction.x != 0:
		$AnimatedSprite2D.flip_h = dash_direction.x < 0
		
	show_dash_line()
	$DashTimer.start() 

func show_dash_line():
	if not dash_line: return
	dash_line.visible = true
	var dash_distance = dash_speed * 0.4 
	var local_target = dash_direction * (dash_distance / scale.x)
	dash_line.clear_points()
	dash_line.add_point(Vector2.ZERO)
	dash_line.add_point(local_target)
	dash_line.default_color = Color(1.0, 0.0, 0.0, 0.2)
	dash_line.width = 2.0 
	
	var tween = create_tween().set_parallel(true)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(dash_line, "default_color", Color(1.0, 0.0, 0.0, 0.8), $DashTimer.wait_time)
	tween.tween_property(dash_line, "width", 6.0, $DashTimer.wait_time)

func _on_dash_timer_timeout() -> void:
	if dash_line: dash_line.visible = false
	is_dashing = true
	
	$AnimatedSprite2D.speed_scale = 2.0 
	$AnimatedSprite2D.play(anim_attack)
	
	await get_tree().create_timer(0.4, true, false, true).timeout
	if not alive or is_transitioning: return
	
	is_dashing = false
	dashes_left -= 1
	$AnimatedSprite2D.speed_scale = 1.0 
	
	if dashes_left > 0:
		$AnimatedSprite2D.play(anim_run)
		await get_tree().create_timer(0.2, true, false, true).timeout 
		if alive and not is_transitioning:
			prepare_single_dash()
	else:
		combo_in_progress = false
		$AnimatedSprite2D.play(anim_run)
		$DashCooldownTimer.start()


# --- HEALTH & PHASES ---
func take_damage(amount: int) -> void:
	if not alive or is_transitioning: return

	health -= amount
	update_hp_bar()
	
	if health <= 0:
		if phase == 1:
			enter_phase_2()
		else:
			die()

func update_hp_bar() -> void:
	if is_instance_valid(big_hp_bar) and is_instance_valid(damage_catchup_bar):
		big_hp_bar.value = health
		var tween = create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) 
		tween.tween_property(damage_catchup_bar, "value", health, 0.6).set_delay(0.2).set_trans(Tween.TRANS_SINE)

func enter_phase_2() -> void:
	is_transitioning = true 
	phase = 2
	$Area2D.set_deferred("monitoring", false) 
	
	# Cancel dashes safely
	combo_in_progress = false
	is_dashing = false
	$DashTimer.stop()
	$DashCooldownTimer.stop()
	if dash_line: dash_line.visible = false
	
	# Hit-stop
	Engine.time_scale = 0.1
	var flash = ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(1.0, 0.0, 0.0, 0.4) 
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_ui_layer.add_child(flash)
	
	await get_tree().create_timer(0.8, true, false, true).timeout 
	
	Engine.time_scale = 1.0
	if is_instance_valid(flash): flash.queue_free()
	
	max_health *= 2  
	health = max_health 
	
	anim_run = "enraged_run"
	anim_attack = "enraged_attack"
	$AnimatedSprite2D.play(anim_run)
	
	var tween = create_tween().set_parallel(true)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) 
	tween.tween_property(self, "scale", Vector2(5, 5), 1.0)
	tween.tween_property($AnimatedSprite2D, "modulate", Color(1.0, 0.7, 0.7), 1.0)
	
	if is_instance_valid(big_hp_bar):
		tween.tween_property(world_dimmer, "color", Color(0.2, 0.0, 0.0, 0.5), 1.0)
		
		big_hp_bar.max_value = max_health
		damage_catchup_bar.max_value = max_health
		
		var fill_style = big_hp_bar.get_theme_stylebox("fill").duplicate()
		fill_style.bg_color = Color(0.9, 0.1, 0.1, 1.0) 
		big_hp_bar.add_theme_stylebox_override("fill", fill_style)
		
		var catchup_bg = damage_catchup_bar.get_theme_stylebox("background").duplicate()
		catchup_bg.border_color = Color(1.0, 0.2, 0.0, 1.0) 
		damage_catchup_bar.add_theme_stylebox_override("background", catchup_bg)
		
		boss_name_label.text = "- ENRAGED TYRANT -"
		boss_name_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.1, 1.0))
		
		var shake = create_tween().set_loops(12)
		shake.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) 
		shake.tween_property(damage_catchup_bar, "position:x", damage_catchup_bar.position.x + 15, 0.05)
		shake.tween_property(damage_catchup_bar, "position:x", damage_catchup_bar.position.x - 15, 0.05)
		shake.chain().tween_property(damage_catchup_bar, "position:x", 200, 0.05) 
		
		tween.tween_property(big_hp_bar, "value", max_health, 1.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(damage_catchup_bar, "value", max_health, 1.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	
	speed += 20
	dash_speed += 300 
	
	if main.has_node("BossBGM"):
		main.get_node("BossBGM").pitch_scale = 1.35 # Adjust this number to make it faster/slowerw
	
	await get_tree().create_timer(1.0, true, false, true).timeout
	$Area2D.set_deferred("monitoring", true)
	is_transitioning = false 
	$DashCooldownTimer.start()


func die() -> void:
	alive = false
	is_dashing = false 
	combo_in_progress = false
	Engine.time_scale = 1.0 
	
	$DashTimer.stop()
	$DashCooldownTimer.stop()
	
	ScoreManager.add_points(60)
	$AnimatedSprite2D.speed_scale = 1.0 
	$AnimatedSprite2D.play("died") 

	$Area2D.set_deferred("monitoring", false)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	
	if is_instance_valid(boss_ui_layer):
		var tween = create_tween().set_parallel(true)
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) 
		tween.tween_property(damage_catchup_bar, "modulate:a", 0.0, 1.0)
		tween.tween_property(world_dimmer, "color:a", 0.0, 1.0)
		tween.chain().tween_callback(boss_ui_layer.queue_free)

	if randf() <= DROP_CHANCE: drop_item()

	var explosion = explosion_scene.instantiate()
	explosion.position = position
	main.add_child(explosion)
	explosion.process_mode = Node.PROCESS_MODE_ALWAYS

	velocity = Vector2.ZERO
	set_physics_process(false)

func _on_area_2d_body_entered(_body: Node2D) -> void:
	hit_player.emit()

func drop_item() -> void:
	var item = item_scene.instantiate()
	item.position = position
	item.item_type = randi_range(0, 2)
	main.call_deferred("add_child", item)
	item.add_to_group("items")

func create_dash_ghost():
	var ghost = Sprite2D.new()
	ghost.add_to_group("bullets") 
	var current_frame = $AnimatedSprite2D.sprite_frames.get_frame_texture($AnimatedSprite2D.animation, $AnimatedSprite2D.frame)
	ghost.texture = current_frame
	ghost.global_position = global_position
	ghost.scale = scale * $AnimatedSprite2D.scale 
	ghost.flip_h = $AnimatedSprite2D.flip_h
	ghost.modulate = Color(1.0, 0.2, 0.2, 0.6) 
	main.add_child(ghost)
	
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) 
	tween.tween_property(ghost, "modulate:a", 0.0, 0.3) 
	tween.tween_callback(ghost.queue_free)
