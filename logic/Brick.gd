extends KinematicBody2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var health = null
var hor_position = null
var current_vert_position = null
onready var label = $HealthLabel

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	label.text = String(health)
	if health <= 0:
		self.queue_free()
