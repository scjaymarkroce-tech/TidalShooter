extends Node2D

@onready var main = get_node("/root/Main")

# 🚜 FARM THEME (Waves 1-10)
var goblin_scene := preload("res://scenes/goblin.tscn")
var fast_goblin_scene := preload("res://scenes/fast_goblin.tscn")
var boss_goblin_scene := preload("res://scenes/boss.tscn")

# 🐀 SEWER THEME (Waves 11-20)
var burrow_rat_scene := preload("res://scenes/burrow_rat.tscn")
var fast_rat_scene := preload("res://scenes/fast_rat.tscn")
var boss_rat_scene := preload("res://scenes/boss_rat.tscn")

# 🐸 SWAMP THEME (Waves 21-30)
var minion_frog_scene := preload("res://scenes/minion_frog.tscn")
var boss_frog_scene := preload("res://scenes/boss_frog.tscn")

var spawn_points := []

signal hit_p


func _ready() -> void:
	for i in get_children():
		if i is Marker2D:
			spawn_points.append(i)


func _on_timer_timeout() -> void:
	var main_node = get_parent()
	var stats = main_node.get_enemy_stats()
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	var bosses = get_tree().get_nodes_in_group("bosses")
	
	# 🚫 enforce max enemies
	if enemies.size() >= main_node.max_enemies:
		return
	
	var spawn = spawn_points[randi() % spawn_points.size()]
	var enemy
	
	# Calculate which part of the 30-wave cycle we are currently in
	# Wave 1 -> 1. Wave 30 -> 30. Wave 31 -> loops back to 1!
	var cycle_wave = ((main_node.wave - 1) % 30) + 1
	
	# 👹 BOSS LOGIC (every 5 waves)
	var is_boss_wave = (main_node.wave % 5 == 0)
	
	if is_boss_wave and bosses.size() == 0:
		if cycle_wave <= 10:
			enemy = boss_goblin_scene.instantiate()
		elif cycle_wave <= 20:
			enemy = boss_rat_scene.instantiate()
		else:
			enemy = boss_frog_scene.instantiate()
		
		# 💀 Scale boss HP globally so EVERY boss gets harder as the player survives longer!
		var boss_level = int(main_node.wave / 5)
		enemy.health = 450 + (boss_level - 1) * 50
		enemy.add_to_group("bosses")
	
	# ⚡ NORMAL ENEMY LOGIC
	else:
		if cycle_wave <= 10:
			# 🚜 FARM THEME
			if randf() < 0.3:
				enemy = fast_goblin_scene.instantiate()
				enemy.health = stats.fast_hp
			else:
				enemy = goblin_scene.instantiate()
				enemy.health = stats.normal_hp
				
		elif cycle_wave <= 20:
			# 🐀 SEWER THEME
			if randf() < 0.3:
				enemy = fast_rat_scene.instantiate()
				enemy.health = stats.fast_hp
			else:
				enemy = burrow_rat_scene.instantiate()
				enemy.health = stats.normal_hp
				
		else:
			# 🐸 SWAMP THEME
			# The Minion Frog is the only normal enemy type here
			enemy = minion_frog_scene.instantiate()
			# Normal HP stats will naturally scale up the tadpole over time!
			enemy.health = stats.normal_hp
	
	# 📍 common setup
	enemy.position = spawn.position
	enemy.hit_player.connect(hit)
	main.add_child(enemy)
	enemy.add_to_group("enemies")


func hit():
	hit_p.emit()
