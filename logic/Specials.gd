extends Area2D

signal special_area_entered(type)

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var mode = null

var hit = false
var hor_position = null
var current_vert_position = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if hit:
		self.queue_free()

func _draw():
	draw_arc($CollisionShape2D.position, 20, 1, 359, 2000, ColorN("white", 1), 5)

func _on_Special_body_entered(body):
	if "Ball" in body.get_name():
		hit = true
		emit_signal("special_area_entered", mode)
