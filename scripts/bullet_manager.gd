extends Node2D

@export var bullet_scene : PackedScene



func _on_player_shoot(pos, dir, damage, is_flame, weapon_type):
	var bullet = bullet_scene.instantiate()
	bullet.weapon_type = weapon_type      # <-- This line!
	bullet.set_bullet_appearance(weapon_type)
	add_child(bullet)
	bullet.position = pos
	bullet.direction = dir.normalized()
	bullet.damage = damage
	bullet.is_flame = is_flame
	bullet.add_to_group("bullets")
	bullet.set_bullet_appearance(weapon_type)   
	
	match weapon_type:
		1:  # Pistol
			bullet.max_range = 450
			bullet.piercing = 0
		2:  # Shotgun
			bullet.max_range = 320
			bullet.piercing = 0
		3:  # Rifle
			bullet.max_range = 600
			bullet.piercing = 2
		4:  # Flamethrower
			bullet.max_range = 300
			bullet.piercing = 3
