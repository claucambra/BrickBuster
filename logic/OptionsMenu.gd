extends Popup

signal options_changed

# This script handles the logic for the game's options menu.
# It handles getting the correct setting states from the global script's
# config and to set values correctly to the config.

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var standard_selected_theme_item_idx = null
var mega_selected_theme_item_idx = null

onready var global = get_node("/root/Global")
onready var light_switch = $TabContainer/General/VBoxContainer/SettingsSwitchesContainer/LightSwitch
onready var audio_switch = $TabContainer/General/VBoxContainer/SettingsSwitchesContainer/AudioSwitch
onready var volume_slider = $TabContainer/General/VBoxContainer/SettingsSwitchesContainer/VolumeSlider
onready var standard_themes_list = $TabContainer/Theming/Bricks/StandardBrick/ItemList
onready var mega_themes_list = $TabContainer/Theming/Bricks/MegaBrick/ItemList
onready var line_color_picker = $TabContainer/Theming/LaunchLine/ColorPicker

# Called when the node enters the scene tree for the first time.
func _ready():
	if global.err == OK:
		light_switch.pressed = global.config.get_value("lighting", "enabled")
		volume_slider.value = global.config.get_value("audio", "volume")
		if global.config.get_value("audio", "volume") == 0:
			audio_switch.pressed = false
	
	volume_slider.visible = audio_switch.pressed
	
	var iterator = 0
	var gradient = Gradient.new()
	for brick_theme in global.colour_themes:
		gradient.set_color(1, global.colour_themes[brick_theme].top_health)
		gradient.set_color(0, global.colour_themes[brick_theme].bottom_health)
		
		if brick_theme == global.config.get_value("theme", "standard_bricks"):
			standard_themes_list.add_item(global.colour_themes[brick_theme].display_name + " (Selected)")
			standard_selected_theme_item_idx = iterator
		else:
			standard_themes_list.add_item(global.colour_themes[brick_theme].display_name)
		standard_themes_list.set_item_metadata(iterator, brick_theme)
		standard_themes_list.set_item_custom_bg_color(iterator, gradient.interpolate(1))
		standard_themes_list.set_item_custom_fg_color(iterator, gradient.interpolate(0))
		
		if brick_theme == global.config.get_value("theme", "mega_bricks"):
			mega_themes_list.add_item(global.colour_themes[brick_theme].display_name + " (Selected)")
			mega_selected_theme_item_idx = iterator
		else:
			mega_themes_list.add_item(global.colour_themes[brick_theme].display_name)
		mega_themes_list.set_item_metadata(iterator, brick_theme)
		mega_themes_list.set_item_custom_bg_color(iterator, gradient.interpolate(1))
		mega_themes_list.set_item_custom_fg_color(iterator, gradient.interpolate(0))
		
		iterator += 1 
	
	line_color_picker.color = Color(global.config.get_value("theme", "launch_line_color"))
	
	var animation = Animation.new()
	var track_index = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_index, str(self.get_path()) + ":modulate:a")
	animation.track_insert_key(track_index, 0.0, 1.0)
	animation.track_insert_key(track_index, 0.3, 0.0)
	$AnimationPlayer.add_animation("fadeout", animation)
	$AnimationPlayer.connect("animation_finished", self, "on_Fadeout_finished")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_ApplyButton_pressed():
	var settings_changed = false
	var standard_theme_changed = false
	var mega_theme_changed = false
	var new_standard_theme_item_idx = null
	var new_mega_theme_item_idx = null
	
	if global.err == OK or global.err == ERR_FILE_NOT_FOUND:
		global.config.set_value("lighting", "enabled", light_switch.pressed)
		global.config.set_value("audio", "volume", volume_slider.value)
		settings_changed = true
	
	if standard_themes_list.is_anything_selected():
		new_standard_theme_item_idx = standard_themes_list.get_selected_items()[0]
		var selected_item_string = standard_themes_list.get_item_metadata(new_standard_theme_item_idx)
		global.config.set_value("theme", "standard_bricks", selected_item_string)
		settings_changed = true
		standard_theme_changed = true
	
	if mega_themes_list.is_anything_selected():
		new_mega_theme_item_idx = mega_themes_list.get_selected_items()[0]
		var selected_item_string = mega_themes_list.get_item_metadata(new_mega_theme_item_idx)
		global.config.set_value("theme", "mega_bricks", selected_item_string)
		settings_changed = true
		mega_theme_changed = true
	
	if line_color_picker.color.to_html() != global.config.get_value("theme", "launch_line_color"):
		global.config.set_value("theme", "launch_line_color", line_color_picker.color.to_html())
		settings_changed = true
	
	if settings_changed:
		global.config.save("user://settings.cfg")
		global.set_theme()
		emit_signal("options_changed")

		if standard_theme_changed:
			var prev_std_selected_item_text = standard_themes_list.get_item_text(standard_selected_theme_item_idx).replace(" (Selected)", "")
			standard_themes_list.set_item_text(standard_selected_theme_item_idx, prev_std_selected_item_text)
			var new_std_selected_item_text = standard_themes_list.get_item_text(new_standard_theme_item_idx) + " (Selected)"
			standard_themes_list.set_item_text(new_standard_theme_item_idx, new_std_selected_item_text)
			standard_selected_theme_item_idx = new_standard_theme_item_idx
		
		if mega_theme_changed:
			var prev_mega_selected_item_text = mega_themes_list.get_item_text(mega_selected_theme_item_idx).replace(" (Selected)", "")
			mega_themes_list.set_item_text(mega_selected_theme_item_idx, prev_mega_selected_item_text)
			var new_mega_selected_item_text = mega_themes_list.get_item_text(new_mega_theme_item_idx) + " (Selected)"
			mega_themes_list.set_item_text(new_mega_theme_item_idx, new_mega_selected_item_text)
			mega_selected_theme_item_idx = new_mega_theme_item_idx

func _on_CloseButton_pressed():
	$AnimationPlayer.play("fadeout")

func on_Fadeout_finished(_anim_name):
	hide()

func _on_AudioSwitch_pressed():
	volume_slider.visible = audio_switch.pressed
	
	if volume_slider.visible:
		volume_slider.value = 100
	else:
		volume_slider.value = 0
