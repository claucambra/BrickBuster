extends KinematicBody2D

signal brick_killed(brick)

var health = null
# "Mega" bricks have double health and an independent colour scheme.
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
		gradient.set_color(1, global.colour_themes[global.selected_mega_theme].top_health)
		gradient.set_color(0, global.colour_themes[global.selected_mega_theme].bottom_health)
		health *= 2
		max_possible_health *= 2
	else:
		gradient.set_color(1, global.colour_themes[global.selected_standard_theme].top_health)
		gradient.set_color(0, global.colour_themes[global.selected_standard_theme].bottom_health)
	modulate.a = 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	label.text = str(health)
	brick_shape.color = gradient.interpolate(float(health)/float(max_possible_health))
	$Light2D.color = brick_shape.color
	
	if health <= 0:
		$Collision2D.disabled = true
		label.text = str(0)
		if modulate.a > 0:
			modulate.a -= 0.05
		else:
			queue_free()
			emit_signal("brick_killed", self)
	else:
		if modulate.a < 1:
			modulate.a += 0.05
	
	if hit:
		modulate.a = 0.5
		hit = false

