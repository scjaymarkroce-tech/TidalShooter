extends Control  # or CanvasLayer if that's your root

func _ready():
	$StartButton.pressed.connect(_on_start_pressed)
	if $QuitButton:  # In browser export, don't show a quit button
		$QuitButton.pressed.connect(_on_quit_pressed)
func _on_start_pressed():
	# Replace with your main game scene path!
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_quit_pressed():
	get_tree().quit()
