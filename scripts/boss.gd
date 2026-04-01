extends CharacterBody2D

@onready var main = get_node("/root/Main")
@onready var player = get_node("/root/Main/Player")

var explosion_scene := preload("res://scenes/explosion.tscn")
var item_scene := preload("res://scenes/item.tscn")

signal hit_player

# Boss stats
var health: int = 50  # starting HP, scale later in spawner
var max_health: int = 50 # Used for the HP bar
var phase: int = 1 # Track which phase the boss is in
var speed: int = 70     # slower than normal enemies
var alive := true


const DROP_CHANCE : float = 1.0  # boss always drops something

var direction := Vector2.ZERO

var is_dashing := false
var can_dash := true
var dash_speed := 1800
var dash_direction := Vector2.ZERO
var can_use_abilities := false

#@onready var hp_bar = $HPBar # Make sure to add a ProgressBar node!
@onready var dash_line = $DashLine # Add this at the top with your other @onready variables


func _ready() -> void:
	alive = true
	max_health = health
	direction = (player.position - position).normalized()
	$AnimatedSprite2D.play("run")
	
	if has_node("ProgressBar"):
		$ProgressBar.max_value = max_health
		$ProgressBar.value = health
	
	# Hide the new dash line initially
	if dash_line:
		dash_line.visible = false
		
	await get_tree().create_timer(3.0).timeout
	can_use_abilities = true
	
	
func _physics_process(_delta: float) -> void:
	if not alive:
		return

	# 🟥 DASHING STATE
	if is_dashing:
		velocity = dash_direction * dash_speed
		move_and_slide()
		return

	# 🧠 NORMAL CHASE
	direction = (player.position - position).normalized()
	velocity = direction * speed
	move_and_slide()

	# flip sprite
	if velocity.x != 0:
		$AnimatedSprite2D.flip_h = velocity.x < 0
		
	if can_dash and can_use_abilities and not is_dashing:
		start_dash_attack()

func start_dash_attack():
	can_dash = false
	
	# lock direction at moment of cast
	dash_direction = (player.position - position).normalized()
	
	show_dash_line()
	$DashTimer.start()

func show_dash_line():
	if not dash_line:
		return
		
	dash_line.visible = true
	
	# Calculate exactly how far the boss will dash (speed * dash duration of 0.4s)
	var dash_distance = dash_speed * 0.4 
	
	# Because the boss scales up 5x in Phase 2, we divide by scale.x
	# so the line accurately shows the distance without being 5x too long!
	var local_target = dash_direction * (dash_distance / scale.x)
	
	# Draw the line from the center of the boss to the target
	dash_line.clear_points()
	dash_line.add_point(Vector2.ZERO)
	dash_line.add_point(local_target)
	
	# --- WARNING ANIMATION ---
	# Start thin and slightly transparent red
	dash_line.default_color = Color(1.0, 0.0, 0.0, 0.2)
	dash_line.width = 3.0 
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Over the duration of the wind-up ($DashTimer.wait_time), fade to solid red
	tween.tween_property(dash_line, "default_color", Color(1.0, 0.0, 0.0, 0.8), $DashTimer.wait_time)
	
	# Also make the line grow much thicker, screaming "DANGER!"
	# (In phase 2, it will appear even thicker due to the 5x boss scale)
	tween.tween_property(dash_line, "width", 7.0, $DashTimer.wait_time)
	
func take_damage(amount: int) -> void:
	if not alive:
		return

	health -= amount
	update_hp_bar()
	
	if health <= 0:
		if phase == 1:
			enter_phase_2()
		else:
			die()
			
# New function to handle Phase 2 transition
func enter_phase_2() -> void:
	phase = 2
	
	# Double the max HP
	max_health *= 2  
	health = max_health 
	
	# Update the HP Bar to match the new max health
	if has_node("ProgressBar"):
		$ProgressBar.max_value = max_health
		# 🎨 TINT EFFECT: Turn the HP bar bright red!
		$ProgressBar.modulate = Color(1, 0.2, 0.2) 
	update_hp_bar()
	
	# Make the boss bigger and look angry!
	var tween = create_tween()
	tween.set_parallel(true) # This makes all tweens happen at the exact same time
	
	# Scales the boss up by 5x over 1 seconds
	tween.tween_property(self, "scale", Vector2(5, 5), 1.0)
	
	# 🎨 TINT EFFECT: Slowly turn the boss's sprite an angry red!
	# Color(Red, Green, Blue) -> 1.0 is full red, 0.3 for green/blue makes it heavily red-tinted
	tween.tween_property($AnimatedSprite2D, "modulate", Color(1.0, 0.3, 0.3), 1.0)
	
	# Make him a little faster
	speed += 30
	dash_speed += 500 # Make the huge boss dash much faster!
	
	# 🎬 ANIMATION EFFECT: Make his running and dashing animations play 50% faster!
	$AnimatedSprite2D.speed_scale = 1.5 
	
	$DashCooldownTimer.start()


func update_hp_bar() -> void:
	if has_node("ProgressBar"):
		$ProgressBar.value = health
	

func die() -> void:
	alive = false
	is_dashing = false # Force dash to stop immediately
	ScoreManager.add_points(40)
	$AnimatedSprite2D.play("dead") 

	# disable collisions
	$Area2D.set_deferred("monitoring", false)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	
	# Hide the HP bar when dead
	if has_node("ProgressBar"):
		$ProgressBar.visible = false

	# drop loot
	if randf() <= DROP_CHANCE:
		drop_item()

	var explosion = explosion_scene.instantiate()
	explosion.position = position
	main.add_child(explosion)
	explosion.process_mode = Node.PROCESS_MODE_ALWAYS

	velocity = Vector2.ZERO
	set_physics_process(false)

func drop_item() -> void:
	var item = item_scene.instantiate()
	item.position = position
	item.item_type = randi_range(0, 2)
	main.call_deferred("add_child", item)
	item.add_to_group("items")

func _on_area_2d_body_entered(_body: Node2D) -> void:
	hit_player.emit()


func _on_DashCooldown_timer_timeout() -> void:
	can_dash = true


func _on_DashTimer_timeout() -> void:
	if dash_line:
		dash_line.visible = false
	
	is_dashing = true
	$AnimatedSprite2D.play("dash")
	
	# dash duration
	await get_tree().create_timer(0.4).timeout
	
	# 🐛 THE BUG FIX: If the boss died while we were waiting for the dash to finish, stop here!
	if not alive:
		return
	
	is_dashing = false
	$AnimatedSprite2D.play("run")

	$DashCooldownTimer.start()
