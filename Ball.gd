extends Area2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export var speed = 200
var direction = Vector2.UP
onready var _initial_pos = position

# Called when the node enters the scene tree for the first time.
#func _ready():

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position += speed * delta * direction
