extends Control

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# These variables are used to keep track of what stage of the round we are in
# This is used to decide input state and acceptance
var drag_enabled = false
# launched is used to differentiate between states when there are no live balls
# i.e. idling vs just after all balls have returned to bottom of screen
var launched = false
var round_in_progress = false
var live_balls = []
var live_bricks = []
var score = 0
var first_click_position = Vector2(0,0)
var rng = RandomNumberGenerator.new()

onready var score_label = $MetaArea/HBoxContainer/ScoreLabel
onready var ball_scene = load("res://scenes/Ball.tscn")
onready var brick_scene = load("res://scenes/Brick.tscn")
onready var slanted_brick_scene = load("res://scenes/SlantedBrick.tscn")
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

func launch_balls(direction, amount):
	for i in amount:
		var next_ball = ball_scene.instance()
		add_child(next_ball)
		next_ball.launch(direction)
		live_balls.append(next_ball)
		wait.start()
		yield(wait, "timeout")

func new_block_line(health, vert_position = 0):
	for column in columns:
		if rng.randi_range(0,2) > 0: 
			var next_brick
			if rng.randi_range(0,3) == 3:
				next_brick = slanted_brick_scene.instance()
				next_brick.rotation_degrees = rng.randi_range(0,3) * 90
			else:
				next_brick = brick_scene.instance()
			next_brick.health = health
			next_brick.hor_position = columns.find(column)
			next_brick.current_vert_position = vert_position
			add_child(next_brick)
			# We set it at 0 and then add 1 to vert position to get swanky movement down
			next_brick.set_position(column.get_point_position(vert_position))
			next_brick.current_vert_position += 1
			live_bricks.append(next_brick)

# Called when the node enters the scene tree for the first time.
func _ready():
	line.add_point(Vector2(0,0), 0)
	line.add_point(Vector2(0,0), 1)
	add_child(ball)
	wait.wait_time = 0.1
	rng.randomize()
	self.new_block_line(score + 1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	rng.randomize()
	score_label.text = String(score)
	
	var ball_center = ball.position
	var mouse_position = get_global_mouse_position()
	var line_direction = first_click_position - mouse_position
	line_direction = line_direction.normalized()
	
	for live_ball in live_balls:
		if !is_instance_valid(live_ball):
			live_balls.erase(live_ball)
	
	# "click" is defined in input map
	if Input.is_action_just_pressed("click") && !round_in_progress:
		first_click_position = get_global_mouse_position()
		drag_enabled = true
	
	# Line drawing and touch place responsibilities
	update() # Updates _draw func
	line.visible = false
	if drag_enabled && !round_in_progress:
		line.visible = true
		line.set_point_position(0, ball_center)
		line.set_point_position(1, line_direction*10000)
	
	# Launch handling
	if Input.is_action_just_released("click") && !round_in_progress && drag_enabled: 
		drag_enabled = false
		self.launch_balls(line_direction, score + 1)
		launched = true
	
	# Round progress checking section
	var inv_live_bricks = live_bricks.duplicate()
	# We have an inverted array so blocks don't get superimposed when newer blocks moved down
	inv_live_bricks.invert() 
	if !live_balls.empty():
		round_in_progress = true
	elif launched:
		score += 1
		launched = false
		round_in_progress = false
		for live_brick in inv_live_bricks:
			if !is_instance_valid(live_brick):
				live_bricks.erase(live_brick)
			else:
				live_brick.current_vert_position += 1
				if live_brick.current_vert_position == 8:
					get_tree().reload_current_scene()
		self.new_block_line(score + 1)
	else:
		var num_incorrect_brick_position = 0
		for live_brick in inv_live_bricks:
			var destination = columns[live_brick.hor_position].get_point_position(live_brick.current_vert_position)
			print (live_brick.position == destination)
			if live_brick.position != destination:
				num_incorrect_brick_position += 1
				var reposition = live_brick.position - destination
				# Snap blocks into position when they are imperceptibly close
				# Otherwise they will never reach the intended position
				if reposition.y > -2:
					live_brick.position = destination
				else:
					var reposition_velocity = reposition * 6 * delta
					live_brick.position -= reposition_velocity
		if num_incorrect_brick_position == 0:
			round_in_progress = false
		else:
			round_in_progress= true

func _draw():
	if drag_enabled && !round_in_progress:
		draw_circle(first_click_position, 25, ColorN("black", 0.5))


