extends Node2D

# <-------------------------- MEMBER VARIABLES -------------------------->
var paused = false
# These variables are used to keep track of what stage of the round we are in
# This is used to decide input state and acceptance
var drag_enabled = false
var mouse_in_controlarea = false
# launched is used to differentiate between states when there are no live balls
# i.e. idling vs just after all balls have returned to bottom of screen
var launched = false
var all_balls_launched = false
var round_in_progress = false
var live_balls = []
var live_destroyables = []
var round_first_dead_ball_position = null
var score = 0
var ammo = 1
var first_click_position = Vector2(0,0)
var rng = RandomNumberGenerator.new()

onready var score_label = $MetaArea/MarginContainer/HBoxContainer/ScoreLabel
onready var ball_scene = load("res://scenes/Ball.tscn")
onready var brick_scene = load("res://scenes/Brick.tscn")
onready var slanted_brick_scene = load("res://scenes/SlantedBrick.tscn")
onready var specials_scene = load("res://scenes/Specials.tscn")
# We use a ball instance to mark where our balls will launch from.
# This ball remains throughout the game, 
# moving position to where the last ball of the last round fell.
onready var ball = ball_scene.instance()
onready var line = $LaunchLine
onready var wait = $LaunchTimer
onready var columns = [
	$Column0,
	$Column1,
	$Column2,
	$Column3,
	$Column4,
	$Column5,
	$Column6
]


# <-------------------------- GAME SAVING FUNCTIONS -------------------------->
func save():
	# This is save_dict is saved in JSON format in our savefile
	var save_dict = {
		"score": score,
		"ammo": ammo,
		"launch_ball_position_x": ball.position.x,
		"launch_ball_position_y": ball.position.y,
		"destroyables" : []
	}
	
	for destroyable in live_destroyables:
		var save_destroyable = {
			"name": destroyable.name,
			"hor_position" : destroyable.hor_position,
			"current_vert_position" : destroyable.current_vert_position,
			"health": null,
			"special_mode": null,
			"rotation": destroyable.rotation
		}
		if "Brick" in destroyable.name:
			save_destroyable.health = destroyable.health
		elif "Special" in destroyable.name:
			save_destroyable.special_mode = destroyable.mode
		save_dict.destroyables.append(save_destroyable)
	
	return save_dict

func save_game():
	var save_game = File.new()
	# 'user://' data path varies by OS
	save_game.open("user://savegame.save", File.WRITE)
	var data = self.save()
	
	# Store the save dictionary as a new line in the save file.
	save_game.store_line(to_json(data))
	save_game.close()

func load_game():
	var save_game = File.new()

	# Load the file line by line and process that dictionary to restore the object it represents.
	save_game.open("user://savegame.save", File.READ)
	while save_game.get_position() < save_game.get_len():
		# Get the saved dictionary from the next line in the save file
		var node_data = parse_json(save_game.get_line())
		
		self.score = node_data["score"]
		self.ammo = node_data["ammo"]
		ball.position = Vector2(node_data["launch_ball_position_x"], node_data["launch_ball_position_y"])
		
		for destroyable in node_data["destroyables"]:
			new_destroyable(destroyable["current_vert_position"] - 1,
				columns[destroyable["hor_position"]],
				destroyable["name"],
				destroyable["health"],
				destroyable["special_mode"],
				destroyable["rotation"])
	
	save_game.close()


# <-------------------------- GAME HELPER FUNCTIONS -------------------------->
func launch_balls(direction, amount):
	all_balls_launched = false
	for i in amount:
		var next_ball = ball_scene.instance()
		add_child(next_ball)
		next_ball.connect("ball_no_contact_timeout", self, "on_ball_no_contact_timeout")
		next_ball.connect("ball_died", self, "on_ball_died")
		next_ball.position = ball.position
		next_ball.launch(direction)
		live_balls.append(next_ball)
		wait.start()
		yield(wait, "timeout")
	all_balls_launched = true

# It is important that you pay attention to the string you feed in for the parameter.
# A wrong string can trip up the whole game.
func new_destroyable(vert_position, column, type, health = null, special_mode = null, rotation = null):
	print(vert_position, column, type, health, special_mode, rotation)
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
		next_destroyable.health = health
		next_destroyable.max_possible_health = score + 1
	elif "Special" in type:
		next_destroyable = specials_scene.instance()
		if type == "AddBallSpecial" && special_mode == null:
			next_destroyable.mode = "add-ball"
		elif type == "BounceSpecial" && special_mode == null:
			next_destroyable.mode = "bounce"
		else:
			next_destroyable.mode = special_mode
		next_destroyable.connect("special_area_entered", self, "on_special_area_entered")
	
	next_destroyable.hor_position = columns.find(column)
	next_destroyable.current_vert_position = vert_position
	add_child(next_destroyable)
	# We set it at 0 and then add 1 to vert position to get swanky movement down
	next_destroyable.set_position(column.get_point_position(vert_position))
	next_destroyable.current_vert_position += 1
	live_destroyables.append(next_destroyable)

func new_destroyable_line(health, vert_position = 0):
	var free_columns = columns.duplicate()
	for column in columns:
		rng.randomize()
		if rng.randi_range(0,2) > 0 && free_columns.size() > 1: 
			free_columns.erase(column)
			if rng.randi_range(0,3) == 3:
				new_destroyable(vert_position, column, "SlantedBrick", health)
			else:
				new_destroyable(vert_position, column, "Brick", health)
	
	rng.randomize()
	var random_free_column = rng.randi_range(0, (free_columns.size() - 1))
	var column_for_add_ball_special = free_columns[random_free_column]
	new_destroyable(vert_position, column_for_add_ball_special, "AddBallSpecial")
	free_columns.erase(column_for_add_ball_special)
	
	rng.randomize()
	if !free_columns.empty() && rng.randi_range(0, 3) == 3:
		random_free_column = rng.randi_range(0, (free_columns.size() - 1))
		var column_for_bounce_special = free_columns[random_free_column]
		new_destroyable(vert_position, column_for_bounce_special, "BounceSpecial")
		free_columns.erase(column_for_bounce_special)

func reset():
	for ball in live_balls:
		if is_instance_valid(ball):
			ball.queue_free()
	for destroyable in live_destroyables:
		if is_instance_valid(destroyable):
			destroyable.queue_free()
	live_balls.clear()
	live_destroyables.clear()
	launched = false
	round_in_progress = false
	round_first_dead_ball_position = null
	score = 0
	ammo = 1
	self.new_destroyable_line(score + 1)
	self.save()


# <-------------------------- SIGNAL HANDLERS -------------------------->
func on_pause_menu_toggled():
	paused = !paused
	get_tree().paused = paused

func on_restart_button_clicked():
	self.reset()

func on_special_area_entered(type):
	if type == "add-ball":
		ammo += 1

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
	if line_point < 8:
		new_destroyable(line_point, columns[3], "BounceSpecial")

func on_ball_died(ball_position_x):
	# Set round_first_dead_ball_position to move our launch position ball there
	if round_first_dead_ball_position == null:
		round_first_dead_ball_position = ball_position_x

func _on_ControlArea_mouse_entered():
	mouse_in_controlarea = true

func _on_ControlArea_mouse_exited():
	mouse_in_controlarea = false


# <-------------------------- STANDARD GAME FUNCTIONS -------------------------->
# Called when the node enters the scene tree for the first time.
func _ready():
	$MetaArea.connect("pause_menu_toggled", self, "on_pause_menu_toggled")
	$MetaArea.pause_mode = Node.PAUSE_MODE_PROCESS
	$MetaArea.connect("restart_button_clicked", self, "on_restart_button_clicked")
	line.add_point(Vector2(0,0), 0)
	line.add_point(Vector2(0,0), 1)
	add_child(ball)
	wait.wait_time = 0.1
	
	var save_game = File.new()
	if not save_game.file_exists("user://savegame.save"):
		rng.randomize()
		self.new_destroyable_line(score + 1)
	else:
		self.load_game()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	score_label.text = String(score)
	
	var ball_center = ball.position
	var mouse_position = get_global_mouse_position()
	var line_direction = first_click_position - mouse_position
	
	# "click" is defined in input map
	# Allow clicks when mouse is in the game area and round not in progress
	if Input.is_action_just_pressed("click") && mouse_in_controlarea && !round_in_progress:
		first_click_position = get_global_mouse_position()
		drag_enabled = true
	
	# Line drawing and touch place responsibilities
	update() # Updates _draw func
	line.visible = false
	if drag_enabled && !round_in_progress:
		line.visible = true
		line.set_point_position(0, ball_center)
		line.set_point_position(1, line_direction.normalized()*100000)
	
	# Launch handling
	if Input.is_action_just_released("click") && !round_in_progress && drag_enabled: 
		drag_enabled = false
		self.launch_balls(line_direction.normalized(), ammo)
		launched = true
	
	if ball.position == round_first_dead_ball_position && !round_in_progress:
		# So our ball doesn't reposition again if it has reached its position but the round is still on
		round_first_dead_ball_position = null
	elif round_first_dead_ball_position != null && ball.position != round_first_dead_ball_position:
		drag_enabled = false
		var reposition = ball.position - round_first_dead_ball_position
		# Snap ball into position when they are imperceptibly close
		# Otherwise they will never reach the intended position
		if round_first_dead_ball_position.distance_to(ball.position) < 0.5:
			ball.position = round_first_dead_ball_position
		elif all_balls_launched:
			var reposition_velocity = reposition * 6 * delta
			ball.position -= reposition_velocity
	
	# Round progress checking section
	for live_ball in live_balls:
		if !is_instance_valid(live_ball):
			live_balls.erase(live_ball)
	
	var copy_live_destroyables = live_destroyables.duplicate()
	# We need a copy of our live destroyables to not bungle things up
	if !live_balls.empty():
		round_in_progress = true
	elif launched:
		# Here we deal with the end-of-round process
		score += 1
		launched = false
		round_in_progress = false
		var game_over = false
		for live_destroyable in copy_live_destroyables:
			if !is_instance_valid(live_destroyable):
				live_destroyables.erase(live_destroyable)
			else:
				live_destroyable.current_vert_position += 1
				if "Special" in live_destroyable.name && (live_destroyable.hit == true || live_destroyable.current_vert_position == 8):
					live_destroyable.queue_free()
					live_destroyables.erase(live_destroyable)
				if "Brick" in live_destroyable.name:
					if live_destroyable.current_vert_position == 8:
						game_over = true
						self.reset()
					else:
						live_destroyable.max_possible_health += 1
		if !game_over:
			self.new_destroyable_line(score + 1)
	else:
		# Here we deal with the smooth repositioning of blocks
		var num_incorrect_brick_position = 0
		for live_destroyable in copy_live_destroyables:
			var destination = columns[live_destroyable.hor_position].get_point_position(live_destroyable.current_vert_position)
			if live_destroyable.position != destination:
				num_incorrect_brick_position += 1
				var reposition = live_destroyable.position - destination
				# Snap blocks into position when they are imperceptibly close
				# Otherwise they will never reach the intended position
				if reposition.y > -2:
					live_destroyable.position = destination
				else:
					var reposition_velocity = reposition * 6 * delta
					live_destroyable.position -= reposition_velocity
		if num_incorrect_brick_position == 0:
			self.save_game()
			round_in_progress = false
		else:
			round_in_progress= true

func _draw():
	if drag_enabled && !round_in_progress:
		# Touch/click marker
		draw_circle(first_click_position, 25, ColorN("black", 0.5))
