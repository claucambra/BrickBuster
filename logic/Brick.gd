extends KinematicBody2D

signal brick_killed(brick)

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var health = null
var mega = null
var max_possible_health = null
var hit = false
var column_num = null
var column_vert_point = null

var top_health_colour = Color("#ff3300")
var bottom_health_colour = Color("#ffe600")
var top_megahealth_colour = Color("#5500ff")
var bottom_megahealth_colour = Color("#00e1ff")
var gradient = Gradient.new()

onready var brick_shape = $BrickShape
onready var label = $HealthLabel
onready var timer = $Timer

# Called when the node enters the scene tree for the first time.
func _ready():
	timer.wait_time = 0.3
	if mega:
		gradient.set_color(1, top_megahealth_colour)
		gradient.set_color(0, bottom_megahealth_colour)
		health *= 2
		max_possible_health *= 2
	else:
		gradient.set_color(1, top_health_colour)
		gradient.set_color(0, bottom_health_colour)
	self.modulate.a = 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	label.text = String(health)
	brick_shape.color = gradient.interpolate(float(health)/float(max_possible_health))
	$Light2D.color = brick_shape.color
	
	if health <= 0:
		$Collision2D.disabled = true
		if self.modulate.a > 0:
			self.modulate.a -= 0.05
		else:
			emit_signal("brick_killed", self)
			self.queue_free()
	else:
		if self.modulate.a < 1:
			self.modulate.a += 0.05
	
	if hit:
		self.modulate.a = 0.5
		self.hit = false

