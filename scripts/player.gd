extends CharacterBody2D
#NOTE!
#we will stop using the var reloading_weapon and $ReloadTimer


var speed : int 
var screen_size : Vector2
var can_shoot : bool
const START_SPEED : int = 200
const BOOST_SPEED : int = 400
const NORMAL_SHOT : float = 0.5
const FAST_SHOT : float = 0.1

#my own modification starts
# Weapon system
var current_weapon : int = 1  # 1 = pistol, 2 = shotgun, 3 = rifle

# Pistol stats (Level 1 from your table)
var pistol_damage := 10
var pistol_cooldown := 0.5

# Shotgun (Level 1)
var shotgun_damage := 15
var shotgun_cooldown := 1.2
var shotgun_pellets := 5
var shotgun_spread := 0.3  # radians (adjust later)

# Rifle (Level 1)
var rifle_damage := 100 #25 by default
var rifle_cooldown := 1.2

#========= BASE STATS ============

# Current ammo in magazine
var current_ammo := {
	1: 12,  # Pistol
	2: 10,  # Shotgun
	3: 3,   # Rifle
	4: -1   # Flamethrower (no ammo system)
}

# Max magazine size
var max_ammo := {
	1: 12,
	2: 10,
	3: 3,
	4: -1
}

# Reload times
var reload_time := {
	1: 3.0,
	2: 4.0,
	3: 7.0,
	4: 0.0  # Flamethrower does NOT use reload
}

# Reloading state
var is_reloading := {
	1: false,
	2: false,
	3: false,
	4: false
}

var reloading_weapon : int = 0
# Flamethrower
var has_flamethrower := false
var flamethrower_active := false
var flamethrower_duration := 7.0
var flamethrower_cooldown := 2.0
var flamethrower_damage := 20
var flamethrower_tick_rate := 0.1  # 0.1 sec = 10 ticks/sec (feels better than 1/sec)
var flamethrower_pending_remove := false    # True for the first wave after using it
var flamethrower_used_this_wave := false    # Internal: true if used this wave

signal shoot(pos, dir, damage, is_flame, weapon_type)


# DODGE SYSTEM
var can_dodge := true
var is_dodging := false
var dodge_speed := 500
var dodge_direction := Vector2.ZERO
var is_invulnerable := false

# ✨ PERFECT DODGE SYSTEM
var has_perfect_dodged := false
var perfect_dodge_distance := 60.0 # How close you must be to trigger the slow-mo


# HUD INTEGRATION
@onready var hud = get_node("/root/Main/Hud")  # adjust if needed!


func _ready() -> void:
	screen_size = get_viewport_rect().size
	reset()

func _process(_delta: float) -> void:
	validate_weapon()

func reset():
	position = screen_size / 2
	flamethrower_used_this_wave = false
	speed = START_SPEED
	can_shoot = true
	$ShotTimer.stop()
	$ReloadTimer.stop()
	reloading_weapon = 0
	for key in is_reloading.keys():
		is_reloading[key] = false
		current_ammo[key] = max_ammo[key]
	apply_weapon_stats()
	# --- HUD UPDATES ---
	hud.update_gun_icon(current_weapon)
	hud.update_ammo(current_ammo[current_weapon], max_ammo[current_weapon])
	hud.show_reload(false)
	hud.set_dodge_cooldown(0.0, 1.0)

func apply_weapon_stats():
	match current_weapon:
		1: $ShotTimer.wait_time = pistol_cooldown
		2: $ShotTimer.wait_time = shotgun_cooldown
		3: $ShotTimer.wait_time = rifle_cooldown


func get_input():
	var input_dir = Input.get_vector("left", "right", "up", "down")

	# Weapon selection
	if Input.is_key_pressed(KEY_4) and has_flamethrower:
		current_weapon = 4
		hud.update_gun_icon(current_weapon)
		hud.update_ammo(current_ammo[current_weapon], max_ammo[current_weapon])

	if Input.is_key_pressed(KEY_1):
		current_weapon = 1
		apply_weapon_stats()
		hud.update_gun_icon(current_weapon)
		hud.update_ammo(current_ammo[current_weapon], max_ammo[current_weapon])
	elif Input.is_key_pressed(KEY_2):
		current_weapon = 2
		apply_weapon_stats()
		hud.update_gun_icon(current_weapon)
		hud.update_ammo(current_ammo[current_weapon], max_ammo[current_weapon])
	elif Input.is_key_pressed(KEY_3):
		current_weapon = 3
		apply_weapon_stats()
		hud.update_gun_icon(current_weapon)
		hud.update_ammo(current_ammo[current_weapon], max_ammo[current_weapon])

	# DODGE
	if Input.is_action_just_pressed("dodge") and can_dodge:
		start_dodge(input_dir)
		hud.start_dodge_cooldown(2.0)

	# Movement
	if is_dodging:
		velocity = dodge_direction * dodge_speed
	else:
		velocity = input_dir.normalized() * speed

	# Firing
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and can_shoot:
		var dir = (get_global_mouse_position() - position).normalized()
		if not is_reloading[current_weapon]:
			match current_weapon:
				1:
					hud.show_reload(false)
					if current_ammo[1] > 0:
						shoot.emit(position, dir, pistol_damage, false, 1)
						current_ammo[1] -= 1
						hud.update_ammo(current_ammo[1], max_ammo[1])
						if current_ammo[1] <= 0:
							reload_weapon(current_weapon)
				2:
					hud.show_reload(false)
					if current_ammo[2] > 0:
						shoot_shotgun(dir)
						current_ammo[2] -= 5
						hud.update_ammo(current_ammo[2], max_ammo[2])
						if current_ammo[2] <= 0:
							reload_weapon(current_weapon)
				3:
					hud.show_reload(false)
					if current_ammo[3] > 0:
						shoot.emit(position, dir, rifle_damage, false, 3)
						current_ammo[3] -= 1
						hud.update_ammo(current_ammo[3], max_ammo[3])
						if current_ammo[3] <= 0:
							reload_weapon(current_weapon)
				4:
					start_flamethrower()
		can_shoot = false
		$ShotTimer.start()

		
func shoot_shotgun(base_dir: Vector2):
	for i in shotgun_pellets:
		var spread = randf_range(-shotgun_spread, shotgun_spread)
		var new_dir = base_dir.rotated(spread)
		shoot.emit(position, new_dir, shotgun_damage, false, 2)
		
func reload_weapon(weapon_id: int):
	if is_reloading[weapon_id]:
		return
	is_reloading[weapon_id] = true
	hud.show_reload(true, 0)
	var elapsed: float = 0.0
	var total: float = reload_time[weapon_id]
	
	while elapsed < total:
		# 🐛 FIX: Stop reloading if the player died or left the scene!
		if not is_inside_tree(): return 
		
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		
		if current_weapon == weapon_id:
			hud.show_reload(true, elapsed / total)
		else:
			hud.show_reload(false)
			
	if elapsed < total: 
		if not is_inside_tree(): return # 🐛 FIX
		await get_tree().create_timer(total - elapsed).timeout
		
	current_ammo[weapon_id] = max_ammo[weapon_id]
	is_reloading[weapon_id] = false
	hud.show_reload(false)
	hud.update_ammo(current_ammo[weapon_id], max_ammo[weapon_id])
	
	
#	THIS IS THE LOGIC FOR OUR SPECIAL WEAPON =======================================
# SPECIAL: Flamethrower
func start_flamethrower():
	hud.show_reload(false)
	hud.update_ammo(0, 0)
	if flamethrower_active: return
	if has_flamethrower and not flamethrower_used_this_wave:
		flamethrower_used_this_wave = true
		flamethrower_pending_remove = true
	flamethrower_active = true
	fire_flamethrower()

func fire_flamethrower():
	var time_passed := 0.0
	while time_passed < flamethrower_duration:
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			break
		var base_dir = (get_global_mouse_position() - position).normalized()
		var spread_dir = base_dir.rotated(randf_range(-0.2, 0.2))
		shoot.emit(position, spread_dir, flamethrower_damage, true, 4)
		await get_tree().create_timer(flamethrower_tick_rate).timeout
		time_passed += flamethrower_tick_rate
	await get_tree().create_timer(flamethrower_cooldown).timeout
	flamethrower_active = false

func validate_weapon():
	if current_weapon == 4 and not has_flamethrower:
		current_weapon = 1
		apply_weapon_stats()


# =====================================================================================
# DODGE MECHANIC
func start_dodge(input_dir: Vector2):
	if input_dir == Vector2.ZERO:
		return
	
	has_perfect_dodged = false 
	dodge_speed = 500 # Reset dodge speed to normal
	
	# 🌾 GREEN/YELLOW: Turn slightly yellow-green during dodge
	modulate = Color(0.8, 1.0, 0.4, 0.8) 
	
	can_dodge = false
	is_dodging = true
	is_invulnerable = true
	dodge_direction = input_dir.normalized()
	$DodgeTimer.start()
	$DodgeCooldownTimer.start()


func _on_dodge_timer_timeout():
	is_dodging = false
	is_invulnerable = false
	dodge_speed = 500 # Reset speed back to normal
	modulate = Color(1, 1, 1, 1)

func _on_dodge_cooldown_timer_timeout():
	can_dodge = true


func _physics_process(_delta: float) -> void:
	get_input()
	move_and_slide()
	position = position.clamp(Vector2.ZERO, screen_size)
	
	# ✨ 1. DODGE GHOST TRAILS
	if is_dodging and Engine.get_physics_frames() % 3 == 0:
		create_dodge_ghost()
		
	# ✨ 2. PERFECT DODGE CHECK (Are we phasing through an enemy?)
	if is_dodging and not has_perfect_dodged:
		check_perfect_dodge()

	var mouse = get_local_mouse_position()
	var angle = snappedf(mouse.angle(), PI / 4) / (PI / 4)
	angle = wrapi(int(angle), 0, 8)
	$AnimatedSprite2D.animation = "walk" + str(angle)
	
	if velocity.length() != 0 :
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()
		$AnimatedSprite2D.frame = 1


# ✨ NEW: VISUAL GHOST TRAIL
func create_dodge_ghost():
	var ghost = Sprite2D.new()
	var current_frame = $AnimatedSprite2D.sprite_frames.get_frame_texture($AnimatedSprite2D.animation, $AnimatedSprite2D.frame)
	ghost.texture = current_frame
	ghost.global_position = global_position
	ghost.scale = scale * $AnimatedSprite2D.scale 
	
	# 🌾 GREEN/YELLOW neon trail
	ghost.modulate = Color(0.6, 1.0, 0.2, 0.6) 
	get_parent().add_child(ghost)
	
	var tween = create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.3) 
	tween.tween_callback(ghost.queue_free)

# ✨ NEW: PERFECT DODGE DETECTION & SLOW-MO
func check_perfect_dodge():
	var enemies = get_tree().get_nodes_in_group("enemies")
	var bosses = get_tree().get_nodes_in_group("bosses")
	var all_enemies = enemies + bosses
	
	for enemy in all_enemies:
		if enemy.alive and global_position.distance_to(enemy.global_position) < perfect_dodge_distance:
			trigger_perfect_dodge()
			return # Stop checking, we already dodged successfully

func trigger_perfect_dodge():
	has_perfect_dodged = true
	
	# ⚡ REWARD: Make this specific dash 15% longer/faster!
	dodge_speed *= 1.15 
	
	# 1. Slow down time drastically (WITCH TIME!)
	Engine.time_scale = 0.2
	
	# 2. Flash the screen slightly yellow-green 🌾
	var flash = ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(0.6, 1.0, 0.2, 0.2)
	get_node("/root/Main").add_child(flash)
	
	# 3. Create floating "PERFECT DODGE" Text
	var text = Label.new()
	text.text = "PERFECT DODGE!"
	text.modulate = Color(0.8, 1.0, 0.2, 1.0) # 🌾 Bright yellow-green text
	text.add_theme_font_size_override("font_size", 30)
	text.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	text.add_theme_constant_override("outline_size", 4)
	text.global_position = global_position + Vector2(-80, -50)
	get_parent().add_child(text)
	
	# 4. Animate it all! (Note: Tweens need to ignore time_scale during slow-mo)
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	tween.tween_property(text, "global_position:y", text.global_position.y - 50, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(text, "modulate:a", 0.0, 0.5).set_delay(0.2)
	tween.parallel().tween_property(flash, "color:a", 0.0, 0.3)
	
	tween.tween_callback(text.queue_free)
	tween.tween_callback(flash.queue_free)
	
	await get_tree().create_timer(0.5, true, false, true).timeout 
	Engine.time_scale = 1.0

# --- WEAPON TIMERS ---
func boost():
	$BoostTimer.start()
	speed = BOOST_SPEED

func quick_fire():
	$FastFireTimer.start()
	$ShotTimer.wait_time = FAST_SHOT

func _on_shot_timer_timeout() -> void:
	can_shoot =  true

func _on_boost_timer_timeout() -> void:
	speed = START_SPEED

func _on_fast_fire_timer_timeout() -> void:
	$ShotTimer.wait_time = NORMAL_SHOT

func _on_ReloadTimer_timeout():
	current_ammo[reloading_weapon] = max_ammo[reloading_weapon]
	is_reloading[reloading_weapon] = false
	reloading_weapon = 0
