extends Area2D


var speed : int = 500
var direction : Vector2

var damage : int = 10

var is_flame := false

var max_range := 500  # default for pistol/rifle, change per-shot
var distance_travelled := 0.0

var piercing: int = 0  # How many enemies it can go through (0=none)

func _ready():
	if is_flame:
		scale = Vector2(2.5, 2.5)  # 🔥 bigger hit feel
	

func _process(delta):
	var actual_speed = speed
	if is_flame:
		actual_speed = 300  # slower = better coverage
	
	var move_dist = actual_speed * delta
	position += direction * move_dist
	distance_travelled += move_dist
	
	if distance_travelled > max_range:
		queue_free()


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
