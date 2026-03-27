extends Node2D

@onready var main = get_node("/root/Main")

var enemy_scene := preload("res://scenes/goblin.tscn")
var fast_enemy_scene := preload("res://scenes/fast_goblin.tscn")
var boss_scene := preload("res://scenes/boss.tscn")

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
	
	# 👹 BOSS LOGIC (every 5 waves)
	var is_boss_wave = main_node.wave % 1 == 0
	
	if is_boss_wave and bosses.size() == 0:
		enemy = boss_scene.instantiate()
		
		# 💀 scale boss HP
		var boss_level = int(main_node.wave / 5)
		enemy.health = 250 + (boss_level - 1) * 50
		
		enemy.add_to_group("bosses")
	
	else:
		# ⚡ NORMAL / FAST MIX
		if randf() < 0.3:
			enemy = fast_enemy_scene.instantiate()
			enemy.health = stats.fast_hp
		else:
			enemy = enemy_scene.instantiate()
			enemy.health = stats.normal_hp
	
	# 📍 common setup
	enemy.position = spawn.position
	enemy.hit_player.connect(hit)
	main.add_child(enemy)
	enemy.add_to_group("enemies")


func hit():
	hit_p.emit()
