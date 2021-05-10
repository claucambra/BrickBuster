extends Node2D

onready var game_control = get_tree().get_root().get_node("MainGame")


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var launch_cooldown_timer = Timer.new()
var launch_cooling_down = true
var score_increase_timer = Timer.new()
var add_ball_enabled = true
var countdown_label = Label.new()
var blocks_moving = false
var top_row_area = Area2D.new()
var top_row_area_collision_shape = CollisionShape2D.new()

func new_destroyable_line(health, vert_point = 0):
	var rng = game_control.rng
	var free_columns = game_control.columns.duplicate()
	var mega = false
	rng.randomize()
	if rng.randi_range(0,7) == 7:
		mega = true
	for column in game_control.columns:
		rng.randomize()
		if rng.randi_range(0,2) > 0 && free_columns.size() > 1: 
			free_columns.erase(column)
			if rng.randi_range(0,3) == 3:
				game_control.new_destroyable(vert_point, column, "SlantedBrick", health, mega)
			else:
				game_control.new_destroyable(vert_point, column, "Brick", health, mega)
	
	rng.randomize()
	var random_free_column = rng.randi_range(0, (free_columns.size() - 1))
	var add_ball_special_column = free_columns[random_free_column]
	rng.randomize()
	if rng.randi_range(0,1) == 1:
		game_control.new_destroyable(vert_point, add_ball_special_column, "AddBallSpecial")
	free_columns.erase(add_ball_special_column)
	
	rng.randomize()
	if !free_columns.empty() && rng.randi_range(0, 2) == 2:
		random_free_column = rng.randi_range(0, (free_columns.size() - 1))
		var bounce_special_column = free_columns[random_free_column]
		free_columns.erase(bounce_special_column)
		rng.randomize()
		var decider = rng.randi_range(0, 1)
		if decider == 1:
			rng.randomize()
			if rng.randi_range(0,1) == 1:
				# new_destroyable checks if rotation is not null to create vertical laser
				game_control.new_destroyable(vert_point, bounce_special_column, "LaserSpecial", null, null, null, null, "vertical")
			else:
				game_control.new_destroyable(vert_point, bounce_special_column, "LaserSpecial", null, null, null, null, "horizontal")
		else:
			game_control.new_destroyable(vert_point, bounce_special_column, "BounceSpecial")

func on_launch_cooldown_timer_timeout():
	launch_cooling_down = false
	blocks_moving = true
	score_increase_timer.start()

func on_score_increase_timer_timeout():
	add_ball_enabled = true
	game_control.score += 1
	game_control.update_score_labels()
	score_increase_timer.start()
	game_control.save()

# Called when the node enters the scene tree for the first time.
func _ready():
	game_control.ball.get_node("CollisionThing2D").disabled = true
	
	launch_cooldown_timer.connect("timeout", self, "on_launch_cooldown_timer_timeout")
	launch_cooldown_timer.wait_time = 3
	launch_cooldown_timer.autostart = true
	launch_cooldown_timer.one_shot = true
	add_child(launch_cooldown_timer)
	
	score_increase_timer.connect("timeout", self, "on_score_increase_timer_timeout")
	score_increase_timer.wait_time = 5
	add_child(score_increase_timer)
	
	countdown_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	countdown_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	countdown_label.anchor_left = 0.5
	countdown_label.anchor_top = 0.5
	$ControlArea.add_child(countdown_label)
	
	top_row_area.monitoring = true
	top_row_area.add_child(top_row_area_collision_shape)
	top_row_area_collision_shape.shape = RectangleShape2D.new()
	var tracs_extents = (game_control.columns[6].get_point_position(1) - game_control.columns[0].get_point_position(0)) / 2
	top_row_area_collision_shape.shape.set_extents(Vector2(tracs_extents.x, tracs_extents.y))
	add_child(top_row_area)
	top_row_area.position =  game_control.columns[0].get_point_position(0)
	
	var save_game = File.new()
	if not save_game.file_exists("user://savegame.save"):
		game_control.rng.randomize()
		game_control.new_destroyable_line(game_control.score + 1)
	else:
		game_control.load_game()
		if game_control.live_destroyables.empty():
			# Caused by 'new game' from main menu, impossible in normal game flow.
			new_destroyable_line(game_control.score + 1)
	game_control.update_score_labels()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):

	if !game_control.game_over:
		if blocks_moving:
			for live_destroyable in game_control.get_children():
				if "Brick" in live_destroyable.name or "Special" in live_destroyable.name:
					if live_destroyable.position.y >= game_control.columns[6].get_point_position(7).y:
						if "Brick" in live_destroyable.name:
							game_control.game_over = true
						else:
							live_destroyable.kill()
					else: 
						live_destroyable.position.y += 1
		
		var row_0_free = true
		for thing in top_row_area.get_overlapping_bodies():
			if "Brick" in thing.name || "Special" in thing.name:
				row_0_free = false
		
		if row_0_free:
			new_destroyable_line(game_control.score + 1)
		
		if !launch_cooling_down && game_control.live_balls.size() != game_control.ammo:
			game_control.drag_enabled = true
			countdown_label.visible = false
			if Input.is_action_just_released("click") && game_control.reasonable_angle:
				game_control.launch_balls(game_control.line_direction.normalized(), game_control.ammo - game_control.live_balls.size())
		else:
			game_control.drag_enabled = false
			if launch_cooldown_timer.time_left > 0:
				countdown_label.text = String(launch_cooldown_timer.time_left)
				countdown_label.visible = true
			else:
				countdown_label.visible = false
