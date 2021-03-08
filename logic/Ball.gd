extends RigidBody2D

signal clicked

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var held = false
export var speed = 250

func launch (vector):
	apply_impulse(Vector2(0,0), vector.normalized() * speed)

# Called when the node enters the scene tree for the first time.
#func _ready():


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):




