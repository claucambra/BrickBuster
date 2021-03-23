extends Area2D

signal special_area_entered(special)

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var mode = null
var laserbeam_direction = null
var colors = {
	"add-ball": Color("#3cc864"),
	"bounce": Color("#e64ce0"),
	"laser": Color("#ff0000")
}

var hit = false
var column_num = null
var column_vert_point = null
var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if hit && mode == "add-ball":
		self.queue_free()

func _draw():
	draw_arc($CollisionShape2D.position, 20, 1, 359, 2000, colors[mode], 5)

func _on_Special_body_entered(body):
	if "Ball" in body.get_name():
		hit = true
		emit_signal("special_area_entered", self)
		if mode == "bounce":
			body.sleeping = true
			rng.randomize()
			var rand_x = rng.randf_range(0, -1)
			var rand_y = rng.randf_range(0, -1)
			body.launch(Vector2(rand_x, rand_y))
