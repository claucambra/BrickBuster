extends Node2D

var game_mode_details = {
	"name": "standard",
	"display_name": "Standard",
	"description": "Destroy the bricks in a round-based race to the high score!"
}

var repositioning_bricks = false
var ball_repositioned_this_round = false
var round_first_dead_ball_position = null

onready var global = get_node("/root/Global")
onready var game_control = get_tree().get_root().get_node("MainGame")

func new_destroyable_line(health, vert_point = 0):
	var rng = global.rng
	var free_columns = game_control.columns.duplicate()
	var mega = false
	rng.randomize()
	
	if int(game_control.score) % 10 == 0 && game_control.score != 0:
		mega = true
	else:
		mega = false
		
	game_control.add_bricks_on_line(free_columns, health, vert_point, mega)
	
	rng.randomize()
	var random_free_column_index = rng.randi_range(0, (free_columns.size() - 1))
	var add_ball_special_column = free_columns[random_free_column_index]
	game_control.new_destroyable(vert_point, add_ball_special_column, "AddBallSpecial")
	free_columns.erase(add_ball_special_column)
	
	rng.randomize()
	if !free_columns.empty() && rng.randi_range(0, 4) == 4:
		game_control.add_special_on_line(free_columns, vert_point)

func round_over_checks():
	for live_destroyable in game_control.get_children():
		if "Brick" in live_destroyable.name or "Special" in live_destroyable.name:
			live_destroyable.column_vert_point += 1
			if "Special" in live_destroyable.name && (live_destroyable.hit == true || live_destroyable.column_vert_point == 8):
				live_destroyable.kill()
			if "Brick" in live_destroyable.name:
				# Game over once blocks reach bottom of screen
				if live_destroyable.column_vert_point == 8:
					game_control.game_over = true
				else:
					live_destroyable.max_possible_health += 1

func destroyable_correct_position_check(destroyable):
	var destination = game_control.columns[destroyable.column_num].get_point_position(destroyable.column_vert_point)
	if destroyable.position != destination:
		return false
	else:
		return true

func destroyable_position_check_and_move(destroyable, delta):
	if !destroyable_correct_position_check(destroyable):
		repositioning_bricks = true
		var destination = game_control.columns[destroyable.column_num].get_point_position(destroyable.column_vert_point)
		var reposition = destroyable.position - destination
		# Snap blocks into position when they are imperceptibly close
		# Otherwise they will never reach the intended position
		if reposition.y > -0.5:
			destroyable.position = destination
			return 0
		else:
			var reposition_velocity = reposition * 6 * delta
			destroyable.position -= reposition_velocity
			return 1
	else:
		return 0

func smoothly_reposition_destroyables(delta):
	# Here we deal with the smooth opacity change and repositioning of blocks
	var num_incorrect_brick_position = 0
	for live_destroyable in game_control.get_children():
		# If destroyable not fully opaque
		if "Brick" in live_destroyable.name or "Special" in live_destroyable.name:
			if live_destroyable.modulate.a < 1:
				live_destroyable.modulate.a += 0.05
			# If destroyable not at point it's supposed to be
			num_incorrect_brick_position += destroyable_position_check_and_move(live_destroyable, delta)
	if num_incorrect_brick_position == 0:
		game_control.save()
		repositioning_bricks = false
	else:
		repositioning_bricks = true


func on_ball_died(dead_ball):
	# Set round_first_dead_ball_position to move our launch position ball there
	if round_first_dead_ball_position == null && !ball_repositioned_this_round:
		round_first_dead_ball_position = dead_ball.position

func on_ball_no_contact_timeout(ball_position, ball_linear_velocity):
	# Create bounce special near live balls when taking too long to move vertically
	var midcolumn_points = Array(game_control.columns[3].get_points())
	var distance_to_midcolumn_points = []
	for point in midcolumn_points:
		distance_to_midcolumn_points.append(point.distance_to(ball_position))
	var line_point = distance_to_midcolumn_points.find(distance_to_midcolumn_points.min())
	
	if ball_linear_velocity.y < 0 && distance_to_midcolumn_points.min() < 0:
		line_point -= 1 # Line points go top to bottom
	elif ball_linear_velocity.y > 0 && distance_to_midcolumn_points.min() > 0:
		line_point += 1
	
	var things_at_point = get_world_2d().direct_space_state.intersect_point(game_control.columns[3].get_point_position(line_point), 32, [], 1, true, true)
	
	if line_point < 8 && things_at_point.empty():
		game_control.new_destroyable(line_point, game_control.columns[3], "BounceSpecial_NC")

func on_reset_triggered():
	ball_repositioned_this_round = false
	round_first_dead_ball_position = null
	new_destroyable_line(game_control.score + 1)

# <--------------------------- STANDARD GAME FUNCS --------------------------->
# Called when the node enters the scene tree for the first time.
func _ready():
	game_control.connect("ball_no_contact_timeout", self, "on_ball_no_contact_timeout")
	game_control.connect("reset_triggered", self, "on_reset_triggered")
	game_control.connect("ball_died", self, "on_ball_died")
	
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
func _process(delta):
	if !game_control.game_over:
		# Before allowing any input we need to make sure everything on the board
		# is prepped.
		# <---------------------- ROUND PROGRESS CHECKS ---------------------->
		if round_first_dead_ball_position != null && game_control.all_balls_launched:
			game_control.smoothly_reposition_ball(delta, game_control.ball, round_first_dead_ball_position)
			if game_control.ball.position.x == round_first_dead_ball_position.x:
				round_first_dead_ball_position = null
				ball_repositioned_this_round = true
		if !game_control.live_balls.empty():
			game_control.round_in_progress = true
		# <--------------------- END OF ROUND PROCESSING --------------------->
		elif game_control.launched:
			# Here we deal with the end-of-round process
			game_control.launched = false
			game_control.round_in_progress = false
			ball_repositioned_this_round = false
			round_over_checks()
			if !game_control.game_over:
				game_control.score += 1
				game_control.update_score_labels()
				new_destroyable_line(game_control.score + 1)
		else:
			smoothly_reposition_destroyables(delta)
		
		# Launch handling
		if !game_control.repositioning_ball && !repositioning_bricks && !game_control.round_in_progress:
			game_control.drag_enabled = true
		else:
			game_control.drag_enabled = false
		
		if Input.is_action_just_released("click"):
			if game_control.drag_enabled && game_control.reasonable_angle: 
				game_control.launch_balls()
				game_control.launched = true
