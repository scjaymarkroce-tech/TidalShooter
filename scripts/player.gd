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
var rifle_damage := 25
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
	2: 7.0,
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
var flamethrower_damage := 5
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
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		# Only update bar if still on this weapon:
		if current_weapon == weapon_id:
			hud.show_reload(true, elapsed / total)
		else:
			hud.show_reload(false)
	if elapsed < total:  # finish waiting if a little short due to frame
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

#THIS IS FOR DODDE MECHANIC

# DODGE MECHANIC
func start_dodge(input_dir: Vector2):
	if input_dir == Vector2.ZERO:
		return
	modulate = Color(1, 1, 1, 0.5)
	can_dodge = false
	is_dodging = true
	is_invulnerable = true
	dodge_direction = input_dir.normalized()
	$DodgeTimer.start()
	$DodgeCooldownTimer.start()

func _on_dodge_timer_timeout():
	is_dodging = false
	is_invulnerable = false
	modulate = Color(1, 1, 1, 1)

func _on_dodge_cooldown_timer_timeout():
	can_dodge = true













func _physics_process(_delta: float) -> void:
	get_input()
	move_and_slide()
	position = position.clamp(Vector2.ZERO, screen_size)
	var mouse = get_local_mouse_position()
	var angle = snappedf(mouse.angle(), PI / 4) / (PI / 4)
	angle = wrapi(int(angle), 0, 8)
	$AnimatedSprite2D.animation = "walk" + str(angle)
	if velocity.length() != 0 :
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()
		$AnimatedSprite2D.frame = 1

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
