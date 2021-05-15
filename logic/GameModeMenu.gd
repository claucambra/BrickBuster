extends Popup

signal game_mode_selected(game_mode_name)

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var global = get_node("/root/Global")
onready var game_mode_list = $GameModeList
onready var go_button = $HBoxContainer/GoButton

# Called when the node enters the scene tree for the first time.
func _ready():
	var iterator = 0
	for game_mode in global.game_modes:
		game_mode_list.add_item(global.game_modes[game_mode].display_name)
		iterator += 1


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	go_button.disabled = !game_mode_list.is_anything_selected()


func _on_GoButton_pressed():
	var selected_item = game_mode_list.get_selected_items()[0]
	var mode_details = game_mode_list.get_item_metadata(selected_item)
	emit_signal("game_mode_selected", mode_details.name)

func _on_CancelButton_pressed():
	visible = false
