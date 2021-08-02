extends Line2D

# This script handles the laserbeams ejected by a laser special.
# The key things it does is handle the fade-in and out of the line,
# as well as the reducing of the health of the bricks within its area.

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	default_color = ColorN("red", 1)
	var length = get_viewport_rect().size.x + get_viewport_rect().size.y
	points[0] = Vector2.ZERO
	points[1] = Vector2(length, 0)
	$LaserArea2D/LaserCollisionShape2D.shape.extents = Vector2(length, 1)
	modulate.a = 1
	$LaserBeamAudio.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if modulate.a > 0:
		modulate.a -= 0.1
	else:
		queue_free()

func _on_LaserArea2D_body_entered(body):
	if "Brick" in body.get_name():
		body.health -= 1
