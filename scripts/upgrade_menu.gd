# upgrade_menu.gd - Handles the upgrade menu UI

extends Control

@onready var main = get_parent()
@onready var player = get_parent().get_node("Player")

var upgrade_manager: UpgradeManager
var upgrade_options: Array[String] = []

# UI References (you'll need to create these buttons in editor)
@onready var button1 = $Button1
@onready var button2 = $Button2
@onready var button3 = $Button3

func _ready() -> void:
	# Create upgrade manager
	upgrade_manager = UpgradeManager.new()
	
	# Hide menu initially
	hide()
	
	# Wait for buttons to be ready, then connect
	await get_tree().process_frame
	
	# Connect buttons with proper error checking
	if button1:
		button1.pressed.connect(_on_upgrade_selected.bind(0))
	else:
		print("ERROR: Button1 not found!")
		
	if button2:
		button2.pressed.connect(_on_upgrade_selected.bind(1))
	else:
		print("ERROR: Button2 not found!")
		
	if button3:
		button3.pressed.connect(_on_upgrade_selected.bind(2))
	else:
		print("ERROR: Button3 not found!")
	
	
# Show upgrade menu with 3 options
func show_upgrade_menu() -> void:
	# DON'T pause the entire tree - just disable player input
	get_tree().paused = false  # ✅ Don't pause
	
	# Disable player input instead
	get_parent().get_node("Player").process_mode = Node.PROCESS_MODE_DISABLED
	
	# Get upgrade options
	upgrade_options = upgrade_manager.get_upgrade_options()
	
	# Display buttons
	display_upgrade_options()
	
	# Show the menu (should be on top)
	show()
	# REMOVE: move_child(self, get_parent().get_child_count() - 1)

# Display the upgrade options on screen
func display_upgrade_options() -> void:
	var option_names = {
		"shotgun": "SHOTGUN UPGRADE",
		"rifle": "RIFLE UPGRADE",
		"flamethrower": "FLAMETHROWER"
	}
	
	# Set button text only (no descriptions)
	for i in range(min(3, upgrade_options.size())):
		var option = upgrade_options[i]
		match i:
			0:
				button1.text = option_names[option]
			1:
				button2.text = option_names[option]
			2:
				button3.text = option_names[option]
				
				
func _on_upgrade_selected(index: int) -> void:
	if index < upgrade_options.size():
		var selected = upgrade_options[index]
		upgrade_manager.apply_upgrade(selected, player)
		
		# Re-enable player
		player.process_mode = Node.PROCESS_MODE_INHERIT
		
		# Close menu
		hide()
		
		# Continue game
		main.on_upgrade_complete()

# Get current upgrade levels for display
func get_upgrade_info() -> Dictionary:
	return {
		"pistol_level": upgrade_manager.pistol_level,
		"shotgun_level": upgrade_manager.shotgun_level,
		"rifle_level": upgrade_manager.rifle_level,
		"has_flamethrower": upgrade_manager.has_flamethrower
	}
