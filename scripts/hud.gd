extends CanvasLayer  # or Control, depending on your HUD root

# GUN ICONS - set your real image paths here! (Texture2D for Godot 4+)
var pistol_icon : Texture2D
var shotgun_icon : Texture2D
var rifle_icon : Texture2D
var flamethrower_icon : Texture2D

func _ready():
	# Load your icons once using real resource paths
	pistol_icon = load("res://ADDED/tgun0.png")
	shotgun_icon = load("res://ADDED/tgun1-Photoroom.png")
	rifle_icon = load("res://ADDED/tgun2-Photoroom.png")
	flamethrower_icon = load("res://ADDED/tgun3-Photoroom.png")
	update_gun_icon(1)  # default to pistol
	ScoreManager.score_changed.connect(_on_score_changed)
	_on_score_changed(ScoreManager.score)
	update_ammo(0, 0)   # <-- Fix here
	show_reload(false)
	set_dodge_cooldown(0.0, 1.0)
	
func _on_score_changed(new_score: int):
	$ScoreLabel.text = "SCORE: %d" % new_score
	
	
# --- GUN ICON ---
func update_gun_icon(weapon_id : int):
	match weapon_id:
		1:
			$GunIcon.texture = pistol_icon
		2:
			$GunIcon.texture = shotgun_icon
		3:
			$GunIcon.texture = rifle_icon
		4:
			$GunIcon.texture = flamethrower_icon

# --- SCORE ---
func update_score(new_score : int):
	$ScoreLabel.text = str(new_score)

# --- AMMO ---
func update_ammo(current: int, max: int):
	if max <= 0:
		$AmmoLabel.visible = false    # HIDE AMMO LABEL FOR FLAMETHROWER
	else:
		$AmmoLabel.visible = true
		$AmmoLabel.text = "%d / %d" % [current, max]

# --- RELOAD VISUAL ---
func show_reload(show: bool, percent: float = 0.0):
	$ReloadBar.visible = show
	if show:
		$ReloadBar.value = percent * 100  # Assume bar max is 100

# --- DODGE COOLDOWN VISUAL ---
# Call start_dodge_cooldown(2.0) when dodge begins!
var dodge_cooldown_time = 2.0
var dodge_timer = 0.0
var dodge_active = false

func start_dodge_cooldown(duration: float):
	dodge_cooldown_time = duration
	dodge_timer = 0.0
	dodge_active = true
	$DodgeBar.visible = true

func set_dodge_cooldown(elapsed: float, duration: float):
	if duration <= 0:
		$DodgeBar.visible = false
		return
	$DodgeBar.value = (elapsed / duration) * 100
	$DodgeBar.visible = elapsed < duration

func _process(delta):
	if dodge_active:
		dodge_timer += delta
		set_dodge_cooldown(dodge_timer, dodge_cooldown_time)
		if dodge_timer >= dodge_cooldown_time:
			dodge_active = false
			$DodgeBar.visible = false
