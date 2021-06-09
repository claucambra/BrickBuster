extends Panel

signal pause_menu_toggled(popup_open)
signal restart_button_clicked
signal quit_to_menu_button_clicked

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var global = get_node("/root/Global")
onready var menu_button = $MarginContainer/HBoxContainer/Button
onready var popup = $MarginContainer/HBoxContainer/Button/PopupMenu
onready var help_popup = $Instructions
onready var close_timer = $CloseTimer
var mouse_in_popup = false
var mouse_on_button = false

# Called when the node enters the scene tree for the first time.
func _ready():
	popup.add_item("Continue", 0)
	popup.add_item("Restart", 1)
	popup.add_item("Help", 2)
	popup.add_item("Quit to main menu", 3)
	popup.connect("id_pressed", self, "_on_MenuItem_pressed")
	popup.popup_centered()
	popup.hide()
	
	help_popup.popup_centered()
	help_popup.hide()
	
	close_timer.one_shot = true
	close_timer.wait_time = 0.25
	
	var animation = Animation.new()
	var track_index = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_index, String(popup.get_path()) + ":modulate:a")
	animation.track_insert_key(track_index, 0.0, 0.0)
	animation.track_insert_key(track_index, 0.3, 1.0)
	$AnimationPlayer.add_animation("fadein", animation)
	
	animation = Animation.new()
	track_index = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_index, str(popup.get_path()) + ":modulate:a")
	animation.track_insert_key(track_index, 0.0, 1.0)
	animation.track_insert_key(track_index, 0.3, 0.0)
	$AnimationPlayer.add_animation("fadeout", animation)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("escape"):
		popup.visible = !popup.visible
		emit_signal("pause_menu_toggled", popup.visible)

func _on_MenuItem_pressed(id):
	if id != 2:
		$AnimationPlayer.play("fadeout")
	match id:
		1:
			close_timer.start() # Stops ball being shot on accident
			emit_signal("pause_menu_toggled", false)
			emit_signal("restart_button_clicked")
		2:
			help_popup.visible = true
		3:
			close_timer.start()
			emit_signal("pause_menu_toggled", false)
			emit_signal("quit_to_menu_button_clicked")

func _on_PopupMenu_mouse_entered():
	mouse_in_popup = true

func _on_PopupMenu_mouse_exited():
	mouse_in_popup = false

func _on_Button_mouse_entered():
	mouse_on_button = true

func _on_Button_mouse_exited():
	mouse_on_button = false

func _on_Button_pressed():
	if !popup.visible:
		popup.visible = true
		$AnimationPlayer.play("fadein")
		emit_signal("pause_menu_toggled", popup.visible)
	else:
		$AnimationPlayer.play("fadeout")

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "fadeout":
		popup.visible = false
		emit_signal("pause_menu_toggled", popup.visible)
