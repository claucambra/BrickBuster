extends Control

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var drag_enabled = false
var launched = false
var round_in_progress = false
var live_balls = []
var score = 0
var first_click_position = Vector2(0,0)
var rng = RandomNumberGenerator.new()
onready var ball_scene = load("res://scenes/Ball.tscn")
onready var brick_scene = load("res://scenes/Brick.tscn")
onready var ball = ball_scene.instance()
onready var test_brick = brick_scene.instance()
onready var line = get_node("../LaunchLine")
onready var wait = get_node("../LaunchTimer")
onready var columns = [
	get_node("../Column0"),
	get_node("../Column1"),
	get_node("../Column2"),
	get_node("../Column3"),
	get_node("../Column4"),
	get_node("../Column5"),
	get_node("../Column6")
]

# Called when the node enters the scene tree for the first time.
func _ready():
	line.add_point(Vector2(0,0), 0)
	line.add_point(Vector2(0,0), 1)
	add_child(ball)
	add_child(test_brick)
	rng.randomize()
	test_brick.set_position(columns[rng.randi_range(0, 6)].get_point_position(0))

func launch_balls(direction, amount):
	for i in amount:
		var next_ball = ball_scene.instance()
		add_child(next_ball)
		next_ball.launch(direction)
		live_balls.append(next_ball)
		wait.start()
		yield(wait, "timeout")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	print(score)
	var ball_center = ball.position
	var mouse_position = get_global_mouse_position()
	var line_direction = first_click_position - mouse_position
	line_direction = line_direction.normalized()
	
	for ball in live_balls:
		if !is_instance_valid(ball):
			live_balls.remove(live_balls.find(ball))
	
	if Input.is_action_just_pressed("click"):
		first_click_position = get_global_mouse_position()
		drag_enabled = true
	
	# Line drawing and touch place responsibilities
	update() # Updates _draw func
	line.visible = false
	if drag_enabled:
		line.visible = true
		line.set_point_position(0, ball_center)
		line.set_point_position(1, line_direction*10000)
		
	if Input.is_action_just_released("click"): # Defined in input map
		drag_enabled = false
		self.launch_balls(line_direction, 10)
		launched = true
		
	if !live_balls.empty():
		round_in_progress = true
	elif launched == true:
		launched = false
		round_in_progress = false
		score += 1
	else:
		round_in_progress = false

func _draw():
	if drag_enabled:
		draw_circle(first_click_position, 25, ColorN("black", 0.5))


