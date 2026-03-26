extends Node

var wave : int
var max_enemies : int 
var lives : int
var difficulty : float
const DIFF_MULTIPLIER : float = 1.2

func _ready() -> void:
	new_game()
	$GameOver/Button.pressed.connect(new_game)

func new_game():
	wave = 1
	lives = 3
	difficulty = 3.0
	$EnemySpawner/Timer.wait_time = 1.0
	reset()

func _process(_delta):
	if is_wave_completed():
		wave += 1
		
		# Remove flamethrower AFTER wave ends
		if wave > 1:
			$Player.has_flamethrower = false
		
		# Adjust difficulty
		if $EnemySpawner/Timer.wait_time > 0.25:
			$EnemySpawner/Timer.wait_time -= 0.05
		difficulty += DIFF_MULTIPLIER
		
		# Show upgrade menu every 3 waves
		if wave % 3 == 0:
			$UpgradeMenu.show_upgrade_menu()
		else:
			$WaveOverTimer.start()

func reset():
	max_enemies = int(difficulty)
	$Player.has_flamethrower = true
	$Player.reset()
	get_tree().call_group("enemies", "queue_free")
	get_tree().call_group("bullets", "queue_free")
	get_tree().call_group("items", "queue_free")
	$Hud/LivesLabel.text = "X " + str(lives)
	$Hud/WaveLabel.text = "WAVE: " + str(wave)
	$Hud/EnemiesLabel.text = "X " + str(max_enemies)
	$GameOver.hide()
	get_tree().paused = true
	$RestartTimer.start()

func _on_enemy_spawner_hit_p() -> void:
	lives -= 1
	$Hud/LivesLabel.text = "X " + str(lives)
	get_tree().paused = true
	if lives <= 0:
		$GameOver/WavesSurvivedLabel.text = "WAVES SURVIVED: " + str(wave - 1)
		$GameOver.show()
	else:
		$WaveOverTimer.start()

func _on_wave_over_timer_timeout() -> void:
	reset()

func _on_restart_timer_timeout() -> void:
	get_tree().paused = false

# Called by upgrade menu when selection is made
func on_upgrade_complete() -> void:
	$WaveOverTimer.start()

func is_wave_completed():
	if wave > 1:
		$Player.has_flamethrower = false
	
	var all_dead = true
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	if enemies.size() == max_enemies:
		for e in enemies:
			if e.alive:
				all_dead = false
		return all_dead
	else:
		return false
