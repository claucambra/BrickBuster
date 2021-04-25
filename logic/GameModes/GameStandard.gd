extends Node2D

var repositioning_bricks = false

onready var game_control = get_tree().get_root().get_node("MainGame")

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

# <--------------------------- STANDARD GAME FUNCS --------------------------->
# Called when the node enters the scene tree for the first time.
func _ready():
	var save_game = File.new()
	if not save_game.file_exists("user://savegame.save"):
		game_control.rng.randomize()
		game_control.new_destroyable_line(game_control.score + 1)
	else:
		game_control.load_game()
		if game_control.live_destroyables.empty():
			# Caused by 'new game' from main menu, impossible in normal game flow.
			game_control.new_destroyable_line(game_control.score + 1)
	
	game_control.update_score_labels()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !game_control.game_over:
		# Before allowing any input we need to make sure everything on the board
		# is prepped.
		# <---------------------- ROUND PROGRESS CHECKS ---------------------->
		if !game_control.live_balls.empty():
			game_control.round_in_progress = true
		# <--------------------- END OF ROUND PROCESSING --------------------->
		elif game_control.launched:
			# Here we deal with the end-of-round process
			game_control.launched = false
			game_control.round_in_progress = false
			round_over_checks()
			if !game_control.game_over:
				game_control.score += 1
				game_control.update_score_labels()
				game_control.new_destroyable_line(game_control.score + 1)
			else:
				game_control.past_scores.append(game_control.score)
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
