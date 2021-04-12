extends Popup

signal options_changed

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var config = ConfigFile.new()
var err = config.load("user://settings.cfg")

onready var light_switch = $MarginContainer/VBoxContainer/SettingsSwitchesContainer/LightSwitch
onready var audio_switch = $MarginContainer/VBoxContainer/SettingsSwitchesContainer/AudioSwitch
onready var volume_slider = $MarginContainer/VBoxContainer/SettingsSwitchesContainer/VolumeSlider

# Called when the node enters the scene tree for the first time.
func _ready():
	print(config.get_value("audio", "volume"))
	if err == OK:
		light_switch.pressed = config.get_value("lighting", "enabled")
		volume_slider.value = config.get_value("audio", "volume")
		if config.get_value("audio", "volume") == 0:
			audio_switch.pressed = false
	
	volume_slider.visible = audio_switch.pressed

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_ApplyButton_pressed():
	if err == OK || err == ERR_FILE_NOT_FOUND:
		config.set_value("lighting", "enabled", light_switch.pressed)
		config.set_value("audio", "volume", volume_slider.value)
		config.save("user://settings.cfg")
	
	emit_signal("options_changed")

func _on_OkButton_pressed():
	hide()

func _on_AudioSwitch_pressed():
	volume_slider.visible = audio_switch.pressed
	
	if volume_slider.visible:
		volume_slider.value = 100
	else:
		volume_slider.value = 0
