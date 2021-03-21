extends RigidBody2D

signal ball_no_contact_timeout(self_position, self_linear_velocity)
signal ball_died(self_position)

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export var speed = 250

func launch (vector):
	apply_impulse(Vector2(0,0), vector.normalized() * speed)

# Called when the node enters the scene tree for the first time.
func _ready():
	$Timer.wait_time = 5.0
	$Timer.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
# func _process(delta):
	# pass

func _on_Ball_body_entered(body):
	if !("Wall" in body.get_name()):
		$Timer.start()
		if "Brick" in body.get_name():
			body.health -= 1
			body.hit = true
	if body.get_name() == "BottomWall":
		emit_signal("ball_died", self.position)
		self.queue_free()

func _draw():
	draw_circle($CollisionShape2D.position, 10, ColorN("white", 1))

func _on_Timer_timeout():
	emit_signal("ball_no_contact_timeout", self.position, self.linear_velocity)
