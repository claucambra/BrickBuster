extends Popup

signal game_mode_selected(game_mode_name)

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var game_mode_list = $GameModeList
onready var go_button = $HBoxContainer/GoButton

# Called when the node enters the scene tree for the first time.
func _ready():
	var game_modes_dir = Directory.new()
	var path = "res://logic/GameModes/"
	game_modes_dir.open(path)
	game_modes_dir.list_dir_begin()

	var iterator = 0
	while true:
		var file_name = game_modes_dir.get_next()
		if file_name == "":
			break
		elif not file_name.begins_with("."):
			var game_mode_file = load(path + file_name)
			var holder_node = Node2D.new()
			holder_node.set_script(game_mode_file)
			var game_mode_details = holder_node.get("game_mode_details")
			game_mode_list.add_item(game_mode_details.display_name)
			game_mode_list.set_item_metadata(iterator, game_mode_details)
			iterator += 1
	game_modes_dir.list_dir_end()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	go_button.disabled = !game_mode_list.is_anything_selected()


func _on_GoButton_pressed():
	var selected_item = game_mode_list.get_selected_items()[0]
	var mode_details = game_mode_list.get_item_metadata(selected_item)
	emit_signal("game_mode_selected", mode_details.name)

func _on_CancelButton_pressed():
	visible = false
