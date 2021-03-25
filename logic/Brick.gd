extends KinematicBody2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var health = null
var max_possible_health = null
var hit = false
var column_num = null
var column_vert_point = null

var top_health_colour = Color("#932e2e")
var bottom_health_colour = Color("#ffb400")
var gradient = Gradient.new()

onready var brick_shape = $BrickShape
onready var label = $HealthLabel
onready var timer = $Timer

# Called when the node enters the scene tree for the first time.
func _ready():
	timer.wait_time = 0.3
	gradient.set_color(1, top_health_colour)
	gradient.set_color(0, bottom_health_colour)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	label.text = String(health)
	brick_shape.color = gradient.interpolate(float(health)/float(max_possible_health))
	$Light2D.color = brick_shape.color
	if health <= 0:
		self.queue_free()
	if hit:
		self.modulate.a = 0.5
		$Light2D.energy = 10
		timer.start()
		self.hit = false
		self.modulate.a = 1
		$Light2D.energy = 0.5

