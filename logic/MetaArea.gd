extends Panel

signal pause_menu_toggled
signal restart_button_clicked

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var menu_button = $MarginContainer/HBoxContainer/Button

# Called when the node enters the scene tree for the first time.
func _ready():
	menu_button.get_popup().add_item("Continue", 0)
	menu_button.get_popup().add_item("Restart", 1)
	menu_button.get_popup().connect("id_pressed", self, "_on_MenuItem_pressed")


# Called every frame. 'delta' is the elapsed time since the previous frame.
# func _process(delta):
#	pass

func _on_Button_toggled(_button_pressed):
	emit_signal("pause_menu_toggled")

func _on_MenuItem_pressed(id):
	if id == 1:
		emit_signal("restart_button_clicked")
