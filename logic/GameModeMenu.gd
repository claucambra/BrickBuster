extends Popup

# This script handles actions for the game mode selection menu.
# It also find game mode script files in the correct folder and displays them.

signal game_mode_selected(game_mode_name)

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var global = get_node("/root/Global")
onready var game_mode_list = $VBoxContainer/GameModeList
onready var go_button = $HBoxContainer/GoButton

# Called when the node enters the scene tree for the first time.
func _ready():
	var iterator = 0
	for game_mode in global.game_modes:
		game_mode_list.add_item(global.game_modes[game_mode].display_name)
		game_mode_list.set_item_metadata(iterator, global.game_modes[game_mode])
		iterator += 1
	
	var animation = Animation.new()
	var track_index = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_index, String(self.get_path()) + ":modulate:a")
	animation.track_insert_key(track_index, 0.0, 1.0)
	animation.track_insert_key(track_index, 0.3, 0.0)
	$AnimationPlayer.add_animation("fadeout", animation)
	$AnimationPlayer.connect("animation_finished", self, "on_Fadeout_finished")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	go_button.disabled = !game_mode_list.is_anything_selected()


func _on_GoButton_pressed():
	$AnimationPlayer.play("fadeout")
	var selected_item = game_mode_list.get_selected_items()[0]
	var mode_details = game_mode_list.get_item_metadata(selected_item)
	emit_signal("game_mode_selected", mode_details.name)

func _on_CloseButton_pressed():
	$AnimationPlayer.play("fadeout")

func on_Fadeout_finished(_anim_name):
	hide()

func _on_GameModeList_item_selected(_index):
	$AnimationPlayer.play("fadeout")
