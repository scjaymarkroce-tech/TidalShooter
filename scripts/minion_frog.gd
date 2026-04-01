extends CharacterBody2D

@onready var main = get_node("/root/Main")
@onready var player = get_node("/root/Main/Player")
@onready var hp_bar = $ProgressBar

var explosion_scene := preload("res://scenes/explosion.tscn")
var item_scene := preload("res://scenes/item.tscn")
var swamp_scene := preload("res://scenes/swamp.tscn")

signal hit_player

enum State { TADPOLE, DASHING, VOMITING }
var current_state = State.TADPOLE

var health: int = 50
var speed: int = 50 
var alive := true

const DROP_CHANCE : float = 0.5

# --- Phase 1: Tadpole ---
var incubation_duration := 7.0
var current_incubation := 0.0

# --- Phase 2: Dashing ---
var is_dashing := false
var dash_speed := 650
var dash_timer := 5.0 # Cooldown until next dash

# --- Phase 2: Vomiting ---
var is_vomiting := false
var vomit_timer := 3.0 # Cooldown until next vomit
var active_swamps = [] # Keeps track of all swamps this frog made

func _ready() -> void:
	alive = true
	$AnimatedSprite2D.play("swim")
	
	if hp_bar:
		hp_bar.max_value = incubation_duration
		hp_bar.value = 0
		hp_bar.modulate = Color(0.3, 0.8, 1.0) # Light blue progress bar


func _physics_process(delta: float) -> void:
	if not alive: return

	match current_state:
		State.TADPOLE:
			handle_tadpole(delta)
		State.DASHING:
			handle_dashing(delta)
		State.VOMITING:
			handle_vomiting(delta)


func update_facing(target_direction: Vector2):
	if target_direction.x != 0:
		$AnimatedSprite2D.flip_h = target_direction.x < 0


# -------------------------
# PHASE 1: TADPOLE LOGIC
# -------------------------
func handle_tadpole(delta: float):
	# Update the progress bar
	current_incubation += delta
	if hp_bar: hp_bar.value = current_incubation
	
	if current_incubation >= incubation_duration:
		evolve()
		return
		
	# Move slowly, do nothing else
	var direction = (player.position - position).normalized()
	velocity = direction * speed
	move_and_slide()
	update_facing(velocity)


func evolve():
	# Randomly pick evolution!
	if randf() > 0.5:
		current_state = State.DASHING
	else:
		current_state = State.VOMITING
		
	health = 60
	speed = 80 # Speeds up after evolving
	
	if hp_bar: hp_bar.visible = false # Hide incubation bar
	
	# Play the walk animation (removed the scaling effect so it keeps your editor size!)
	$AnimatedSprite2D.play("walk")


# -------------------------
# PHASE 2: DASHING LOGIC
# -------------------------
func handle_dashing(delta: float):
	if is_dashing:
		move_and_slide() # Continues sliding with the high dash velocity
		return
		
	var direction = (player.position - position).normalized()
	velocity = direction * speed
	move_and_slide()
	update_facing(velocity)
	
	dash_timer -= delta
	if dash_timer <= 0:
		perform_dash(direction)

func perform_dash(dir: Vector2):
	is_dashing = true
	$AnimatedSprite2D.play("dash")
	velocity = dir * dash_speed
	
	await get_tree().create_timer(0.4).timeout
	
	if not alive: return
	is_dashing = false
	velocity = Vector2.ZERO
	$AnimatedSprite2D.play("walk")
	dash_timer = randf_range(2.0, 3.5) # Random cooldown between dashes


# -------------------------
# PHASE 2: VOMITING LOGIC
# -------------------------
func handle_vomiting(delta: float):
	if is_vomiting:
		return # Stand completely still while vomiting
		
	var direction = (player.position - position).normalized()
	velocity = direction * speed
	move_and_slide()
	update_facing(velocity)
	
	vomit_timer -= delta
	if vomit_timer <= 0:
		perform_vomit()

func perform_vomit():
	is_vomiting = true
	$AnimatedSprite2D.play("vomit")
	
	# Wait a second for the animation to play out
	await get_tree().create_timer(0.6).timeout
	if not alive: return
	
	# Spawn Swamp slightly below the frog
	var swamp = swamp_scene.instantiate()
	swamp.position = position + Vector2(0, 20) 
	swamp.hit_player.connect(func(): hit_player.emit())
	main.add_child(swamp)
	
	# Store reference so we can delete it when the frog dies
	active_swamps.append(swamp) 
	
	$AnimatedSprite2D.play("walk")
	is_vomiting = false
	vomit_timer = randf_range(3.0, 5.0)


# -------------------------
# HIT & DEATH LOGIC
# -------------------------
func _on_area_2d_body_entered(body: Node2D) -> void:
	if current_state == State.TADPOLE:
		return # Tadpole is harmless!
		
	if body.name == "Player":
		hit_player.emit()

func take_damage(amount: int) -> void:
	if not alive: return
	health -= amount
	if health <= 0:
		die()

func die() -> void:
	alive = false
	ScoreManager.add_points(10)
	
	# Cleanup Swamps!
	for swamp in active_swamps:
		if is_instance_valid(swamp):
			swamp.queue_free()
	
	# 🐛 THE FIX: Play the correct death animation!
	if current_state == State.TADPOLE:
		# Your custom deflate-on-death effect!
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "scale", Vector2(3, 3), 0.5)
		$AnimatedSprite2D.play("tadpole_died")
	else:
		# Your custom deflate-on-death effect!
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "scale", Vector2(3, 3), 0.5)
		$AnimatedSprite2D.play("died") 
		
	$Area2D.set_deferred("monitoring", false)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	if hp_bar: hp_bar.visible = false

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
