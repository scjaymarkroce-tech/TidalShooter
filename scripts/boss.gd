extends CharacterBody2D

@onready var main = get_node("/root/Main")
@onready var player = get_node("/root/Main/Player")

var explosion_scene := preload("res://scenes/explosion.tscn")
var item_scene := preload("res://scenes/item.tscn")

signal hit_player

# Boss stats
var health: int = 300  # starting HP, scale later in spawner
var speed: int = 70     # slower than normal enemies
var alive := true

const DROP_CHANCE : float = 1.0  # boss always drops something

var direction := Vector2.ZERO

var is_dashing := false
var can_dash := true
var dash_speed := 1800
var dash_direction := Vector2.ZERO
var can_use_abilities := false


func _ready() -> void:
	alive = true
	direction = (player.position - position).normalized()
	$AnimatedSprite2D.play("run")
	
	# 🔥 MOVE PIVOT TO LEFT EDGE (true origin fix)
	var tex_size = $DashIndicatorRoot/DashIndicator.texture.get_size()
	$DashIndicatorRoot/DashIndicator.offset = Vector2(-tex_size.x / 2, 0)
	
	# hide initially
	#$DashIndicatorRoot/DashIndicator.visible = false
	$DashIndicatorRoot.visible = false
	
	await get_tree().create_timer(3.0).timeout
	can_use_abilities = true
	
	
func _physics_process(_delta: float) -> void:
	if not alive:
		return

	# 🟥 DASHING STATE
	if is_dashing:
		velocity = dash_direction * dash_speed
		move_and_slide()
		return

	# 🧠 NORMAL CHASE
	direction = (player.position - position).normalized()
	velocity = direction * speed
	move_and_slide()

	# flip sprite
	if velocity.x != 0:
		$AnimatedSprite2D.flip_h = velocity.x < 0
		
	if can_dash and can_use_abilities and not is_dashing:
		start_dash_attack()

func start_dash_attack():
	can_dash = false
	
	# lock direction at moment of cast
	dash_direction = (player.position - position).normalized()
	
	show_dash_line()
	
	$DashTimer.start()

func show_dash_line():
	var length = 300
	
	var root = $DashIndicatorRoot
	var indicator = $DashIndicatorRoot/DashIndicator
	
	root.visible = true
	
	# place root EXACTLY at boss
	root.position = Vector2.ZERO
	
	# rotate root
	root.rotation = dash_direction.angle()
	
	# scale forward
	var tex_width = indicator.texture.get_size().x if indicator.texture else 100
	indicator.scale.x = length / tex_width
	
	# reset local position
	indicator.position = Vector2.ZERO
	
	# fade in
	indicator.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(indicator, "modulate:a", 1.0, 0.2)
	
func take_damage(amount: int) -> void:
	if not alive:
		return

	health -= amount
	if health <= 0:
		die()

func die() -> void:
	alive = false
	#$AnimatedSprite2D.stop()
	$AnimatedSprite2D.animation = "dead"

	# disable collisions
	$Area2D.set_deferred("monitoring", false)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)

	# drop loot
	if randf() <= DROP_CHANCE:
		drop_item()

	var explosion = explosion_scene.instantiate()
	explosion.position = position
	main.add_child(explosion)
	explosion.process_mode = Node.PROCESS_MODE_ALWAYS

	velocity = Vector2.ZERO
	set_physics_process(false)

func drop_item() -> void:
	var item = item_scene.instantiate()
	item.position = position
	item.item_type = randi_range(0, 2)
	main.call_deferred("add_child", item)
	item.add_to_group("items")

func _on_area_2d_body_entered(_body: Node2D) -> void:
	hit_player.emit()


func _on_DashCooldown_timer_timeout() -> void:
	can_dash = true


func _on_DashTimer_timeout() -> void:
	$DashIndicatorRoot/DashIndicator.visible = false
	$DashIndicatorRoot.visible = false
	
	is_dashing = true
	$AnimatedSprite2D.play("dash")
	
	# dash duration
	await get_tree().create_timer(0.4).timeout
	
	is_dashing = false
	$AnimatedSprite2D.play("run")

	$DashCooldownTimer.start()
	$DashIndicatorRoot/DashIndicator.visible = false
