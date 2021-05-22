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

var gradient = Gradient.new()

onready var global = get_node("/root/Global")
onready var brick_shape = $BrickShape
onready var label = $HealthLabel
onready var timer = $Timer

# Called when the node enters the scene tree for the first time.
func _ready():
	timer.wait_time = 0.3
	if mega:
		gradient.set_color(1, global.top_megahealth_colour)
		gradient.set_color(0, global.bottom_megahealth_colour)
		health *= 2
		max_possible_health *= 2
	else:
		gradient.set_color(1, global.top_health_colour)
		gradient.set_color(0, global.bottom_health_colour)
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
			self.queue_free()
			emit_signal("brick_killed", self)
	else:
		if self.modulate.a < 1:
			self.modulate.a += 0.05
	
	if hit:
		self.modulate.a = 0.5
		self.hit = false

