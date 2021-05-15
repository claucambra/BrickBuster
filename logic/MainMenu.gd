extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# We want to take care of these in the right order in our ready func
var ball = null
var popup_game_mode_menu = null
var popup_balls_menu = null
var popup_options_menu = null
var popup_score_menu = null
var popups = []

onready var global = get_node("/root/Global")
onready var new_game_button = $CanvasLayer/MainMenu/VBoxContainer/NewGameButton
onready var continue_button = $CanvasLayer/MainMenu/VBoxContainer/ContinueButton
onready var scores_button = $CanvasLayer/MainMenu/VBoxContainer/ScoresButton
onready var balls_button = $CanvasLayer/MainMenu/VBoxContainer/BallsButton
onready var options_button = $CanvasLayer/MainMenu/VBoxContainer/OptionsButton


func close_popups():
	for popup in popups:
		popup.visible = false



# Called when the node enters the scene tree for the first time.
func _ready():
	var no_scores = true
	for score_array in global.save_game_data["past_scores"]:
		if !global.save_game_data["past_scores"][score_array].empty():
			no_scores = false
	
	if !global.save_game_data || no_scores:
		continue_button.visible = false
		scores_button.disabled = true
	
	ball = global.selected_ball_scene.instance()
	add_child(ball)
	
	global.rng.randomize()
	$TitleBrick.health = 90000
	$TitleBrick.max_possible_health = 100000
	ball.position = Vector2(512, 1216)
	ball.launch(Vector2(global.rng.randf_range(1, -1), global.rng.randf_range(-0, -1)))
	ball.get_node("Light2D").energy = 1
	ball.get_node("Light2D").enabled = global.config.get_value("lighting", "enabled")
	ball.set_color(global.config.get_value("ball", "color"))
	
	popup_game_mode_menu = $CanvasLayer/MainMenu/VBoxContainer/NewGameButton/GameModeMenu
	new_game_button.add_child(popup_game_mode_menu)
	popup_balls_menu = load("res://scenes/SubMenus/BallMenu.tscn").instance()
	balls_button.add_child(popup_balls_menu)
	popup_options_menu = load("res://scenes/SubMenus/OptionsMenu.tscn").instance()
	options_button.add_child(popup_options_menu)
	popup_score_menu = load("res://scenes/SubMenus/ScoreMenu.tscn").instance()
	scores_button.add_child(popup_score_menu)
	popups = [popup_game_mode_menu, popup_balls_menu, popup_options_menu, popup_score_menu]
	
	popup_game_mode_menu.connect("game_mode_selected", self, "on_game_mode_selected")
	popup_balls_menu.connect("color_changed", self, "on_color_changed")
	popup_balls_menu.connect("ball_changed", self, "on_ball_changed")
	popup_options_menu.connect("options_changed", self, "on_options_changed")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_ContinueButton_pressed():
	get_tree().change_scene("res://scenes/Board.tscn")
	
func _on_NewGameButton_pressed():
	close_popups()
	popup_game_mode_menu.visible = !popup_game_mode_menu.visible

func _on_QuitButton_pressed():
	get_tree().quit()

func _on_ScoresButton_pressed():
	close_popups()
	popup_score_menu.visible = !popup_score_menu.visible

func _on_OptionsButton_pressed():
	close_popups()
	popup_options_menu.visible = !popup_options_menu.visible

func _on_BallsButton_pressed():
	close_popups()
	popup_balls_menu.visible = !popup_balls_menu.visible

func on_game_mode_selected(game_mode_name):
	global.write_save_file(game_mode_name)
	get_tree().change_scene("res://scenes/Board.tscn")

func on_color_changed():
	global.config.load("user://settings.cfg")
	ball.set_color(global.config.get_value("ball", "color"))

func on_ball_changed():
	global.config.load("user://settings.cfg")
	var ball_position = ball.position
	var ball_angular_velocity = ball.get_angular_velocity()
	var ball_linear_velocity = ball.get_linear_velocity()
	ball.queue_free()
	var ball_scene = load("res://scenes/Balls/" + global.config.get_value("ball", "ball_file_name"))
	ball = ball_scene.instance()
	add_child(ball)
	ball.position = ball_position
	ball.set_angular_velocity(ball_angular_velocity)
	ball.set_linear_velocity(ball_linear_velocity)
	ball.get_node("Light2D").energy = 1
	ball.get_node("Light2D").enabled = global.config.get_value("lighting", "enabled")
	ball.set_color(global.config.get_value("ball", "color"))

func on_options_changed():
	global.config.load("user://settings.cfg")
	ball.get_node("Light2D").enabled = global.config.get_value("lighting", "enabled")
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), global.config.get_value("audio", "volume") == 0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), global.config.get_value("audio", "volume"))
