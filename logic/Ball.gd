extends RigidBody2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export var speed = 250

func launch (vector):
	apply_impulse(Vector2(0,0), vector.normalized() * speed)

# Called when the node enters the scene tree for the first time.
#func _ready():

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#pass

func _on_Ball_body_entered(body):
	if body.get_name() == "BottomWall":
		self.queue_free()
	if body.get_name() == "Brick":
		body.health -= 1
