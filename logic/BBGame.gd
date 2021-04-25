# This file contains most of the functionality and the variables that are 
# universal to all of BrickBuster's gamemodes. This functionality includes:
#
# - Saving and loading the game
# - Pause menu behaviour and function
# - Configuration handling (i.e. lighting, ball colour settings, etc.)
# - Launch line calculations and drawing
# - Destroyable creation (and destroyable line creation) and behaviour
# - Live ball and live destroyable storage
# - Ball launching and launch cadence, and repositioning after launch
# - Updating score and ammo labels
# - Game over procedure and dead ball and destroyable instance handling
#
# Aspects of the game loop that vary depending on the game mode are left to the
# specific scripts that handle that game mode. These game mode scripts are
# handled, selected, and applied to the Board node by ModeSelector.gd (which is
# attached to the GameModeSelector node of this scene.
#
# GameMode scripts have the responsibility of handling the following:
#
# - Drag enabled state (i.e. when input is accepted) and when the user can
#	launch balls
# - How destroyables are relocated around the board during the game
# - How (or if) rounds are implemented and how they affect the game state

extends Node2D

signal game_prepped

# <---------------------------- MEMBER VARIABLES ---------------------------->
var config = ConfigFile.new()
var err = config.load("user://settings.cfg")

var game_over = false
# These variables are used to keep track of what stage of the round we are in
# This is used to decide input state and acceptance
var drag_enabled = false
var mouse_in_controlarea = false
var mouse_position = Vector2(0,0)
var line_direction = Vector2(0,0)
var first_click_position = Vector2(0,0)
var reasonable_angle = false
var draw_touch_marker = false
# launched is used to differentiate between states when there are no live balls
# i.e. idling vs just after all balls have returned to bottom of screen
var launched = false
var all_balls_launched = false
var round_in_progress = false
var repositioning_ball = false
var live_balls = []
var live_destroyables = []
var round_first_dead_ball_position = null
var score = 0
var past_scores = []
var ammo = 1
var rng = RandomNumberGenerator.new()
var lighting_enabled = true
var ball_color = "#ffffff"

var ball_scene = null
var ball = null

onready var meta_area = $Board/CanvasLayer/MetaArea
onready var current_score_label = $Board/CanvasLayer/MetaArea/MarginContainer/HBoxContainer/CurrentScoreLabel
onready var high_score_label = $Board/CanvasLayer/MetaArea/MarginContainer/HBoxContainer/VBoxContainer/HighScoreLabel
onready var ammo_label = $Board/CanvasLayer/BottomPanel/CenterContainer/AmmoLabel
onready var brick_scene = load("res://scenes/Brick.tscn")
onready var slanted_brick_scene = load("res://scenes/SlantedBrick.tscn")
onready var specials_scene = load("res://scenes/Specials.tscn")
onready var laserbeam_scene = load("res://scenes/LaserBeam.tscn")
# We use a ball instance to mark where our balls will launch from.
# This ball remains throughout the game, 
# moving position to where the last ball of the last round fell.
onready var launch_line = $Board/CanvasLayer/LaunchLine
onready var launch_line_raycast = $Board/LaunchRayCast2D
onready var wait = $Board/LaunchTimer
onready var columns = [
	$Board/Column0,
	$Board/Column1,
	$Board/Column2,
	$Board/Column3,
	$Board/Column4,
	$Board/Column5,
	$Board/Column6
]


# <-------------------------- GAME SAVING FUNCTIONS -------------------------->
func save():
	# This is save_dict is saved in JSON format in our savefile
	var save_dict = {
		"game_mode": $GameModeSelector.selected_game_mode,
		"score": score,
		"past_scores": past_scores,
		"ammo": ammo,
		"launch_ball_position_x": ball.position.x,
		"launch_ball_position_y": ball.position.y,
		"destroyables" : []
	}
	
	for destroyable in live_destroyables:
		var save_destroyable = {
			"name": destroyable.name,
			"column_num" : destroyable.column_num,
			"column_vert_point" : destroyable.column_vert_point,
			"health": null,
			"mega": null,
			"special_mode": null,
			"rotation": destroyable.rotation,
			"laserbeam_direction": null
		}
		if "Brick" in destroyable.name:
			save_destroyable.health = destroyable.health
			save_destroyable.mega = destroyable.mega
		elif "Special" in destroyable.name:
			save_destroyable.special_mode = destroyable.mode
			if destroyable.mode == "laser":
				save_destroyable.laserbeam_direction = destroyable.laserbeam_direction
		save_dict.destroyables.append(save_destroyable)
	
	var save_game = File.new()
	# 'user://' data path varies by OS
	save_game.open("user://savegame.save", File.WRITE)
	
	# Store the save dictionary as a new line in the save file.
	save_game.store_line(to_json(save_dict))
	save_game.close()

func load_game():
	var save_game = File.new()

	# Load the file line by line and process that dictionary 
	# to restore the object it represents.
	save_game.open("user://savegame.save", File.READ)
	while save_game.get_position() < save_game.get_len():
		# Get the saved dictionary from the next line in the save file
		var node_data = parse_json(save_game.get_line())
		
		score = node_data["score"]
		past_scores = node_data["past_scores"]
		ammo = node_data["ammo"]
		ball.position = Vector2(node_data["launch_ball_position_x"], node_data["launch_ball_position_y"])
		
		for destroyable in node_data["destroyables"]:
			new_destroyable(destroyable["column_vert_point"] - 1,
				columns[destroyable["column_num"]],
				destroyable["name"],
				destroyable["health"],
				destroyable["mega"],
				destroyable["special_mode"],
				destroyable["rotation"],
				destroyable["laserbeam_direction"],
				true)
	
	save_game.close()








# <-------------------------- GAME HELPER FUNCTIONS -------------------------->
func launch_line_calc():
	mouse_position = get_global_mouse_position()
	line_direction = first_click_position - mouse_position
	# We can calculate a minimum coordinate set for the launch line to stop us scoring against ourselves
	if line_direction.normalized().x > -0.998 && line_direction.normalized().x < 0.998 && line_direction.normalized().y < 0:
		 reasonable_angle = true
	else:
		reasonable_angle = false

func setup_line():
	launch_line_raycast.position = ball.position
	launch_line_raycast.cast_to = line_direction.normalized()*100000
	launch_line.set_point_position(0, ball.position)
	launch_line.set_point_position(1, launch_line_raycast.get_collision_point())
	if launch_line.modulate.a < 1:
		launch_line.modulate.a += 0.1

func launch_balls(direction = line_direction.normalized(), amount = ammo):
	all_balls_launched = false
	for i in amount:
		var next_ball = ball_scene.instance()
		next_ball.get_node("Light2D").enabled = lighting_enabled
		next_ball.set_color(ball_color)
		add_child(next_ball)
		next_ball.connect("ball_no_contact_timeout", self, "on_ball_no_contact_timeout")
		next_ball.connect("ball_died", self, "on_ball_died")
		next_ball.position = ball.position
		next_ball.launch(direction)
		live_balls.append(next_ball)
		wait.start()
		yield(wait, "timeout")
	all_balls_launched = true

# It is important that you pay attention to the string you feed in for the type.
# A wrong string can trip up the whole game.
func new_destroyable(vert_point, column, type, health = null, mega = null, special_mode = null, rotation = null, laserbeam_direction = null, from_save = false):
	var next_destroyable
	if "Brick" in type:
		if "SlantedBrick" in type:
			next_destroyable = slanted_brick_scene.instance()
			if rotation == null:
				rng.randomize()
				next_destroyable.rotation_degrees = rng.randi_range(0,3) * 90
			else:
				next_destroyable.rotation = rotation
		else:
			next_destroyable = brick_scene.instance()
		
		next_destroyable.mega = mega
		if mega && from_save:
			next_destroyable.health = health / 2
		else:
			next_destroyable.health = health
		next_destroyable.max_possible_health = score + 1
		next_destroyable.connect("brick_killed", self, "on_destroyable_killed")
		
	elif "Special" in type:
		next_destroyable = specials_scene.instance()
		next_destroyable.get_node("Light2D").enabled = lighting_enabled
		if type == "AddBallSpecial" && special_mode == null:
			next_destroyable.mode = "add-ball"
		elif type == "LaserSpecial" && special_mode == null:
			next_destroyable.mode = "laser"
			next_destroyable.laserbeam_direction = laserbeam_direction
		elif "BounceSpecial" in type && special_mode == null:
			next_destroyable.mode = "bounce"
			if type == "BounceSpecial_NC":
				next_destroyable.hit = true
		else:
			next_destroyable.mode = special_mode
		next_destroyable.laserbeam_direction = laserbeam_direction
		next_destroyable.connect("special_area_entered", self, "on_special_area_entered")
		next_destroyable.connect("special_killed", self, "on_destroyable_killed")
	
	next_destroyable.column_num = columns.find(column)
	next_destroyable.column_vert_point = vert_point
	add_child(next_destroyable)
	# We set it at 0 and then add 1 to vert position to get swanky movement down
	next_destroyable.set_position(column.get_point_position(vert_point))
	# Add exception for bounce specials introduced in middle of round
	if type != "BounceSpecial_NC":
		# Set opacity to 0
		next_destroyable.modulate.a = 0
		next_destroyable.column_vert_point += 1
	live_destroyables.append(next_destroyable)

func new_destroyable_line(health, vert_point = 0):
	var free_columns = columns.duplicate()
	var mega = false
	rng.randomize()
	if rng.randi_range(0,9) == 9:
		mega = true
	for column in columns:
		rng.randomize()
		if rng.randi_range(0,2) > 0 && free_columns.size() > 1: 
			free_columns.erase(column)
			if rng.randi_range(0,3) == 3:
				new_destroyable(vert_point, column, "SlantedBrick", health, mega)
			else:
				new_destroyable(vert_point, column, "Brick", health, mega)
	
	rng.randomize()
	var random_free_column = rng.randi_range(0, (free_columns.size() - 1))
	var add_ball_special_column = free_columns[random_free_column]
	new_destroyable(vert_point, add_ball_special_column, "AddBallSpecial")
	free_columns.erase(add_ball_special_column)
	
	rng.randomize()
	if !free_columns.empty() && rng.randi_range(0, 4) == 4:
		random_free_column = rng.randi_range(0, (free_columns.size() - 1))
		var bounce_special_column = free_columns[random_free_column]
		free_columns.erase(bounce_special_column)
		rng.randomize()
		var decider = rng.randi_range(0, 1)
		if decider == 1:
			rng.randomize()
			if rng.randi_range(0,1) == 1:
				# new_destroyable checks if rotation is not null to create vertical laser
				new_destroyable(vert_point, bounce_special_column, "LaserSpecial", null, null, null, null, "vertical")
			else:
				new_destroyable(vert_point, bounce_special_column, "LaserSpecial", null, null, null, null, "horizontal")
		else:
			new_destroyable(vert_point, bounce_special_column, "BounceSpecial")

func update_score_labels():
	ammo_label.text = "x" + String(ammo)
	current_score_label.text = String(score)
	if past_scores.empty() || score > past_scores.max():
		high_score_label.text = String(score)
	else:
		high_score_label.text = String(past_scores.max())

func reset():
	for live_ball in live_balls:
		if is_instance_valid(live_ball):
			live_ball.queue_free()
	for live_destroyable in live_destroyables:
		if is_instance_valid(live_destroyable):
			live_destroyable.queue_free()
	live_balls.clear()
	live_destroyables.clear()
	launched = false
	round_in_progress = false
	round_first_dead_ball_position = null
	score = 0
	ammo = 1
	ball.position = Vector2(360, 1072)
	repositioning_ball = false
	update_score_labels()
	new_destroyable_line(score + 1)
	game_over = false
	save()









# <----------------------------- SIGNAL HANDLERS ----------------------------->
func on_pause_menu_toggled(popup_open):
	get_tree().paused = popup_open

func on_restart_button_clicked():
	reset()

func on_destroyable_killed(destroyable):
	live_destroyables.erase(destroyable)

func on_special_area_entered(special):
	if special.mode == "add-ball":
		ammo += 1
	if special.mode == "laser":
		var laserbeam = laserbeam_scene.instance()
		if special.laserbeam_direction == "vertical":
			laserbeam.position = Vector2(special.global_position.x, 0)
			laserbeam.rotation_degrees = 90
		elif special.laserbeam_direction == "horizontal":
			laserbeam.position = Vector2(0, special.global_position.y)
		add_child(laserbeam)


func on_ball_no_contact_timeout(ball_position, ball_linear_velocity):
	# Create bounce special near live balls when taking too long to move vertically
	var midcolumn_points = Array(columns[3].get_points())
	var distance_to_midcolumn_points = []
	for point in midcolumn_points:
		distance_to_midcolumn_points.append(point.distance_to(ball_position))
	var line_point = distance_to_midcolumn_points.find(distance_to_midcolumn_points.min())
	
	if ball_linear_velocity.y < 0 && distance_to_midcolumn_points.min() < 0:
		line_point -= 1 # Line points go top to bottom
	elif ball_linear_velocity.y > 0 && distance_to_midcolumn_points.min() > 0:
		line_point += 1
	
	var things_at_point = get_world_2d().direct_space_state.intersect_point(columns[3].get_point_position(line_point), 32, [], 1, true, true)
	
	if line_point < 8 && things_at_point.empty():
		new_destroyable(line_point, columns[3], "BounceSpecial_NC")

func on_ball_died(ball_position):
	# Set round_first_dead_ball_position to move our launch position ball there
	if round_first_dead_ball_position == null:
		round_first_dead_ball_position = ball_position

func _on_ControlArea_mouse_entered():
	mouse_in_controlarea = true

func _on_ControlArea_mouse_exited():
	mouse_in_controlarea = false








# <--------------------------- STANDARD GAME FUNCS --------------------------->
func _ready():
	if err == OK:
		ball_scene = load("res://scenes/Balls/" + config.get_value("ball", "ball_file_name"))
		ball = ball_scene.instance()
		ball.marker_ball = true
		lighting_enabled = config.get_value("lighting", "enabled")
		ball_color = config.get_value("ball", "color")
	
	meta_area.connect("pause_menu_toggled", self, "on_pause_menu_toggled")
	meta_area.pause_mode = Node.PAUSE_MODE_PROCESS
	meta_area.connect("restart_button_clicked", self, "on_restart_button_clicked")
	
	launch_line.add_point(Vector2(0,0), 0)
	launch_line.add_point(Vector2(0,0), 1)
	launch_line_raycast.add_exception(ball)
	ball.get_node("Light2D").enabled = lighting_enabled
	ball.set_color(ball_color)
	add_child(ball)
	
	wait.wait_time = 0.1
	
	emit_signal("game_prepped")

func _process(delta):
	if game_over:
		var all_transparent = true
		for live_destroyable in live_destroyables:
			if !is_instance_valid(live_destroyable):
				live_destroyables.erase(live_destroyable)
			elif "Brick" in live_destroyable.name:
				live_destroyable.health = 0
				# Setting health to 0 makes bricks queue_free themselves
			elif live_destroyable.modulate.a > 0:
				live_destroyable.modulate.a -= 0.05
				all_transparent = false
			else:
				live_destroyable.queue_free()
				live_destroyables.erase(live_destroyable)
		
		if all_transparent:
			reset()
	
	else:
		# <------------- UPDATE AMMO LABEL AS BALLS TOUCH BOTTOM ------------->
		ammo_label.text = "x" + String(ammo - live_balls.size())
		
		# <-------------- CALCULATE LAUNCH LINE AND BALL ANGLES -------------->
		launch_line_calc()
		
		# <-------------- SETTING LAUNCH LINE AND LAUNCHING BALL -------------->
		# "click" is defined in input map
		# Allow clicks when mouse is in the game area
		if !mouse_in_controlarea:
			drag_enabled = false
		
		if Input.is_action_just_pressed("click"):
			first_click_position = get_global_mouse_position()
		
		if Input.is_action_pressed("click") && reasonable_angle && drag_enabled:
			setup_line()
			draw_touch_marker = true
		elif !drag_enabled:
			draw_touch_marker = false
			if launch_line.modulate.a > 0:
				launch_line.modulate.a -= 0.1
		elif launch_line.modulate.a > 0:
			launch_line.modulate.a -= 0.1
		
		update() # Updates _draw func
		
		# <---- SMOOTHLY REPOSITION INDICATOR BALL AFTER FIRST BALL RETURN ---->
		if round_first_dead_ball_position != null && ball.position.x != round_first_dead_ball_position.x:
			repositioning_ball = true
			var reposition = ball.position - round_first_dead_ball_position
			# Snap ball into position when they are imperceptibly close
			# Otherwise they will never reach the intended position
			# We also don't want to go to the Y position of the dead ball, only the X
			if round_first_dead_ball_position.distance_to(Vector2(ball.position.x, round_first_dead_ball_position.y)) < 0.5:
				ball.position.x = round_first_dead_ball_position.x
				# So our ball doesn't reposition again if it has reached its position but the round is still on
				round_first_dead_ball_position = null
				repositioning_ball = false
			elif all_balls_launched:
				var reposition_velocity = reposition * 6 * delta
				ball.position.x -= reposition_velocity.x
		
		for live_ball in live_balls:
			if !is_instance_valid(live_ball):
				live_balls.erase(live_ball)

func _draw():
	if drag_enabled && draw_touch_marker:
		# Touch/click marker
		draw_circle(first_click_position, 25, ColorN("white", 0.5))
