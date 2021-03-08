extends Control

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var drag_enabled = false
var firstClickPosition = Vector2(0,0)
onready var ballScene = load("res://Ball.tscn")
onready var ball = ballScene.instance()
onready var line = get_node("../LaunchLine")
onready var wait = get_node("../LaunchTimer")

# Called when the node enters the scene tree for the first time.
func _ready():
	line.add_point(Vector2(0,0), 0)
	line.add_point(Vector2(0,0), 1)
	add_child(ball)

func launchBalls(direction, amount):
	for i in amount:
		var nextBall = ballScene.instance()
		add_child(nextBall)
		nextBall.launch(direction)
		wait.start()
		yield(wait, "timeout")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var ballCenter = ball.position
	var mousePosition = get_global_mouse_position()
	var lineDirection = firstClickPosition - mousePosition
	lineDirection = lineDirection.normalized()
	
	if Input.is_action_just_pressed("click"):
		firstClickPosition = get_global_mouse_position()
		drag_enabled = true
	
	# Line drawing and touch place responsibilities
	update() # Updates _draw func
	line.visible = false
	if drag_enabled:
		line.visible = true
		line.set_point_position(0, ballCenter)
		line.set_point_position(1, lineDirection*10000)
		
	if Input.is_action_just_released("click"): # Defined in input map
		drag_enabled = false
		self.launchBalls(lineDirection, 10)

func _draw():
	if drag_enabled:
		draw_circle(firstClickPosition, 25, ColorN("black", 0.5))


