extends Button


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var config = ConfigFile.new()
var err = config.load("user://settings.cfg")

onready var light_switch = $PopupMenu/MarginContainer/VBoxContainer/SettingsSwitchesContainer/LightSwitch

var lighting_enabled = config.get_value("lighting", "enabled")

# Called when the node enters the scene tree for the first time.
func _ready():
	if err == OK:
		light_switch.pressed = config.get_value("lighting", "enabled")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_ApplyButton_pressed():
	if err == OK || err == ERR_FILE_NOT_FOUND:
		config.set_value("lighting", "enabled", light_switch.pressed)
		config.save("user://settings.cfg")

func _on_OkButton_pressed():
	$PopupMenu.hide()
