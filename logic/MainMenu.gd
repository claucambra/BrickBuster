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
var popup_donate_menu = null
var popup_help_menu = null
var popups = []

var go_to_board = false

onready var global = get_node("/root/Global")
onready var title_brick = $TitleBrick
onready var main_menu = $CanvasLayer/MainMenu
onready var buttons_container = $CanvasLayer/MainMenu/VBoxContainer
onready var new_game_button = $CanvasLayer/MainMenu/VBoxContainer/NewGameButton
onready var continue_button = $CanvasLayer/MainMenu/VBoxContainer/ContinueButton
onready var scores_button = $CanvasLayer/MainMenu/VBoxContainer/ScoresButton
onready var balls_button = $CanvasLayer/MainMenu/VBoxContainer/BallsButton
onready var options_button = $CanvasLayer/MainMenu/VBoxContainer/OptionsButton
onready var donate_button = $CanvasLayer/MainMenu/VBoxContainer/DonateButton
onready var help_button = $CanvasLayer/MainMenu/VBoxContainer/HelpButton
onready var quit_button = $CanvasLayer/MainMenu/VBoxContainer/QuitButton


func close_popups():
	for popup in popups:
		popup.visible = false

func set_menu_colours():
	var gradient = Gradient.new()
	gradient.set_color(1, global.colour_themes[global.selected_standard_theme].top_health)
	gradient.set_color(0, global.colour_themes[global.selected_standard_theme].bottom_health)
	title_brick.gradient.set_color(1, global.colour_themes[global.selected_mega_theme].top_health)
	title_brick.gradient.set_color(0, global.colour_themes[global.selected_mega_theme].bottom_health)
	
	var iterator = 1
	for button in buttons_container.get_children():
		var new_style_normal = StyleBoxFlat.new()
		var new_style_hover = StyleBoxFlat.new()
		var new_style_pressed = StyleBoxFlat.new()
		
		var normal_color = gradient.interpolate(float(iterator)/float(buttons_container.get_child_count()))
		var hover_color = Color(normal_color.r, normal_color.g, normal_color.b, 0.8)
		var pressed_color = Color(normal_color.r, normal_color.g, normal_color.b, 0.5)
		
		new_style_normal.set_bg_color(normal_color)
		new_style_hover.set_bg_color(hover_color)
		new_style_pressed.set_bg_color(pressed_color)
		
		button.set('custom_styles/normal', new_style_normal)
		button.set('custom_styles/hover', new_style_hover)
		button.set('custom_styles/pressed', new_style_pressed)
		
		iterator += 1

# Called when the node enters the scene tree for the first time.
func _ready():
	var no_scores = true
	if global.save_game_data && global.save_game_data.has("past_scores"):
		for score_array in global.save_game_data["past_scores"]:
			if !global.save_game_data["past_scores"][score_array].empty():
				no_scores = false
	
	if !global.save_game_data || no_scores:
		continue_button.visible = false
		scores_button.disabled = true
	
	ball = global.selected_ball_scene.instance()
	add_child(ball)
	
	global.rng.randomize()
	title_brick.mega = true
	title_brick.health = 90000
	title_brick.max_possible_health = 100000
	ball.position = Vector2(512, 1216)
	ball.launch(Vector2(global.rng.randf_range(1, -1), global.rng.randf_range(-0, -1)))
	ball.get_node("Light2D").energy = 1
	ball.get_node("Light2D").enabled = global.config.get_value("lighting", "enabled")
	ball.set_color(global.config.get_value("ball", "color"))
	
	popup_game_mode_menu = load("res://scenes/SubMenus/GameModeMenu.tscn").instance()
	new_game_button.add_child(popup_game_mode_menu)
	popup_balls_menu = load("res://scenes/SubMenus/BallMenu.tscn").instance()
	balls_button.add_child(popup_balls_menu)
	popup_options_menu = load("res://scenes/SubMenus/OptionsMenu.tscn").instance()
	options_button.add_child(popup_options_menu)
	popup_score_menu = load("res://scenes/SubMenus/ScoreMenu.tscn").instance()
	scores_button.add_child(popup_score_menu)
	popup_donate_menu = load("res://scenes/SubMenus/DonateMenu.tscn").instance()
	donate_button.add_child(popup_donate_menu)
	popup_help_menu = load("res://scenes/SubMenus/Instructions.tscn").instance()
	help_button.add_child(popup_help_menu)
	popups = [popup_game_mode_menu, popup_balls_menu, popup_options_menu, popup_score_menu, popup_donate_menu, popup_help_menu]
	
	popup_game_mode_menu.connect("game_mode_selected", self, "on_game_mode_selected")
	popup_balls_menu.connect("color_changed", self, "on_color_changed")
	popup_balls_menu.connect("ball_changed", self, "on_ball_changed")
	popup_options_menu.connect("options_changed", self, "on_options_changed")
	
	set_menu_colours()
	
	for popup in popups:
		var animation = Animation.new()
		var track_index = animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(track_index, str(popup.get_path()) + ":modulate:a")
		animation.track_insert_key(track_index, 0.0, 0.0)
		animation.track_insert_key(track_index, 0.3, 1.0)
		$AnimationPlayer.add_animation(popup.name + "_fadein", animation)
	
	# Fade-in and fade-out animation for the whole main menu has been added through UI to AnimationPlayer node
	if OS.get_name() == "Android" || OS.get_name() == "iOS":
		donate_button.hide()
		quit_button.hide()
	# Uncomment for non Play Store / App Store export

# Called every frame. 'delta' is the elapsed time since the previous frame.
# func _process(delta):
#	pass

# There must be a way to do these in a more automatic manner.
func _on_ContinueButton_pressed():
	$AnimationPlayer.play("fadeout")
	
func _on_NewGameButton_pressed():
	close_popups()
	popup_game_mode_menu.visible = true
	$AnimationPlayer.play(popup_game_mode_menu.name + "_fadein")

func _on_QuitButton_pressed():
	get_tree().quit()

func _on_ScoresButton_pressed():
	close_popups()
	popup_score_menu.visible = true
	$AnimationPlayer.play(popup_score_menu.name + "_fadein")

func _on_OptionsButton_pressed():
	close_popups()
	popup_options_menu.visible = true
	$AnimationPlayer.play(popup_options_menu.name + "_fadein")

func _on_BallsButton_pressed():
	close_popups()
	popup_balls_menu.visible = true
	$AnimationPlayer.play(popup_balls_menu.name + "_fadein")

func _on_DonateButton_pressed():
	close_popups()
	popup_donate_menu.visible = true
	$AnimationPlayer.play(popup_donate_menu.name + "_fadein")

func _on_HelpButton_pressed():
	close_popups()
	popup_help_menu.visible = true
	$AnimationPlayer.play(popup_help_menu.name + "_fadein")

func on_game_mode_selected(game_mode_name):
	global.write_save_file(game_mode_name)
	$AnimationPlayer.play("fadeout")

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
	set_menu_colours()



func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "fadeout":
		get_tree().change_scene("res://scenes/Board.tscn")

