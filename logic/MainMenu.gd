extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var save_game = File.new()
var rng = RandomNumberGenerator.new()
var config = ConfigFile.new()
var err = config.load("user://settings.cfg")

var ball = null

onready var scores_button = $CanvasLayer/MainMenu/VBoxContainer/ScoresButton
onready var popup_score_menu = $CanvasLayer/MainMenu/VBoxContainer/ScoresButton/ScoresMenu
onready var balls_button = $CanvasLayer/MainMenu/VBoxContainer/BallsButton
onready var popup_balls_menu = $CanvasLayer/MainMenu/VBoxContainer/BallsButton/BallsMenu
onready var options_button = $CanvasLayer/MainMenu/VBoxContainer/OptionsButton
onready var popup_options_menu = $CanvasLayer/MainMenu/VBoxContainer/OptionsButton/OptionsMenu
onready var popups = [popup_score_menu, popup_balls_menu, popup_options_menu]

func write_save_file(first_save = false):
	var save_dict = {
		"game_mode": "standard",
		"score": 0,
		"ammo": 1,
		"launch_ball_position_x": 360,
		"launch_ball_position_y": 1072,
		"destroyables" : []
	}
	
	if first_save:
		save_dict["past_scores"] = []
	else:
		save_game.open("user://savegame.save", File.READ)
		var node_data = parse_json(save_game.get_line())
		save_dict["past_scores"] = node_data["past_scores"]
	
	save_game.open("user://savegame.save", File.WRITE)
	save_game.store_line(to_json(save_dict))
	save_game.close()

# Called when the node enters the scene tree for the first time.
func _ready():
	if save_game.file_exists("user://savegame.save"):
		save_game.open("user://savegame.save", File.READ)
		while save_game.get_position() < save_game.get_len():
			var node_data = parse_json(save_game.get_line())
			var past_scores = node_data["past_scores"]
			if past_scores.empty():
				scores_button.disabled = true
	else:
		$CanvasLayer/MainMenu/VBoxContainer/ContinueButton.visible = false
		$CanvasLayer/MainMenu/VBoxContainer/ScoresButton.disabled = true
		write_save_file(true)
	
	if err == ERR_FILE_NOT_FOUND:
		config.set_value("lighting", "enabled", true)
		config.set_value("audio", "volume", 10)
		config.set_value("ball", "color", "#ffffff")
		config.set_value("ball", "ball_file_name", "Ball.tscn")
		config.save("user://settings.cfg")
		config.load("user://settings.cfg")
	
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), config.get_value("audio", "volume") == 0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), config.get_value("audio", "volume"))
	
	if config.get_value("ball", "ball_file_name") == null:
		config.set_value("ball", "ball_file_name", "Ball.tscn")
		config.save("user://settings.cfg")
		config.load("user://settings.cfg")
	var ball_scene = load("res://scenes/Balls/" + config.get_value("ball", "ball_file_name"))
	ball = ball_scene.instance()
	add_child(ball)
	
	rng.randomize()
	$TitleBrick.health = 90000
	$TitleBrick.max_possible_health = 100000
	ball.position = Vector2(512, 1216)
	ball.launch(Vector2(rng.randf_range(1, -1),rng.randf_range(-0, -1)))
	ball.get_node("Light2D").energy = 1
	ball.get_node("Light2D").enabled = config.get_value("lighting", "enabled")
	ball.set_color(config.get_value("ball", "color"))
	
	popup_balls_menu.connect("color_changed", self, "on_color_changed")
	popup_balls_menu.connect("ball_changed", self, "on_ball_changed")
	popup_options_menu.connect("options_changed", self, "on_options_changed")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_ContinueButton_pressed():
	get_tree().change_scene("res://scenes/Board.tscn")
	
func _on_NewGameButton_pressed():
	write_save_file()
	
	get_tree().change_scene("res://scenes/Board.tscn")

func _on_QuitButton_pressed():
	get_tree().quit()

func _on_ScoresButton_pressed():
	popup_options_menu.visible = false
	popup_balls_menu.visible = false
	popup_score_menu.visible = !popup_score_menu.visible

func _on_OptionsButton_pressed():
	popup_score_menu.visible = false
	popup_balls_menu.visible = false
	popup_options_menu.visible = !popup_options_menu.visible

func _on_BallsButton_pressed():
	popup_score_menu.visible = false
	popup_options_menu.visible = false
	popup_balls_menu.visible = !popup_balls_menu.visible


func on_color_changed():
	config.load("user://settings.cfg")
	ball.set_color(config.get_value("ball", "color"))

func on_ball_changed():
	config.load("user://settings.cfg")
	var ball_position = ball.position
	var ball_angular_velocity = ball.get_angular_velocity()
	var ball_linear_velocity = ball.get_linear_velocity()
	ball.queue_free()
	var ball_scene = load("res://scenes/Balls/" + config.get_value("ball", "ball_file_name"))
	ball = ball_scene.instance()
	add_child(ball)
	ball.position = ball_position
	ball.set_angular_velocity(ball_angular_velocity)
	ball.set_linear_velocity(ball_linear_velocity)
	ball.get_node("Light2D").energy = 1
	ball.get_node("Light2D").enabled = config.get_value("lighting", "enabled")
	ball.set_color(config.get_value("ball", "color"))

func on_options_changed():
	config.load("user://settings.cfg")
	ball.get_node("Light2D").enabled = config.get_value("lighting", "enabled")
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), config.get_value("audio", "volume") == 0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), config.get_value("audio", "volume"))
