extends Popup


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var save_game = File.new()

onready var popup_score_list = $MarginContainer/VBoxContainer/ScrollContainer/ItemList
onready var sort_options_button = $MarginContainer/VBoxContainer/HBoxContainer/SortOptionButton

# Called when the node enters the scene tree for the first time.
func _ready():
	if save_game.file_exists("user://savegame.save"):
		save_game.open("user://savegame.save", File.READ)
		while save_game.get_position() < save_game.get_len():
			var node_data = parse_json(save_game.get_line())
			var past_scores = node_data["past_scores"]
			if !past_scores.empty():
				var top_score = past_scores.max()
				var item_index = 0
				for score in past_scores:
					popup_score_list.add_item(String(score), null, false)
					# We set an id number with item_index, we can also use item_index to access the right item
					# Since list is currently in the order acquired from the save file.
					popup_score_list.set_item_metadata(item_index, item_index)
					if score == top_score:
						popup_score_list.set_item_custom_bg_color(item_index,ColorN("red", 1))
					item_index += 1
		
		sort_options_button.add_item("By attainment (asc)", 0)
		sort_options_button.add_item("By attainment (desc)", 1)
		sort_options_button.add_item("By score (asc)", 2)
		sort_options_button.add_item("By score (desc)", 3)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

class Sorter:
	static func sort_id_ascending(a, b):
		if int(a[1]) < int(b[1]):
			return true
		return false
	
	static func sort_id_descending(a, b):
		if int(a[1]) > int(b[1]):
			return true
		return false
	
	static func sort_score_ascending(a, b):
		if int(a[0]) < int(b[0]):
			return true
		return false
	
	static func sort_score_descending(a, b):
		if int(a[0]) > int(b[0]):
			return true
		return false

func _on_SortOptionButton_item_selected(index):
	var num_items = popup_score_list.get_item_count()
	var scores = []
	for index in num_items:
		scores.append([popup_score_list.get_item_text(index), popup_score_list.get_item_metadata(index)])
	
	scores.sort_custom(Sorter, "sort_score_descending")
	var top_score = scores[0][0]
	
	match index:
		0:
			scores.sort_custom(Sorter, "sort_id_ascending")
		1:
			scores.sort_custom(Sorter, "sort_id_descending")
		2:
			scores.sort_custom(Sorter, "sort_score_ascending")
		3:
			scores.sort_custom(Sorter, "sort_score_descending")
	
	popup_score_list.clear()
	var item_index = 0
	for score in scores:
		popup_score_list.add_item(score[0], null, false)
		popup_score_list.set_item_metadata(item_index, score[1])
		if score[0] == top_score:
			popup_score_list.set_item_custom_bg_color(item_index,ColorN("red", 1))
		item_index += 1

func _on_OkButton_pressed():
	hide()
