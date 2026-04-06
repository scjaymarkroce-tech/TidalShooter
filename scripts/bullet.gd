extends Area2D


var speed : int = 500
var direction : Vector2

var damage : int = 10

var is_flame := false

var max_range := 500  # default for pistol/rifle, change per-shot
var distance_travelled := 0.0
var weapon_type: int = 1  # Default to pistol
var piercing: int = 0  # How many enemies it can go through (0=none)

@export var pistol_tex : Texture2D
@export var shotgun_tex : Texture2D
@export var rifle_tex : Texture2D
@export var flame_tex : Texture2D

var trail_length_target := 0.0

func _ready():
	rotation = direction.angle()  # This makes particles face/travel forward

	if is_flame:
		scale = Vector2(2.5, 2.5)  # 🔥 bigger hit feel
		
	if has_node("FlameFX"):
		$FlameFX.rotation = 0         
	
	if has_node("MuzzleBurst"):
		$MuzzleBurst.emitting = true
		$MuzzleBurst.visible = true
		$MuzzleBurst.restart()
		
func _process(delta):
	var actual_speed = speed
	if is_flame:
		actual_speed = 300  # slower = better coverage
	
	var move_dist = actual_speed * delta
	position += direction * move_dist
	distance_travelled += move_dist
	rotation = direction.angle()       # rotates whole bullet
	
	if has_node("FlameFX"):
		$FlameFX.rotation = 0             
		
	if distance_travelled > max_range:
		queue_free()
		
	# Dynamic Trail Stretching
	if has_node("Trail") and $Trail.visible and $Trail.points.size() >= 2:
		$Trail.set_point_position(0, Vector2.ZERO)
		$Trail.set_point_position(1, Vector2(-trail_length_target, 0))

func _on_timer_timeout() -> void:
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.name == "World":
		queue_free()
	elif body.has_method("take_damage"):
		body.take_damage(damage)
		if piercing > 0:
			piercing -= 1
			if piercing < 0:
				queue_free()
		else:
			queue_free()
			

# Called by manager for EVERY bullet spawned
func set_bullet_appearance(w_type: int):
	weapon_type = w_type
	
	# Turn off all special FX by default, we'll turn them on per-weapon
	if has_node("Trail"): $Trail.visible = false
	if has_node("ExplosionFX"): $ExplosionFX.visible = false
	if has_node("FlameFX"): $FlameFX.visible = false
	$Sprite2D.visible = true
	
	# Make sure the trail has 2 points ready
	if has_node("Trail"):
		$Trail.clear_points()
		$Trail.add_point(Vector2.ZERO)
		$Trail.add_point(Vector2.ZERO)
	
	if weapon_type == 1:
		# PISTOL: Fast little beige seed
		$Sprite2D.texture = pistol_tex
		$Sprite2D.scale = Vector2(1, 1)
		$Sprite2D.modulate = Color(0.9, 0.85, 0.75) # Off-white / Beige
		
		if has_node("Trail"):
			trail_length_target = 30.0
			$Trail.width = 4
			$Trail.antialiased = true
			var g = Gradient.new()
			g.colors = [Color(1, 1, 1, 0.8), Color(0.6, 0.4, 0.2, 0.0)] # White to brown fade
			$Trail.gradient = g
			$Trail.visible = true
			
	elif weapon_type == 2: 
		# SHOTGUN: Heavy dark dirt clods / chaff
		$Sprite2D.texture = shotgun_tex  
		$Sprite2D.scale = Vector2(1.8, 1.8)
		$Sprite2D.modulate = Color(0.4, 0.25, 0.15, 1.0) # Deep Earthy Brown
		
		if has_node("Trail"):
			trail_length_target = 50.0
			$Trail.width = 12
			$Trail.antialiased = true
			var g := Gradient.new()
			g.offsets = [0.0, 0.3, 0.7, 1.0]
			g.colors = [
				Color(0.8, 0.7, 0.6, 0.9),  # Dusty white
				Color(0.5, 0.35, 0.2, 0.7), # Mid brown
				Color(0.3, 0.2, 0.1, 0.3),  # Dark brown
				Color(0.2, 0.1, 0.05, 0.0)  # Fade out
			]
			$Trail.gradient = g
			$Trail.visible = true

	elif weapon_type == 3:
		# RIFLE: Piercing white wood splinter
		$Sprite2D.texture = rifle_tex
		$Sprite2D.scale = Vector2(1.2, 1.2)
		$Sprite2D.modulate = Color(1.0, 1.0, 1.0, 1.0) # Pure piercing white
		
		if has_node("Trail"):
			trail_length_target = 180.0 # Very long, fast trail
			$Trail.width = 10
			$Trail.antialiased = true
			var g := Gradient.new()
			g.offsets = [0.0, 0.15, 0.4, 0.8, 1.0]
			g.colors = [
				Color(1.0, 1.0, 1.0, 1.0),     # Hot white core
				Color(0.9, 0.8, 0.6, 0.9),     # Light tan/wood
				Color(0.6, 0.4, 0.2, 0.6),     # Rich brown
				Color(0.3, 0.15, 0.05, 0.2),   # Dark earth
				Color(0.1, 0.05, 0.0, 0.0)     # Transparent
			]
			$Trail.gradient = g
			$Trail.visible = true
			
	elif weapon_type == 4:
		# FLAMETHROWER: Elegant "Golden Wheat / Autumn Wind"
		$Sprite2D.visible = false
		
		if has_node("FlameFX"):
			$FlameFX.visible = true
			
			# 🐛 FIX: Use color_ramp for CPUParticles2D instead of process_material
			var fg = Gradient.new()
			fg.offsets = [0.0, 0.2, 0.6, 1.0]
			fg.colors = [
				Color(1.0, 1.0, 1.0, 1.0),     # Bright white wind core
				Color(0.95, 0.85, 0.55, 0.9),  # Golden wheat glow
				Color(0.65, 0.45, 0.25, 0.6),  # Earthy brown
				Color(0.4, 0.25, 0.15, 0.0)    # Fades softly into the dirt
			]
			
			# Make sure it works for both CPU and GPU particles just in case!
			if $FlameFX is CPUParticles2D:
				$FlameFX.color_ramp = fg
			elif $FlameFX is GPUParticles2D and $FlameFX.process_material != null:
				var tex = GradientTexture1D.new()
				tex.gradient = fg
				$FlameFX.process_material.color_ramp = tex
				
			$FlameFX.restart()
