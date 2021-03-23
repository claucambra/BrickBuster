extends Line2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	self.default_color = ColorN("red", 1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	self.points[0] = Vector2.ZERO
	self.points[1] = Vector2(self.get_viewport_rect().size.x, 0)

func _on_LaserArea2D_body_entered(body):
	if "Brick" in body.get_name():
		body.health -= 1
