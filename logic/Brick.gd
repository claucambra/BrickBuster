extends KinematicBody2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var health = null
var hit = false
var hor_position = null
var current_vert_position = null
onready var label = $HealthLabel
onready var timer = $Timer

# Called when the node enters the scene tree for the first time.
func _ready():
	timer.wait_time = 0.1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	label.text = String(health)
	if health <= 0:
		self.queue_free()
	if hit:
		self.modulate.a = 0.5
		timer.start()
		self.hit = false
	else:
		self.modulate.a = 1
