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
var rifle_trail_gradient := Gradient.new()

func _ready():
	rotation = direction.angle()  # This makes particles face/travel forward

	if is_flame:
		scale = Vector2(2.5, 2.5)  # 🔥 bigger hit feel
		
	if has_node("FlameFX"):
		$FlameFX.rotation = 0         # ensure flame always fires along local X
	
	if has_node("MuzzleBurst"):
		$MuzzleBurst.emitting = true
		$MuzzleBurst.visible = true
		$MuzzleBurst.restart()
		
	if weapon_type == 3 and has_node("Trail"):
		var trail_length := 60.0
		$Trail.clear_points()
		$Trail.add_point(Vector2.ZERO)
		$Trail.add_point(Vector2(-trail_length, 0))
		$Trail.width = 12
		$Trail.antialiased = true

		# Make a nice glowing gradient:
		rifle_trail_gradient.colors = [
			Color(1, 1, 0.8, 1.0),   # bright yellow-white at bullet (full opacity)
			Color(0.4, 1, 0.4, 0.75), # pale green midway, semi fade
			Color(0, 0.5, 1, 0.2),   # blue very faint at tail
			Color(1, 1, 1, 0.0)      # fully transparent at far end
		]
		$Trail.gradient = rifle_trail_gradient
		$Trail.visible = true
		
func _process(delta):
	var actual_speed = speed
	if is_flame:
		actual_speed = 300  # slower = better coverage
	
	var move_dist = actual_speed * delta
	position += direction * move_dist
	distance_travelled += move_dist
	rotation = direction.angle()       # rotates whole bullet
	$FlameFX.rotation = 0             # keep local, prevents double-rotation issues
	if distance_travelled > max_range:
		queue_free()
		
	if weapon_type == 3 and has_node("Trail") and $Trail.points.size() >= 2:
		var trail_length := 160.0
		$Trail.set_point_position(0, Vector2.ZERO)
		$Trail.set_point_position(1, Vector2(-trail_length, 0))

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
func set_bullet_appearance(weapon_type: int):
	if weapon_type == 1:
		$Sprite2D.texture = pistol_tex
		$Sprite2D.scale = Vector2(1,1)
		$Trail.visible = false
		$ExplosionFX.visible = false
		$FlameFX.visible = false
	elif weapon_type == 2: # Shotgun (Raze rocket style)
		$Sprite2D.texture = shotgun_tex  # Should be big, brightly colored (red/orange)
		$Sprite2D.scale = Vector2(2.2, 2.2)
		$Sprite2D.modulate = Color(1, 0.6, 0.2, 1.0) # vivid orange
		$Trail.width = 18
		$Trail.antialiased = true
		$Trail.clear_points()
		$Trail.add_point(Vector2.ZERO)
		$Trail.add_point(Vector2(-40, 0))  # Shorter than rifle trail
		var g := Gradient.new()
		g.offsets = [0.0, 0.35, 0.8, 1.0]
		g.colors = [
			Color(1, 1, 0.75, 1),    # bright yellow fire at pellet
			Color(1, 0.4, 0.1, 0.7), # hot orange
			Color(0.15, 0.12, 0.11, 0.22), # brown/grey smokey
			Color(1, 0.5, 0, 0.0)    # fade to transparent
		]
		$Trail.gradient = g
		$Trail.visible = true

		# Show (and play) MuzzleBurst effect:
		if has_node("MuzzleBurst"):
			$MuzzleBurst.emitting = true
			$MuzzleBurst.visible = true
			$MuzzleBurst.restart()
		$ExplosionFX.visible = false
		$FlameFX.visible = false
	elif weapon_type == 3:
		var trail_length := 100.0  # Make it longer for that dramatic sniping effect!
		$Trail.clear_points()
		$Trail.add_point(Vector2.ZERO)
		$Trail.add_point(Vector2(-trail_length, 0))
		$Trail.width = 16
		$Trail.antialiased = true

		var g := Gradient.new()
		g.offsets = [0.0, 0.15, 0.35, 0.55, 0.8, 1.0]
		g.colors = [
			Color(1, 1, 1, 1.0),           # pure white hot core at bullet tip
			Color(1, 0.8, 0.95, 0.85),     # bold hot pink/fuchsia next to core
			Color(0.7, 0.1, 0.9, 0.65),    # deep magenta/purple (Chamber effect)
			Color(0.2, 0.9, 1, 0.4),       # teal/cyan halo, <--- this is signature
			Color(0.4, 0.1, 1, 0.2),       # soft violet edge
			Color(1, 0, 1, 0.0)            # fully transparent/outer edge
		]
		$Trail.gradient = g
		$Trail.visible = true
	elif weapon_type == 4:
		$Sprite2D.visible = false
		$Trail.visible = false
		$ExplosionFX.visible = false
		$FlameFX.visible = true
		$FlameFX.restart()
