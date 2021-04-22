extends Popup

signal color_changed
signal ball_changed

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var save_game = File.new()
var config = ConfigFile.new()
var err = config.load("user://settings.cfg")

var ball_scenes = []

onready var ball_list = $TabContainer/BallPicker/ScrollContainer/ItemList
onready var color_picker = $TabContainer/ColourMenu/VBoxContainer/ColorPicker

func fetch_balls():
	var ball_scenes_dir = Directory.new()
	var path = "res://scenes/Balls/"
	ball_scenes_dir.open(path)
	ball_scenes_dir.list_dir_begin()

	while true:
		var file_name = ball_scenes_dir.get_next()
		if file_name == "":
			break
		elif not file_name.begins_with("."):
			var ball_scene = load(path + file_name)
			ball_scenes.append({"filename": file_name, "ball_scene": ball_scene})

	ball_scenes_dir.list_dir_end()

# Called when the node enters the scene tree for the first time.
func _ready():
	if err == OK:
		color_picker.color = config.get_value("ball", "color")
	
	fetch_balls()
	var iterator = 0
	for ball_scene in ball_scenes:
		var ball_filename = ball_scene["filename"]
		var ball_meta = ball_scene["ball_scene"].instance().get_node("MetaNode")
		ball_list.add_item(ball_meta.ball_name, ball_meta.ball_icon)
		ball_list.set_item_metadata(iterator, ball_filename)
		
		# Make balls selectable if high score is high enough
		if ball_meta.get("min_score") && save_game.file_exists("user://savegame.save"):
			save_game.open("user://savegame.save", File.READ)
			var node_data = parse_json(save_game.get_line())
			var past_scores = node_data["past_scores"]
			if past_scores.max():
				for score in past_scores:
					score = int(score)
				ball_list.set_item_disabled(iterator, ball_meta.min_score > past_scores.max())
				ball_list.set_item_tooltip(iterator, "Unlocked after scoring " + String(ball_meta.min_score) + " or more")
		elif ball_meta.get("min_score"):
			ball_list.set_item_selectable(iterator, false)
		
		# Highlight the selected ball
		if ball_filename == config.get_value("ball", "ball_file_name"):
			ball_list.set_item_custom_bg_color(iterator, ColorN("red", 1))
		iterator += 1
	if config.get_value("ball", "ball_file_name") == null:
		ball_list.set_item_custom_bg_color(0, ColorN("red", 1))


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_ApplyButton_pressed():
	if err == OK || err == ERR_FILE_NOT_FOUND:
		config.set_value("ball", "color", color_picker.color)
		if !ball_list.is_anything_selected() && config.get_value("ball", "ball_file_name") == null:
			config.set_value("ball", "ball_file_name", "Ball.tscn")
		elif ball_list.is_anything_selected():
			config.set_value("ball", "ball_file_name", ball_list.get_item_metadata(ball_list.get_selected_items()[0]))
			for item_index in ball_list.get_item_count():
				 ball_list.set_item_custom_bg_color(item_index, ColorN("red", 0))
			ball_list.set_item_custom_bg_color(ball_list.get_selected_items()[0], ColorN("red", 1))
			ball_list.unselect_all()
		
		config.save("user://settings.cfg")
		emit_signal("color_changed")
		emit_signal("ball_changed")

func _on_OkButton_pressed():
	hide()
