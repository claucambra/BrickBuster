extends Popup

signal color_changed
signal ball_changed

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var global = get_node("/root/Global")
onready var ball_list = $TabContainer/BallPicker/ScrollContainer/ItemList
onready var color_picker = $TabContainer/ColourMenu/VBoxContainer/ColorPicker

# Called when the node enters the scene tree for the first time.
func _ready():
	if global.err == OK:
		color_picker.color = global.config.get_value("ball", "color")
	
	var iterator = 0
	for ball_scene in global.ball_scenes:
		var ball_filename = ball_scene["filename"]
		var ball_meta = ball_scene["ball_scene"].instance().get_node("MetaNode")
		ball_list.add_item(ball_meta.ball_name, ball_meta.ball_icon)
		ball_list.set_item_metadata(iterator, ball_filename)
		
		# Make balls selectable if high score is high enough
		if ball_meta.get("min_score") && global.save_game_data:
			var past_scores = global.save_game_data["past_scores"]
			if past_scores.standard.max():
				for score in past_scores:
					score = int(score)
				ball_list.set_item_disabled(iterator, ball_meta.min_score > past_scores.standard.max())
				ball_list.set_item_tooltip(iterator, "Unlocked after scoring " + String(ball_meta.min_score) + " or more")
		elif ball_meta.get("min_score"):
			ball_list.set_item_selectable(iterator, false)
		
		# Highlight the selected ball
		if ball_filename == global.config.get_value("ball", "ball_file_name"):
			ball_list.set_item_custom_bg_color(iterator, ColorN("red", 1))
		iterator += 1
	if global.config.get_value("ball", "ball_file_name") == null:
		ball_list.set_item_custom_bg_color(0, ColorN("red", 1))


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_ApplyButton_pressed():
	if global.err == OK || global.err == ERR_FILE_NOT_FOUND:
		global.config.set_value("ball", "color", color_picker.color)
		if !ball_list.is_anything_selected() && global.config.get_value("ball", "ball_file_name") == null:
			global.config.set_value("ball", "ball_file_name", "Ball.tscn")
		elif ball_list.is_anything_selected():
			global.config.set_value("ball", "ball_file_name", ball_list.get_item_metadata(ball_list.get_selected_items()[0]))
			for item_index in ball_list.get_item_count():
				 ball_list.set_item_custom_bg_color(item_index, ColorN("red", 0))
			ball_list.set_item_custom_bg_color(ball_list.get_selected_items()[0], ColorN("red", 1))
			ball_list.unselect_all()
		
		global.config.save("user://settings.cfg")
		global.reload_selected_ball()
		emit_signal("color_changed")
		emit_signal("ball_changed")

func _on_CloseButton_pressed():
	hide()
