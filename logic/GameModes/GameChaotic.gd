extends Node2D

onready var global = get_node("/root/Global")
onready var game_control = get_tree().get_root().get_node("MainGame")


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var game_mode_details = {
	"name": "chaotic",
	"display_name": "Chaotic",
	"description": "Fight off the endless march of the bricks for as long as you can!"
}

var launch_cooldown_timer = Timer.new()
var launch_cooling_down = true
var score_increase_timer = Timer.new()
var add_ball_enabled = true
var countdown_label = Label.new()
var blocks_moving = false
var top_row_area = Area2D.new()
var top_row_area_collision_shape = CollisionShape2D.new()

var mega_added_this_score = false

func new_destroyable_line(health, vert_point = 0):
	var rng = global.rng
	var free_columns = game_control.columns.duplicate()
	var mega = false
	rng.randomize()
	
	# Make sure only one mega row each time score is a multiple of 5
	if int(game_control.score) % 5 == 0 && !mega_added_this_score && game_control.score != 0:
		mega = true
		mega_added_this_score = true
	else:
		mega = false
		mega_added_this_score = false
	
	game_control.add_bricks_on_line(free_columns, health, vert_point, mega)
	
	rng.randomize()
	var random_free_column = rng.randi_range(0, (free_columns.size() - 1))
	var add_ball_special_column = free_columns[random_free_column]
	var actual_column_index = game_control.columns.find(add_ball_special_column)
	
	rng.randomize()
	if rng.randi_range(0,1) == 1:
		var new_addball_request = game_control.SpecialRequest.new()
		new_addball_request.column_vert_point = vert_point
		new_addball_request.column_num = actual_column_index
		new_addball_request.mode = "add-ball"
		
		game_control.new_destroyable(new_addball_request)
		
	free_columns.erase(add_ball_special_column)
	
	rng.randomize()
	if !free_columns.empty() && rng.randi_range(0, 2) == 2:
		game_control.add_special_on_line(free_columns, vert_point)

func on_launch_cooldown_timer_timeout():
	launch_cooling_down = false
	blocks_moving = true
	score_increase_timer.start()

func on_score_increase_timer_timeout():
	add_ball_enabled = true
	game_control.score += 1
	game_control.update_score_labels()
	score_increase_timer.start()
	if !game_control.game_over:
		game_control.save()
	for live_destroyable in game_control.get_children():
		if "Brick" in live_destroyable.name:
			live_destroyable.max_possible_health = game_control.score + 1

# Called when the node enters the scene tree for the first time.
func _ready():
	game_control.ball.get_node("CollisionThing2D").disabled = true
	
	launch_cooldown_timer.connect("timeout", self, "on_launch_cooldown_timer_timeout")
	launch_cooldown_timer.wait_time = 3.4 # When rounded still says 3
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
	countdown_label.set("custom_fonts/font", global.noto_font_bold_title)
	$CanvasLayer.add_child(countdown_label)
	$CanvasLayer.move_child(countdown_label, 0)
	
	top_row_area.monitoring = true
	top_row_area.add_child(top_row_area_collision_shape)
	top_row_area_collision_shape.shape = RectangleShape2D.new()
	# Collision areas are special snowflakes and take sizing from the center point.
	# This includes positioning. Why, I have no clue.
	var tracs_extents = (game_control.columns[6].get_point_position(1) - game_control.columns[0].get_point_position(0)) / 2
	var tracs_position = Vector2(game_control.columns[3].get_point_position(0).x, game_control.columns[0].get_point_position(0).y)
	top_row_area_collision_shape.shape.set_extents(Vector2(tracs_extents.x, tracs_extents.y))
	add_child(top_row_area)
	top_row_area.position = tracs_position
	
	if !global.save_game_data:
		game_control.rng.randomize()
		game_control.new_destroyable_line(game_control.score + 1)
	else:
		game_control.load_game()
		if game_control.live_destroyables.empty():
			# Caused by 'new game' from main menu, impossible in normal game flow.
			new_destroyable_line(game_control.score + 1)
	game_control.update_score_labels()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if game_control.game_over:
		score_increase_timer.stop()
	else:
		if score_increase_timer.is_stopped():
			score_increase_timer.start()
		
		if blocks_moving:
			for live_destroyable in game_control.get_children():
				if "Brick" in live_destroyable.name or "Special" in live_destroyable.name:
					if live_destroyable.position.y >= game_control.columns[6].get_point_position(7).y:
						if "Brick" in live_destroyable.name:
							game_control.game_over = true
						else:
							live_destroyable.kill()
					else: 
						live_destroyable.position.y += 0.75
		
		var row_0_free = true
		for thing in top_row_area.get_overlapping_bodies():
			if "Brick" in thing.name || "Special" in thing.name:
				row_0_free = false
		
		if row_0_free:
			new_destroyable_line(game_control.score + 1)
		
		if !launch_cooling_down && game_control.live_balls.size() != game_control.ammo:
			game_control.drag_enabled = true
			if Input.is_action_just_released("click") && game_control.reasonable_angle:
				game_control.launch_balls(game_control.line_direction.normalized(), game_control.ammo - game_control.live_balls.size())
		else:
			game_control.drag_enabled = false
			if launch_cooldown_timer.time_left >= 0.4: # Checking at 0 creates problems...
				countdown_label.text = str(round(launch_cooldown_timer.time_left))
				countdown_label.modulate.a = 1
				countdown_label.visible = true
			elif countdown_label.modulate.a > 0:
				countdown_label.modulate.a -= 0.05
			else:
				countdown_label.visible = false
