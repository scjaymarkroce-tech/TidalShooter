extends Control

var options := []
var upgrade_manager = UpgradeManager.new()
@onready var player = get_parent().get_node("Player")

func open_menu():
	get_tree().paused = true
	visible = true
	# Set up options for this round (randomly or rotate)
	options = upgrade_manager.get_upgrade_options()
	# Set button text, etc.
	$Button1.text = options[0].capitalize()
	$Button2.text = options[1].capitalize()
	if options.size() > 2:
		$Button3.text = options[2].capitalize()
		$Button3.visible = true
	else:
		$Button3.text = ""
		$Button3.visible = false

	visible = true
	# Disable player processing
	player.process_mode = Node.PROCESS_MODE_DISABLED

func _on_Button1_pressed():
	_finish_upgrade(0)
func _on_Button2_pressed():
	_finish_upgrade(1)
func _on_Button3_pressed():
	if options.size() > 2:
		_finish_upgrade(2)

func _finish_upgrade(idx):
	var choice = options[idx]
	upgrade_manager.apply_upgrade(choice, player)
	player.process_mode = Node.PROCESS_MODE_INHERIT
	visible = false
	get_tree().paused = false
	# Properly signal main (parent) to continue its wave flow
	get_parent()._on_upgrade_menu_closed()
