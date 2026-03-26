extends Area2D


var speed : int = 500
var direction : Vector2

var damage : int = 10

var is_flame := false

func _ready():
	if is_flame:
		scale = Vector2(2.5, 2.5)  # 🔥 bigger hit feel
	

func _process(delta):
#	
	var actual_speed = speed
	
	if is_flame:
		actual_speed = 300  # slower = better coverage
		
#	NORMAL BULLET DIRECTION
	position += speed * direction * delta


func _on_timer_timeout() -> void:
	queue_free()


func _on_body_entered(body: Node2D) -> void:
		if body.name == "World":
			queue_free()
		else:
			if body.has_method("take_damage"):
				body.take_damage(damage)
				queue_free()
