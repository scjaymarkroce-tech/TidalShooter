extends Node

var wave: int
var max_enemies: int
var lives: int
var difficulty: float
const DIFF_MULTIPLIER: float = 1.2

var wave_in_transition := false  # Prevents duplicate triggers

# 🖼️ BACKGROUND VARIABLES
# Make sure the path "World/bg1" matches your scene tree. 
# If your TileMap is named something else (like "TileMap"), change "World" to that name!
@onready var bg1 = $World/bg1
@onready var bg2 = $World/bg2
@onready var bg3 = $World/bg3

func _ready() -> void:
	new_game()
	$GameOver/Panel/PlayAgainButton.pressed.connect(new_game)
	$UpgradeMenu.hide()

func new_game():
	wave = 1
	lives = 3
	difficulty = 3.0
	ScoreManager.reset_score()
	wave_in_transition = false
	$UpgradeMenu.upgrade_manager.reset_upgrades()
	$UpgradeMenu.upgrade_manager.apply_shotgun_stats($Player)
	$UpgradeMenu.upgrade_manager.apply_rifle_stats($Player)
	# (and repeat for pistol if you ever add pistol upgrades)
	reset()

func _process(_delta):
	if not wave_in_transition and is_wave_completed():
		wave_in_transition = true   # Start transition
		ScoreManager.add_points(20)
		if $EnemySpawner/Timer.wait_time > 0.25:
			$EnemySpawner/Timer.wait_time -= 0.05
		difficulty += DIFF_MULTIPLIER
		
		# Show upgrade after every 3rd wave except wave 0/start
		if wave % 1 == 0 and wave != 0:
			get_tree().paused = true        # Pause everything except upgrade menu
			$UpgradeMenu.open_menu()
		else:
			wave += 1
			get_tree().paused = true
			$WaveOverTimer.start()

func reset():
	wave_in_transition = false  # Allow next wave checks
	
	# ✨ UPDATE BACKGROUND FOR THE CURRENT WAVE
	update_background()
	
	var stats = get_enemy_stats()
	max_enemies = stats.max_enemies
	$EnemySpawner/Timer.wait_time = stats.spawn_rate
	$Player.reset()
	get_tree().call_group("enemies", "queue_free")
	get_tree().call_group("bullets", "queue_free")
	get_tree().call_group("items", "queue_free")
	get_tree().call_group("swamps", "queue_free")
	$Hud/LivesLabel.text = "X " + str(lives)
	$Hud/WaveLabel.text = "WAVE: " + str(wave)
	$Hud/EnemiesLabel.text = "X " + str(max_enemies)
	$GameOver.hide()
	get_tree().paused = true
	$RestartTimer.start()
	
	
#ENEMY FOCUS ============================================================================================
#ENEMY FOCUS ============================================================================================
func _on_enemy_spawner_hit_p() -> void:
	# 🛡️ INVULNERABILITY CHECK
	if $Player.is_invulnerable:
		return
	
	lives -= 1
	$Hud/LivesLabel.text = "X " + str(lives)
	get_tree().paused = true
	
	if lives <= 0:
		# 🐛 THE FIX: Always guarantee time goes back to normal when Game Over hits!
		Engine.time_scale = 1.0 
		
		$GameOver.show_game_over(ScoreManager.score, wave - 1)
		$GameOver.show()
	else:
		$WaveOverTimer.start()
		
func get_enemy_stats():
	var stats = {}

	# 📈 SMOOTH SCALING FORMULAS
	
	# Enemy count (caps at 15)
	stats.max_enemies = min(5 + int(wave * 1.2), 15)
	
	# Spawn rate (gets faster, min 0.25)
	stats.spawn_rate = max(1.0 - (wave * 0.05), 0.25)
	
	# Normal HP scaling
	stats.normal_hp = int(20 * pow(1.1, wave - 1))
	
	# Fast HP scaling (slightly lower early, catches up)
	stats.fast_hp = int(15 * pow(1.12, wave - 1))
	
	return stats
	

func _on_wave_over_timer_timeout() -> void:
	reset()

func _on_restart_timer_timeout() -> void:
	get_tree().paused = false

func is_wave_completed():
	var all_dead = true
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.size() == max_enemies:
		for e in enemies:
			if e.alive:
				all_dead = false
		if all_dead:
			# CHECK flamethrower for removal after use!
			if $Player.has_flamethrower and $Player.flamethrower_pending_remove:
				$Player.has_flamethrower = false
				$Player.flamethrower_pending_remove = false
			return true
	return false

# Called by upgrade_menu.gd after an upgrade is chosen.
func _on_upgrade_menu_closed():
	wave += 1
	get_tree().paused = true
	$WaveOverTimer.start()
	

# ✨ NEW FUNCTION: Handles the background switching logic
func update_background():
	# If for some reason the backgrounds aren't found in the tree, skip to prevent crashing
	if not bg1 or not bg2 or not bg3:
		return
		
	# Calculate which part of the 30-wave cycle we are in (1 to 30)
	var cycle_wave = ((wave - 1) % 30) + 1
	
	# Show the correct one based on the theme!
	if cycle_wave <= 10:
		# 🚜 FARM THEME (Waves 1-10)
		bg1.visible = true
		bg2.visible = false
		bg3.visible = false
	elif cycle_wave <= 20:
		# 🐀 SEWER THEME (Waves 11-20)
		bg1.visible = false
		bg2.visible = true
		bg3.visible = false
	else:
		# 🐸 SWAMP THEME (Waves 21-30)
		bg1.visible = false
		bg2.visible = false
		bg3.visible = true
		

# ⏭️ CHEAT CODES
func _unhandled_input(event: InputEvent) -> void:
	
	# 💥 INSTANT KILL ALL: Press '0'
	if event is InputEventKey and event.pressed and event.keycode == KEY_0:
		# Nuke all normal enemies
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy.alive and enemy.has_method("take_damage"):
				enemy.take_damage(9999) 
				
		# Nuke all bosses
		for boss in get_tree().get_nodes_in_group("bosses"):
			if boss.alive and boss.has_method("take_damage"):
				boss.take_damage(9999) 


	# ⏩ INSTANT LEVEL JUMP: Press '5' to jump straight to the Wave 5 Boss!
	if event is InputEventKey and event.pressed and event.keycode == KEY_5:
		# If the game is paused (like in the upgrade menu), unpause it so we can jump
		get_tree().paused = false 
		
		# Set the wave directly to 5
		wave = 25
		
		# Force the game to reset and immediately load the new wave
		reset()
