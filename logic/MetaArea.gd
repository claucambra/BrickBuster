extends Panel

signal pause_menu_toggled
signal restart_button_clicked

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var menu_button = $MarginContainer/HBoxContainer/Button
onready var popup = $MarginContainer/HBoxContainer/Button/PopupMenu
var mouse_in_popup = false
var mouse_on_button = false

# Called when the node enters the scene tree for the first time.
func _ready():
	popup.add_item("Continue", 0)
	popup.add_item("Restart", 1)
	popup.add_item("Quit to main menu", 2)
	popup.connect("id_pressed", self, "_on_MenuItem_pressed")
	popup.popup_centered()
	popup.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if popup.visible && Input.is_action_just_released("click") && !(mouse_in_popup || mouse_on_button):
		menu_button.pressed = false
	if Input.is_action_just_pressed("escape"):
		menu_button.pressed = !menu_button.pressed

func _on_Button_toggled(_button_pressed):
	popup.visible = !popup.visible
	emit_signal("pause_menu_toggled")

func _on_MenuItem_pressed(id):
	menu_button.pressed = false
	match id:
		1:
			emit_signal("restart_button_clicked")
		2:
			get_tree().change_scene("res://scenes/MainMenu.tscn")

func _on_PopupMenu_mouse_entered():
	mouse_in_popup = true

func _on_PopupMenu_mouse_exited():
	mouse_in_popup = false

func _on_Button_mouse_entered():
	mouse_on_button = true

func _on_Button_mouse_exited():
	mouse_on_button = false

func _on_PopupMenu_popup_hide():
	menu_button.pressed = false
