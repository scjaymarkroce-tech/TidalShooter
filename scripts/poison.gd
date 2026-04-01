extends Area2D

var speed := 700
var direction := Vector2.ZERO
var is_destroyed := false

signal hit_player

func _ready():
	$AnimatedSprite2D.play("poison_fly")
	# Rotate the poison to face the direction it's flying
	rotation = direction.angle()
	
	# Auto-destroy after 5 seconds if it misses everything
	await get_tree().create_timer(5.0).timeout
	if not is_destroyed:
		queue_free()

func _physics_process(delta: float) -> void:
	if not is_destroyed:
		position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if is_destroyed:
		return
		
	# Check if we hit the player (assuming player is on Layer 2 or named "Player")
	if body.name == "Player":
		hit_player.emit()
		
	destroy()

func destroy():
	is_destroyed = true
	$AnimatedSprite2D.play("poison_impact")
	# Stop moving and wait for impact animation to finish
	await $AnimatedSprite2D.animation_finished
	queue_free()
