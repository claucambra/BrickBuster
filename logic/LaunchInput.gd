extends Control

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var drag_enabled = false
var launched = false
var round_in_progress = false
var score = 0
var first_click_position = Vector2(0,0)
onready var ball_scene = load("res://Ball.tscn")
onready var ball = ball_scene.instance()
onready var line = get_node("../LaunchLine")
onready var wait = get_node("../LaunchTimer")

# Called when the node enters the scene tree for the first time.
func _ready():
	line.add_point(Vector2(0,0), 0)
	line.add_point(Vector2(0,0), 1)
	add_child(ball)

func launch_balls(direction, amount):
	for i in amount:
		var next_ball = ball_scene.instance()
		add_child(next_ball)
		next_ball.launch(direction)
		wait.start()
		yield(wait, "timeout")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	print(score)
	var ball_center = ball.position
	var mouse_position = get_global_mouse_position()
	var line_direction = first_click_position - mouse_position
	line_direction = line_direction.normalized()
	
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
		
	if get_child_count() > 1:
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


