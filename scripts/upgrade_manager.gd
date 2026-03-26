# upgrade_manager.gd - Centralized upgrade tracking system

class_name UpgradeManager

# Track weapon levels (1-5+)
var pistol_level: int = 1
var shotgun_level: int = 1
var rifle_level: int = 1
var has_flamethrower: bool = false

# Define scaling per level (from DEVELOPMENT_GUIDE.md)
var PISTOL_SCALING = {
	1: {"damage": 10, "mag": 12, "reload": 3.0},
	2: {"damage": 10, "mag": 12, "reload": 3.0},
	3: {"damage": 10, "mag": 12, "reload": 3.0},
	4: {"damage": 10, "mag": 12, "reload": 3.0},
	5: {"damage": 10, "mag": 12, "reload": 3.0}  # No change per guide
}

var SHOTGUN_SCALING = {
	1: {"damage": 15, "mag": 10, "reload": 7.0},
	2: {"damage": 21, "mag": 15, "reload": 6.0},
	3: {"damage": 27, "mag": 20, "reload": 5.0},
	4: {"damage": 35, "mag": 25, "reload": 4.0},
	5: {"damage": 0, "mag": 0, "reload": 0}  # Will be calculated as prev*1.2
}

var RIFLE_SCALING = {
	1: {"damage": 25, "mag": 3, "reload": 7.0},
	2: {"damage": 40, "mag": 4, "reload": 6.0},
	3: {"damage": 55, "mag": 5, "reload": 5.0},
	4: {"damage": 70, "mag": 5, "reload": 4.0},
	5: {"damage": 0, "mag": 0, "reload": 0}  # Will be calculated as prev*1.2
}

# Apply upgrade to player
func apply_upgrade(upgrade_choice: String, player: Node) -> void:
	match upgrade_choice:
		"shotgun":
			if shotgun_level < 5:
				shotgun_level += 1
			else:
				# Level 5+: multiply by 1.2
				shotgun_level += 1
			
			apply_shotgun_stats(player)
			print("Shotgun upgraded to level ", shotgun_level)
		
		"rifle":
			if rifle_level < 5:
				rifle_level += 1
			else:
				# Level 5+: multiply by 1.2
				rifle_level += 1
			
			apply_rifle_stats(player)
			print("Rifle upgraded to level ", rifle_level)
		
		"flamethrower":
			has_flamethrower = true
			player.has_flamethrower = true
			print("Flamethrower unlocked!")

# Apply shotgun stats based on level
func apply_shotgun_stats(player: Node) -> void:
	if shotgun_level <= 4:
		player.shotgun_damage = SHOTGUN_SCALING[shotgun_level]["damage"]
		player.max_ammo[2] = SHOTGUN_SCALING[shotgun_level]["mag"]
		player.reload_time[2] = SHOTGUN_SCALING[shotgun_level]["reload"]
		player.current_ammo[2] = player.max_ammo[2]
	else:
		# Level 5+: multiply previous by 1.2
		var prev_level = shotgun_level - 1
		var prev_damage = SHOTGUN_SCALING[4]["damage"]
		player.shotgun_damage = int(prev_damage * pow(1.2, shotgun_level - 4))
		# Mag and reload stay capped

# Apply rifle stats based on level
func apply_rifle_stats(player: Node) -> void:
	if rifle_level <= 4:
		player.rifle_damage = RIFLE_SCALING[rifle_level]["damage"]
		player.max_ammo[3] = RIFLE_SCALING[rifle_level]["mag"]
		player.reload_time[3] = RIFLE_SCALING[rifle_level]["reload"]
		player.current_ammo[3] = player.max_ammo[3]
	else:
		# Level 5+: multiply previous by 1.2
		var prev_damage = RIFLE_SCALING[4]["damage"]
		player.rifle_damage = int(prev_damage * pow(1.2, rifle_level - 4))
		# Mag and reload stay capped

# Get upgrade options for this wave
func get_upgrade_options() -> Array[String]:
	var options: Array[String] = []  # ✅ Explicitly typed array
	
	options.append("shotgun")
	options.append("rifle")
	
	# 10% chance for flamethrower
	if randf() <= 0.3 and not has_flamethrower:
		options.append("flamethrower")
	
	# If we only have 2 options, that's fine - return them
	return options
