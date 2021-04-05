extends Node2D

# <---------------------------- MEMBER VARIABLES ---------------------------->
var game_over = false
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
var past_scores = []
var ammo = 1
var first_click_position = Vector2(0,0)
var rng = RandomNumberGenerator.new()
var lighting_enabled = true

onready var meta_area = $CanvasLayer/MetaArea
onready var current_score_label = $CanvasLayer/MetaArea/MarginContainer/HBoxContainer/VBoxContainer/CurrentScoreLabel
onready var high_score_label = $CanvasLayer/MetaArea/MarginContainer/HBoxContainer/VBoxContainer/HighScoreLabel
onready var ammo_label = $CanvasLayer/BottomPanel/CenterContainer/AmmoLabel
onready var ball_scene = load("res://scenes/Ball.tscn")
onready var brick_scene = load("res://scenes/Brick.tscn")
onready var slanted_brick_scene = load("res://scenes/SlantedBrick.tscn")
onready var specials_scene = load("res://scenes/Specials.tscn")
onready var laserbeam_scene = load("res://scenes/LaserBeam.tscn")
# We use a ball instance to mark where our balls will launch from.
# This ball remains throughout the game, 
# moving position to where the last ball of the last round fell.
onready var ball = ball_scene.instance()
onready var launch_line = $CanvasLayer/LaunchLine
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
func launch_balls(direction, amount):
	all_balls_launched = false
	var num_balls_left = ammo
	for i in amount:
		var next_ball = ball_scene.instance()
		next_ball.get_node("Light2D").enabled = lighting_enabled
		add_child(next_ball)
		next_ball.connect("ball_no_contact_timeout", self, "on_ball_no_contact_timeout")
		next_ball.connect("ball_died", self, "on_ball_died")
		next_ball.position = ball.position
		next_ball.launch(direction)
		live_balls.append(next_ball)
		num_balls_left -= 1
		ammo_label.text = "x" + String(num_balls_left)
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
		high_score_label.text = "High Score: " + String(score)
	else:
		high_score_label.text = "High Score: " + String(past_scores.max())

func reset(from_main_menu = false):
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
	self.update_score_labels()
	self.new_destroyable_line(score + 1)
	game_over = false
	self.save()








# <----------------------------- SIGNAL HANDLERS ----------------------------->
func on_pause_menu_toggled():
	paused = !paused
	get_tree().paused = paused

func on_restart_button_clicked():
	self.reset()

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
	
	var things_at_point = get_world_2d().direct_space_state.intersect_point(columns[3].get_point_position(line_point), 32, [], 1, true, true)
	if ball_linear_velocity.y < 0 && distance_to_midcolumn_points.min() < 0:
		line_point -= 1 # Line points go top to bottom
	elif ball_linear_velocity.y > 0 && distance_to_midcolumn_points.min() > 0:
		line_point += 1
	if line_point < 8 && things_at_point.empty():
		new_destroyable(line_point, columns[3], "BounceSpecial_NC")

func on_ball_died(ball_position_x):
	# Set round_first_dead_ball_position to move our launch position ball there
	if round_first_dead_ball_position == null:
		round_first_dead_ball_position = ball_position_x

func _on_ControlArea_mouse_entered():
	mouse_in_controlarea = true

func _on_ControlArea_mouse_exited():
	mouse_in_controlarea = false








# <--------------------------- STANDARD GAME FUNCS --------------------------->
# Called when the node enters the scene tree for the first time.
func _ready():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		lighting_enabled = config.get_value("lighting", "enabled")
	
	meta_area.connect("pause_menu_toggled", self, "on_pause_menu_toggled")
	meta_area.pause_mode = Node.PAUSE_MODE_PROCESS
	meta_area.connect("restart_button_clicked", self, "on_restart_button_clicked")
	
	launch_line.add_point(Vector2(0,0), 0)
	launch_line.add_point(Vector2(0,0), 1)
	ball.get_node("Light2D").enabled = lighting_enabled
	add_child(ball)
	
	wait.wait_time = 0.1
	
	var save_game = File.new()
	if not save_game.file_exists("user://savegame.save"):
		rng.randomize()
		self.new_destroyable_line(score + 1)
	else:
		self.load_game()
		if live_destroyables.empty():
			# Caused by 'new game' from main menu, impossible in normal game flow.
			self.new_destroyable_line(score + 1)
	
	self.update_score_labels()

# Called every frame. 'delta' is the elapsed time since the previous frame.
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
			self.reset()
	
	else:
		# <-------------- CALCULATE LAUNCH LINE AND BALL ANGLES -------------->
		var mouse_position = get_global_mouse_position()
		var line_direction = first_click_position - mouse_position
		# We can calculate a minimum coordinate set for the launch line to stop us scoring against ourselves
		var reasonable_angle
		if line_direction.normalized().x > -0.998 && line_direction.normalized().x < 0.998 && line_direction.normalized().y < 0:
			 reasonable_angle = true
		else:
			reasonable_angle = false
		
		# <-------------- SETTING LAUNCH LINE AND LAUNCHING BALL -------------->
		# "click" is defined in input map
		# Allow clicks when mouse is in the game area and round not in progress
		if Input.is_action_just_pressed("click") && mouse_in_controlarea && !round_in_progress:
			first_click_position = get_global_mouse_position()
			drag_enabled = true
		
		# Line drawing and touch place responsibilities
		update() # Updates _draw func
		if (!drag_enabled || !reasonable_angle) && launch_line.modulate.a > 0:
			launch_line.modulate.a -= 0.1
		if drag_enabled && !round_in_progress && reasonable_angle:
			$LaunchRayCast2D.position = ball.position
			$LaunchRayCast2D.cast_to = line_direction.normalized()*100000
			launch_line.set_point_position(0, ball.position)
			launch_line.set_point_position(1, $LaunchRayCast2D.get_collision_point())
			if launch_line.modulate.a < 1:
				launch_line.modulate.a += 0.1
		
		# Launch handling
		if Input.is_action_just_released("click"):
			if !round_in_progress && drag_enabled && reasonable_angle: 
				self.launch_balls(line_direction.normalized(), ammo)
				launched = true
			drag_enabled = false
		
		# <---- SMOOTHLY REPOSITION INDICATOR BALL AFTER FIRST BALL RETURN ---->
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
		
		# <---------------------- ROUND PROGRESS CHECKS ---------------------->
		for live_ball in live_balls:
			if !is_instance_valid(live_ball):
				live_balls.erase(live_ball)
		
		var copy_live_destroyables = live_destroyables.duplicate()
		# We need a copy of our live destroyables to not bungle things up
		if !live_balls.empty():
			round_in_progress = true
		# <--------------------- END OF ROUND PROCESSING --------------------->
		elif launched:
			# Here we deal with the end-of-round process
			launched = false
			round_in_progress = false
			for live_destroyable in copy_live_destroyables:
				if !is_instance_valid(live_destroyable):
					live_destroyables.erase(live_destroyable)
				else:
					live_destroyable.column_vert_point += 1
					if "Special" in live_destroyable.name && (live_destroyable.hit == true || live_destroyable.column_vert_point == 8):
						live_destroyable.queue_free()
						live_destroyables.erase(live_destroyable)
					if "Brick" in live_destroyable.name:
						# Game over once blocks reach bottom of screen
						if live_destroyable.column_vert_point == 8:
							game_over = true
						else:
							live_destroyable.max_possible_health += 1
			if !game_over:
				score += 1
				self.update_score_labels()
				self.new_destroyable_line(score + 1)
			else:
				past_scores.append(score)
		# <------------------------ SET UP NEXT ROUND ------------------------>
		elif !game_over:
			# Here we deal with the smooth opacity change and repositioning of blocks
			var num_incorrect_brick_position = 0
			for live_destroyable in copy_live_destroyables:
				# If destroyable not fully opaque
				if live_destroyable.modulate.a < 1:
					live_destroyable.modulate.a += 0.05
				# If destroyable not at point it's supposed to be
				var destination = columns[live_destroyable.column_num].get_point_position(live_destroyable.column_vert_point)
				if live_destroyable.position != destination:
					num_incorrect_brick_position += 1
					var reposition = live_destroyable.position - destination
					# Snap blocks into position when they are imperceptibly close
					# Otherwise they will never reach the intended position
					if reposition.y > -0.5:
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
		draw_circle(first_click_position, 25, ColorN("white", 0.5))
