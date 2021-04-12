extends Popup

signal color_changed

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var config = ConfigFile.new()
var err = config.load("user://settings.cfg")

onready var color_picker = $TabContainer/ColourMenu/VBoxContainer/ColorPicker

# Called when the node enters the scene tree for the first time.
func _ready():
	if err == OK:
		color_picker.color = config.get_value("ball", "color")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_ApplyButton_pressed():
	if err == OK || err == ERR_FILE_NOT_FOUND:
		config.set_value("ball", "color", color_picker.color)
		config.save("user://settings.cfg")
	
	emit_signal("color_changed")

func _on_OkButton_pressed():
	hide()
