extends CharacterBody2D

@onready var main = get_node("/root/Main")
@onready var player = get_node("/root/Main/Player")
@onready var dash_line = $DashLine
@onready var hp_bar = $ProgressBar

var explosion_scene := preload("res://scenes/explosion.tscn")
var item_scene := preload("res://scenes/item.tscn")

signal hit_player

# Boss stats
var health: int = 1050  
var max_health: int = 1050
var speed: int = 70     
var alive := true
var phase := 1 

const DROP_CHANCE : float = 1.0  

var direction := Vector2.ZERO

# Dash Combo System Variables
var is_dashing := false
var dash_speed := 1800
var dash_direction := Vector2.ZERO
var can_use_abilities := false
var dashes_left := 0 
var combo_in_progress := false # 🛡️ The ultimate lock against infinite loops

# Animation tracking
var anim_run := "run"
var anim_attack := "attack"

func _ready() -> void:
	alive = true
	max_health = health
	direction = (player.position - position).normalized()
	$AnimatedSprite2D.play(anim_run)
	
	if hp_bar:
		hp_bar.max_value = max_health
		hp_bar.value = health
	
	if dash_line:
		dash_line.visible = false
		dash_line.width = 3.0
		
	# Make sure the timer isn't auto-starting in the editor
	$DashCooldownTimer.stop()
		
	await get_tree().create_timer(3.0).timeout
	can_use_abilities = true
	
	# Start the very first attack cycle manually
	$DashCooldownTimer.start()


func _physics_process(_delta: float) -> void:
	if not alive:
		return

	if is_dashing:
		velocity = dash_direction * dash_speed
		move_and_slide()
		
		# ✨ DRAMATIC GHOST TRAIL: Spawn a ghost every 3 frames
		if Engine.get_physics_frames() % 3 == 0:
			create_dash_ghost()
			
		return

	# NORMAL CHASE
	direction = (player.position - position).normalized()
	velocity = direction * speed
	move_and_slide()

	# flip sprite
	if velocity.x != 0:
		$AnimatedSprite2D.flip_h = velocity.x < 0

# REMOVED the start_dash_attack() check from _physics_process!
# It is now entirely controlled by the DashCooldownTimer.


# --- DASH COMBO SYSTEM ---

# This ONLY gets called when the DashCooldownTimer finishes.
func _on_dash_cooldown_timer_timeout() -> void:
	if not alive or not can_use_abilities or combo_in_progress:
		return
		
	start_dash_combo()

func start_dash_combo():
	combo_in_progress = true # Lock the system
	
	if phase == 1:
		dashes_left = 2
	else:
		dashes_left = 4
		
	prepare_single_dash()


func prepare_single_dash():
	if not alive: return 
	
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
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(dash_line, "default_color", Color(1.0, 0.0, 0.0, 0.8), $DashTimer.wait_time)
	tween.tween_property(dash_line, "width", 6.0, $DashTimer.wait_time)


func _on_dash_timer_timeout() -> void:
	if dash_line: dash_line.visible = false
	
	is_dashing = true
	
	$AnimatedSprite2D.speed_scale = 2.0 
	$AnimatedSprite2D.play(anim_attack)
	
	# Dash travel duration
	await get_tree().create_timer(0.4).timeout
	
	if not alive: return
	
	is_dashing = false
	dashes_left -= 1
	
	$AnimatedSprite2D.speed_scale = 1.0 
	
	if dashes_left > 0:
		$AnimatedSprite2D.play(anim_run)
		# Tiny pause between dashes
		await get_tree().create_timer(0.2).timeout 
		
		if alive:
			prepare_single_dash()
	else:
		# Combo completely finished! Unlock the system and start cooldown.
		combo_in_progress = false
		$AnimatedSprite2D.play(anim_run)
		$DashCooldownTimer.start()


# --- HEALTH & PHASES ---
func take_damage(amount: int) -> void:
	if not alive: return

	health -= amount
	if hp_bar: hp_bar.value = health
	
	if health <= 0:
		if phase == 1:
			enter_phase_2()
		else:
			die()

func enter_phase_2() -> void:
	phase = 2
	max_health *= 2  
	health = max_health 
	
	# CANCEL EVERYTHING SAFELY
	combo_in_progress = false
	is_dashing = false
	$DashTimer.stop()
	$DashCooldownTimer.stop()
	if dash_line: dash_line.visible = false
	
	if hp_bar:
		hp_bar.max_value = max_health
		hp_bar.value = health
		hp_bar.modulate = Color(1, 0.2, 0.2) 
	
	anim_run = "enraged_run"
	anim_attack = "enraged_attack"
	$AnimatedSprite2D.play(anim_run)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(5, 5), 0.5)
	# Subtle red tint
	tween.tween_property($AnimatedSprite2D, "modulate", Color(1.0, 0.7, 0.7), 0.5)
	
	speed += 20
	dash_speed += 300 
	
	# Start Phase 2 cycle after transforming!
	$DashCooldownTimer.start()

func die() -> void:
	alive = false
	is_dashing = false 
	combo_in_progress = false
	
	$DashTimer.stop()
	$DashCooldownTimer.stop()
	
	ScoreManager.add_points(60)
	
	$AnimatedSprite2D.speed_scale = 1.0 
	$AnimatedSprite2D.play("died") 

	$Area2D.set_deferred("monitoring", false)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	if hp_bar: hp_bar.visible = false

	if randf() <= DROP_CHANCE:
		drop_item()

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


# ✨ DRAMATIC DASH EFFECTS ✨
func create_dash_ghost():
	var ghost = Sprite2D.new()
	# Grab the exact frame of animation the boss is currently in
	var current_frame = $AnimatedSprite2D.sprite_frames.get_frame_texture($AnimatedSprite2D.animation, $AnimatedSprite2D.frame)
	ghost.texture = current_frame
	ghost.global_position = global_position
	
	# Match the boss's size and direction
	ghost.scale = scale * $AnimatedSprite2D.scale 
	ghost.flip_h = $AnimatedSprite2D.flip_h
	
	# Give it a badass glowing red tint
	ghost.modulate = Color(1.0, 0.2, 0.2, 0.6) 
	
	# Add it to the world behind the boss
	main.add_child(ghost)
	
	# Make it quickly fade away and delete itself
	var tween = create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.3) # Fade to invisible over 0.3s
	tween.tween_callback(ghost.queue_free)
