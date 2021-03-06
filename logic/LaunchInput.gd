extends Control

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var drag_enabled = false
onready var line = get_node("../LaunchLine")

# Called when the node enters the scene tree for the first time.
func _ready():
	line.add_point(Vector2(0,0), 0)
	line.add_point(Vector2(0,0), 1)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var ballCenter = get_node("../Ball").global_position
	var mousePosition = get_global_mouse_position()
	var direction = mousePosition - ballCenter
	
	line.visible = false
	if drag_enabled:
		line.visible = true
		line.set_point_position(0, mousePosition)
		line.set_point_position(1, ballCenter)

func _on_Control_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			drag_enabled = event.pressed
			#print(drag_enabled)


