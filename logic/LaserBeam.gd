extends Line2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	self.default_color = ColorN("red", 1)
	var length = self.get_viewport_rect().size.x + self.get_viewport_rect().size.y
	self.points[0] = Vector2.ZERO
	self.points[1] = Vector2(length, 0)
	$LaserArea2D/LaserCollisionShape2D.shape.extents = Vector2(length, 1)
	self.modulate.a = 1
	$LaserBeamAudio.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if self.modulate.a > 0:
		self.modulate.a -= 0.1
	else:
		self.queue_free()

func _on_LaserArea2D_body_entered(body):
	if "Brick" in body.get_name():
		body.health -= 1
