extends CharacterBody2D

@onready var main = get_node("/root/Main")
@onready var player = get_node("/root/Main/Player")

var explosion_scene := preload("res://scenes/explosion.tscn")
var item_scene := preload("res://scenes/item.tscn")

signal hit_player

var entered : bool
var speed : int = 100
var direction : Vector2
var alive : bool

const DROP_CHANCE : float = 0.3

func _ready() -> void:
	var screen_rect = get_viewport_rect()
	alive = true
	entered = false

	
#	pick a direction from the where it spawned
	var dist = screen_rect.get_center() - position
	
#	check to which direction it has to move
	if abs(dist.x) > abs(dist.y):
#		move horizontally
		direction.x = dist.x
		direction.y = 0
	
	else:
#		move vertically
		direction.x = 0
		direction.y = dist.y
		
func _physics_process(_delta: float) -> void:
	if alive: 
		$AnimatedSprite2D.animation = "run"
		if entered:
			direction = (player.position - position)
		direction = direction.normalized()
		velocity = direction * speed
		move_and_slide()
		
	#	this is used to flip
		if velocity.x != 0:
			$AnimatedSprite2D.flip_h = velocity.x < 0
	
	else:
		pass
		
func die():
	alive = false
	$AnimatedSprite2D.stop()
	$AnimatedSprite2D.animation = "dead"
	$Area2D/CollisionShape2D.set_deferred("disabled", true)
	if randf() <= DROP_CHANCE:
		drop_item()
	var explosion = explosion_scene.instantiate()
	explosion.position = position
	main.add_child(explosion)
	explosion.process_mode = Node.PROCESS_MODE_ALWAYS
	
func drop_item():
	var item = item_scene.instantiate()
	item.position = position
	item.item_type =  randi_range(0, 2)
	main.call_deferred("add_child", item)
	item.add_to_group("items")

func _on_entrance_timer_timeout() -> void:
		entered = true


func _on_area_2d_body_entered(_body: Node2D) -> void:
	hit_player.emit()
