extends Popup

signal color_changed

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

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
			ball_scenes.append(ball_scene)

	ball_scenes_dir.list_dir_end()

# Called when the node enters the scene tree for the first time.
func _ready():
	if err == OK:
		color_picker.color = config.get_value("ball", "color")
	
	fetch_balls()
	for ball_scene in ball_scenes:
		var ball = ball_scene.instance()
		ball_list.add_item(ball.ball_name, ball.ball_icon)


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
