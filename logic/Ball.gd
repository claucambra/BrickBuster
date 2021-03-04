extends RigidBody2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export var speed = 150.0

# Called when the node enters the scene tree for the first time.
func _ready():
	apply_impulse(Vector2(), Vector2(1, -1).normalized() * speed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
