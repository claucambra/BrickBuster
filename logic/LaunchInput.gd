extends Control

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var drag_enabled = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_Control_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			drag_enabled = event.pressed
			#print(drag_enabled)
			var ballCenter = get_node("../Ball").global_position
			var mousePosition = get_global_mouse_position()
			#var direction = mousePosition - ballCenter
			print(ballCenter)
			print(mousePosition)
			var line = get_node("../LaunchLine")
			if event.pressed:
				line.add_point(mousePosition, 0)
				line.add_point(Vector2(299,299), 1)
			else:
				line.clear_points()


