extends CharacterBody2D

@onready var main = get_node("/root/Main")
@onready var player = get_node("/root/Main/Player")

var explosion_scene := preload("res://scenes/explosion.tscn")
var item_scene := preload("res://scenes/item.tscn")

signal hit_player

# State Machine to track what the rat is doing
enum State { CHASE, BURROW_DOWN, UNDERGROUND, BURROW_UP }
var current_state = State.CHASE

var health: int = 40
var walk_speed: int = 70
var underground_speed: int = 150 # Moves much faster underground!
var alive := true

const DROP_CHANCE : float = 0.2

var burrow_cooldown := 3.0
var underground_timer := 0.0

# Store the original collision layers so we can restore them after burrowing
var original_layer: int
var original_mask: int

func _ready() -> void:
	alive = true
	$AnimatedSprite2D.play("walk")
	
	# Save original layers
	original_layer = collision_layer
	original_mask = collision_mask
	
	# Randomize first burrow so they don't all dive at the exact same time
	burrow_cooldown = randf_range(2.0, 4.0)


func _physics_process(delta: float) -> void:
	if not alive: return

	match current_state:
		State.CHASE:
			handle_chase(delta)
		State.UNDERGROUND:
			handle_underground(delta)
		# We don't move during BURROW_DOWN or BURROW_UP


func update_facing(dir: Vector2):
	if dir.x != 0:
		$AnimatedSprite2D.flip_h = dir.x < 0


# --- NORMAL CHASE ---
func handle_chase(delta: float):
	var direction = (player.position - position).normalized()
	velocity = direction * walk_speed
	move_and_slide()
	update_facing(velocity)

	burrow_cooldown -= delta
	if burrow_cooldown <= 0:
		start_burrow_down()


# --- BURROW MECHANICS ---
func start_burrow_down():
	current_state = State.BURROW_DOWN
	velocity = Vector2.ZERO # Stop moving
	
	$AnimatedSprite2D.play("burrow")
	
	# Wait for the burrow animation to finish going into the ground
	await $AnimatedSprite2D.animation_finished
	if not alive: return
	
	# Become the "Shadow"
	current_state = State.UNDERGROUND
	underground_timer = 4 # Max time it can spend underground
	
	# Disable hitboxes so it can't be damaged OR hurt the player while underground
	$Area2D.set_deferred("monitoring", false)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	
	# Visual Marker: Make it look like a dark, transparent shadow moving on the ground
	$AnimatedSprite2D.modulate = Color(0, 0, 0, 0.4) 
	$AnimatedSprite2D.play("walk")


func handle_underground(delta: float):
	var direction = (player.position - position).normalized()
	velocity = direction * underground_speed
	move_and_slide()
	update_facing(velocity)

	underground_timer -= delta
	
	# If time is up, OR it has reached the player's feet, pop up!
	if underground_timer <= 0 or position.distance_to(player.position) < 30:
		start_burrow_up()


func start_burrow_up():
	current_state = State.BURROW_UP
	velocity = Vector2.ZERO # Stop moving to pop out
	
	# Restore normal colors BEFORE popping out
	$AnimatedSprite2D.modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	# 👇 Shrink the sprite ONLY for the burrow_out animation
	# Change the 0.7 to whatever number makes it match your other animations!
	$AnimatedSprite2D.scale = Vector2(0.1, 0.1) 
	
	# Play your awesome new animation!
	$AnimatedSprite2D.play("burrow_out")
	
	# Wait for the rat to fully emerge
	await $AnimatedSprite2D.animation_finished
	if not alive: return
	
	# Re-enable hitboxes and collisions so it is dangerous again!
	$Area2D.set_deferred("monitoring", true)
	set_deferred("collision_layer", original_layer)
	set_deferred("collision_mask", original_mask)
	
	current_state = State.CHASE
	
	# 👇 Return the scale to normal before walking again
	$AnimatedSprite2D.scale = Vector2(0.13, 0.13)
	
	$AnimatedSprite2D.play("walk")
	
	# Reset cooldown for next burrow
	burrow_cooldown = randf_range(3.0, 5.0)


# --- HIT & DEATH LOGIC ---
func _on_area_2d_body_entered(body: Node2D) -> void:
	# Only hurt the player if NOT underground
	if current_state != State.UNDERGROUND and body.name == "Player":
		hit_player.emit()

func take_damage(amount: int) -> void:
	
	# ✨ SPAWN THE DAMAGE NUMBER!
	DamageNumbers.show_damage(amount, global_position)
	
	
	# Ignore damage if underground!
	if not alive or current_state == State.UNDERGROUND: return

	health -= amount
	if health <= 0:
		die()

func die() -> void:
	alive = false
	ScoreManager.add_points(15)
	$AnimatedSprite2D.scale = Vector2(0.1, 0.1)
	# Reset visual just in case it died right as it was changing
	$AnimatedSprite2D.modulate = Color(1.0, 1.0, 1.0, 1.0)
	$AnimatedSprite2D.play("died") 
	
	$Area2D.set_deferred("monitoring", false)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)

	if randf() <= DROP_CHANCE:
		var item = item_scene.instantiate()
		item.position = position
		item.item_type = randi_range(0, 2)
		main.call_deferred("add_child", item)

	var explosion = explosion_scene.instantiate()
	explosion.position = position
	main.add_child(explosion)

	velocity = Vector2.ZERO
	set_physics_process(false)
