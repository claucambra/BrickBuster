extends RigidBody2D

# This file defines the behaviour of the ball, and how it should react to
# hitting nodes of different types.

signal ball_no_contact_timeout(self_position, self_linear_velocity)
signal ball_died(ball)

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export var speed = 250
var ball_color = "#ffffff"
var marker_ball = false

func launch (vector):
	apply_impulse(Vector2(0,0), vector.normalized() * speed)
	$LaunchAudio.play()

func set_color(color):
	ball_color = color
	$Light2D.color = color
	if ($MetaNode.ball_name == "Standard ball"):
		update()
	else:
		$Polygon2D.color = color

# Called when the node enters the scene tree for the first time.
func _ready():
	$Timer.wait_time = 5.0
	$Timer.start()
	
	if $MetaNode.ball_name != "Standard ball":
		$Polygon2D.color = ball_color

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#pass

func _on_Ball_body_entered(body):
	if not ("Wall" in body.get_name()):
		# Restart the timer if we hit something. In standard this is used to 
		# bring up a bouncy special if there's a while in which nothing has been
		# hit.
		$Timer.start()
	if "Brick" in body.get_name():
		body.health -= 1
		body.hit = true
		$BrickHitAudio.play()
	elif body.get_name() == "EliminatorBottomWall" and marker_ball == false:
		# The marker ball indicates where the balls will be launched from.
		# Slight variations when we reposition can make it touch the bottom wall
		# but we want to make sure it isn't killed off.
		emit_signal("ball_died", self)
		self.queue_free()
	else:
		$WallHitAudio.play()

func _draw():
	# No circle polygon node available so we draw one instead
	if ($MetaNode.ball_name == "Standard ball"):
		draw_circle($CollisionThing2D.position, 10, Color(ball_color))

func _on_Timer_timeout():
	emit_signal("ball_no_contact_timeout", self.position, self.linear_velocity)
