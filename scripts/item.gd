extends Area2D

@onready var main = get_node("/root/Main")
@onready var lives_label = get_node("/root/Main/Hud/LivesLabel")


var item_type : int # 0: coffee, 1: health, 2: gun

var coffee_box = preload("res://assets/items/coffee_box.png")
var health_box = preload("res://assets/items/health_box.png")
var gun_box = preload("res://assets/items/gun_box.png")
var  textures = [coffee_box, health_box, gun_box]


func _ready() -> void:
	$Sprite2D.texture = textures[item_type]


func _on_body_entered(body: Node2D) -> void:
#	coffee
	if item_type == 0:
		print("Got a Coffee")
		body.boost()
#	health
	elif item_type == 1:
		main.lives += 1
		lives_label.text = "X " + str(main.lives)
		print("Got a Health")
#	gun
	elif item_type == 2:
		print("Got a Gun")
		body.quick_fire()
		
#	to delete after taking buff
	queue_free()
	
