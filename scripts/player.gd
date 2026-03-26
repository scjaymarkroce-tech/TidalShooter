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



func _ready() -> void:
	screen_size = get_viewport_rect().size
	reset()

func _process(_delta: float) -> void:
	validate_weapon()

func reset():
#	this is the player starting position, always in the middle of the screen
	position = screen_size / 2
	flamethrower_used_this_wave = false
	# movement reset
	speed = START_SPEED
	can_shoot = true
	
	# reset timers
	$ShotTimer.stop()
	$ReloadTimer.stop()
	
	# reset weapon states
	reloading_weapon = 0
	
	for key in is_reloading.keys():
		is_reloading[key] = false
		current_ammo[key] = max_ammo[key]
	
	# reset weapon cooldown
	apply_weapon_stats()
	
	
func apply_weapon_stats():
	match current_weapon:
		1: # Pistol
			$ShotTimer.wait_time = pistol_cooldown
		2: # Shotgun
			$ShotTimer.wait_time = shotgun_cooldown
		3: # Rifle
			$ShotTimer.wait_time = rifle_cooldown
			


func get_input():
#	KEYBOARD INOUT TO ACTIVATE THE SPECIAL GUN HEHE
	if Input.is_key_pressed(KEY_4) and has_flamethrower:
		current_weapon = 4
	
#	KEYBOARD INPUT FOR RELOADING
	if Input.is_key_pressed(KEY_R):
		reload_weapon(current_weapon)
	
#	THIS IS WEAPON CHOOSING USING KEYBOARD	
	if Input.is_key_pressed(KEY_1):
		current_weapon = 1
		apply_weapon_stats()
	elif Input.is_key_pressed(KEY_2):
		current_weapon = 2
		apply_weapon_stats()
	elif Input.is_key_pressed(KEY_3):
		current_weapon = 3
		apply_weapon_stats()
	
#	keyboard input
	var input_dir = Input.get_vector("left", "right", "up", "down")
	velocity = input_dir.normalized() * speed
	
#	mouse clicks
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and can_shoot:
		var dir = (get_global_mouse_position() - position).normalized()
		
		if not is_reloading[current_weapon]:
			match current_weapon:
				1:	#pistol
					if current_ammo[1] > 0:
						shoot.emit(position, dir, pistol_damage, false, 1)
						current_ammo[1] -= 1
						
						# ✅ PUT IT HERE
						if current_ammo[1] <= 0:
							reload_weapon(current_weapon)
				
				2: #shotgun
					if current_ammo[2] > 0:
						shoot_shotgun(dir)
						current_ammo[2] -= 5
						
						# ✅ HERE
						if current_ammo[2] <= 0:
							reload_weapon(current_weapon)
				
				3:	#rifledddda
					if current_ammo[3] > 0:
						shoot.emit(position, dir, rifle_damage, false, 3)
						current_ammo[3] -= 1
						
						# ✅ HERE
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
	
	# async reload (independent per weapon)
	await get_tree().create_timer(reload_time[weapon_id]).timeout
	
	current_ammo[weapon_id] = max_ammo[weapon_id]
	is_reloading[weapon_id] = false
	
	
#	THIS IS THE LOGIC FOR OUR SPECIAL WEAPON =======================================
func start_flamethrower():
	if flamethrower_active:
		return

	if has_flamethrower and not flamethrower_used_this_wave:
		flamethrower_used_this_wave = true
		flamethrower_pending_remove = true    # Will be removed at wave end

	flamethrower_active = true
	fire_flamethrower()
	
func fire_flamethrower():
	var time_passed := 0.0
	
	while time_passed < flamethrower_duration:
		# stop if player lets go
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			break
		
		# 🔥 dynamically aim every tick
		var base_dir = (get_global_mouse_position() - position).normalized()
		var spread_dir = base_dir.rotated(randf_range(-0.2, 0.2))
		
		shoot.emit(position, spread_dir, flamethrower_damage, true, 4)
		
		await get_tree().create_timer(flamethrower_tick_rate).timeout
		time_passed += flamethrower_tick_rate
	
	# cooldown
	await get_tree().create_timer(flamethrower_cooldown).timeout
	
	flamethrower_active = false
	

func validate_weapon():
	if current_weapon == 4 and not has_flamethrower:
		current_weapon = 1
		apply_weapon_stats()


# =====================================================================================

func _physics_process(_delta: float) -> void:
	get_input()
	move_and_slide()
	
#	limit movement
	position = position.clamp(Vector2.ZERO, screen_size)

#	player rotation
	var mouse = get_local_mouse_position()
	var angle = snappedf(mouse.angle(), PI / 4) / (PI / 4)
	angle = wrapi(int(angle), 0, 8)
	
	$AnimatedSprite2D.animation = "walk" + str(angle)
	
#	play animation
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
