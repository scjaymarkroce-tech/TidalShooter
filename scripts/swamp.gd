extends Area2D

signal hit_player

func _ready():
	# 🐛 THE FIX: Add to a group so we can wipe them out on game over!
	add_to_group("swamps")
	
	$AnimatedSprite2D.play("swamp")
	
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1, 1), 0.5)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		hit_player.emit()
