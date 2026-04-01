extends CharacterBody2D

@onready var main = get_node("/root/Main")
@onready var player = get_node("/root/Main/Player")
@onready var dash_line = $DashLine
@onready var hp_bar = $ProgressBar

var explosion_scene := preload("res://scenes/explosion.tscn")
var item_scene := preload("res://scenes/item.tscn")
var poison_scene := preload("res://scenes/poison.tscn")

signal hit_player

var health: int = 2050  
var max_health: int = 2050
var speed: int = 70     
var alive := true
var phase := 1 

const DROP_CHANCE : float = 1.0  

var direction := Vector2.ZERO

# Attack System Variables
var is_dashing := false       # True ONLY during the 0.4s dash travel
var is_preparing_shoot := false # True ONLY while standing still to shoot poison
var attack_in_progress := false # Locks the system so loops don't overlap

var dash_speed := 1800
var attack_direction := Vector2.ZERO
var can_use_abilities := false

# Animations
var anim_run := "run"
var anim_attack := "attack"

func _ready() -> void:
	alive = true
	max_health = health
	$AnimatedSprite2D.play(anim_run)
	
	if hp_bar:
		hp_bar.max_value = max_health
		hp_bar.value = health
	
	if dash_line:
		dash_line.visible = false
		dash_line.width = 3.0
		
	$DashCooldownTimer.stop()
	await get_tree().create_timer(3.0).timeout
	can_use_abilities = true
	$DashCooldownTimer.start()


func _physics_process(_delta: float) -> void:
	if not alive: return

	# 🐸 Phase 1 Dash Movement (Only applies when actually dashing!)
	if is_dashing:
		velocity = attack_direction * dash_speed
		move_and_slide()
		return
	
	# 🟢 Phase 2 Shooting Windup (Stops moving to aim/shoot)
	if is_preparing_shoot:
		return

	# NORMAL CHASE (Continues even while the dash warning line is drawing, just like the Rat)
	direction = (player.position - position).normalized()
	velocity = direction * speed
	move_and_slide()

	if velocity.x != 0:
		$AnimatedSprite2D.flip_h = velocity.x < 0


# --- ATTACK SYSTEM ---
func _on_dash_cooldown_timer_timeout() -> void:
	if not alive or not can_use_abilities or attack_in_progress: return
	
	attack_in_progress = true # Lock the system!
	attack_direction = (player.position - position).normalized()
	
	if attack_direction.x != 0:
		$AnimatedSprite2D.flip_h = attack_direction.x < 0

	if phase == 1:
		# Set the timer wait time for a proper 1-second warning
		$DashTimer.wait_time = 1.0
		show_dash_line()
		$DashTimer.start() 
	else:
		# Phase 2: Very fast windup before the poison fires
		is_preparing_shoot = true
		$AnimatedSprite2D.play(anim_attack)
		$DashTimer.wait_time = 0.3
		$DashTimer.start() 


func show_dash_line():
	if not dash_line: return
	dash_line.visible = true
	
	var dash_distance = dash_speed * 0.4 
	var local_target = attack_direction * (dash_distance / scale.x)
	
	dash_line.clear_points()
	dash_line.add_point(Vector2.ZERO)
	dash_line.add_point(local_target)
	
	dash_line.default_color = Color(1.0, 0.0, 0.0, 0.2)
	dash_line.width = 2.0 
	
	var tween = create_tween()
	tween.set_parallel(true)
	# Relies strictly on the exact wait_time we set above
	tween.tween_property(dash_line, "default_color", Color(1.0, 0.0, 0.0, 0.8), $DashTimer.wait_time)
	tween.tween_property(dash_line, "width", 6.0, $DashTimer.wait_time)


func _on_dash_timer_timeout() -> void:
	if not alive: return
	if dash_line: dash_line.visible = false
	
	if phase == 1:
		# PERFORM DASH
		is_dashing = true # NOW we allow physics to launch the frog
		$AnimatedSprite2D.speed_scale = 2.0 
		$AnimatedSprite2D.play(anim_attack)
		
		await get_tree().create_timer(0.4).timeout
		
		if not alive: return
		$AnimatedSprite2D.speed_scale = 1.0 
		$AnimatedSprite2D.play(anim_run)
		
		# Reset state
		is_dashing = false
		attack_in_progress = false
		
		# Normal 2-second cooldown between dashes
		$DashCooldownTimer.start(2.0)
		
	elif phase == 2:
		# PERFORM POISON SHOOT
		shoot_poison()
		
		$AnimatedSprite2D.play(anim_run)
		
		# Reset state
		is_preparing_shoot = false
		attack_in_progress = false
		
		# RAPID FIRE: Only 0.6 seconds cooldown
		$DashCooldownTimer.start(0.6)


func shoot_poison():
	var poison = poison_scene.instantiate()
	poison.position = position
	poison.direction = attack_direction
	poison.hit_player.connect(func(): hit_player.emit())
	main.add_child(poison)


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
	
	# Cancel Phase 1 actions safely
	attack_in_progress = false
	is_dashing = false
	is_preparing_shoot = false
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
	# Subtle Green/Yellow tint for poison theme!
	tween.tween_property($AnimatedSprite2D, "modulate", Color(0.8, 1.0, 0.5), 0.5)
	
	speed += 20 
	# Start Phase 2 rapid fire cycle!
	$DashCooldownTimer.start(0.6)

func die() -> void:
	alive = false
	is_dashing = false 
	is_preparing_shoot = false
	attack_in_progress = false
	$DashTimer.stop()
	$DashCooldownTimer.stop()
	
	ScoreManager.add_points(60)
	
	# Your custom deflate-on-death effect!
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(3, 3), 0.5)
	
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
