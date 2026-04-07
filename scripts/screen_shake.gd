extends Node

var shake_intensity: float = 0.0
var shake_timer: float = 0.0
var shake_duration: float = 0.0

func shake(intensity: float, duration: float):
	if intensity >= shake_intensity * (shake_timer / max(shake_duration, 0.001)):
		shake_intensity = intensity
		shake_timer = duration
		shake_duration = duration

func _process(delta: float):
	if shake_timer > 0:
		shake_timer -= delta
		var amount = shake_intensity * (shake_timer / shake_duration) 
		var offset = Vector2(randf_range(-amount, amount), randf_range(-amount, amount))
		
		# If there is a cinematic camera, shake that! Otherwise shake the whole canvas.
		var cam = get_viewport().get_camera_2d()
		if cam:
			cam.offset = offset
		else:
			var t = Transform2D()
			t.origin = offset
			get_viewport().canvas_transform = t
	else:
		shake_intensity = 0.0
		var cam = get_viewport().get_camera_2d()
		if cam:
			cam.offset = Vector2.ZERO
		else:
			get_viewport().canvas_transform = Transform2D()
