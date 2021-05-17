extends Popup


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var item_lists = [] # Used for quick rewriting with sorted lists

onready var global = get_node("/root/Global")
onready var tab_container = $MarginContainer/VBoxContainer/TabContainer
onready var sort_options_button = $MarginContainer/VBoxContainer/HBoxContainer/SortOptionButton

# Called when the node enters the scene tree for the first time.
func _ready():
	if global.save_game_data:
		var past_scores = global.save_game_data["past_scores"]
		if !past_scores.empty():
			
			for key in past_scores.keys():
				var scroll_container = ScrollContainer.new()
				var item_list = ItemList.new()
				item_lists.append(item_list)
				tab_container.add_child(scroll_container)
				scroll_container.add_child(item_list)
				
				scroll_container.name = key
				scroll_container.size_flags_horizontal = 3
				scroll_container.size_flags_vertical = 3
				item_list.size_flags_horizontal = 3
				item_list.size_flags_vertical = 3
				item_list.auto_height = true
				item_list.set("custom_fonts/font", global.noto_font)
				
				var item_index = 0
				var top_score = past_scores[key].max()
				for score in past_scores[key]:
					item_list.add_item(String(score), null, false)
					# We set an id number with item_index, we can also use item_index to access the right item
					# Since list is currently in the order acquired from the save file.
					item_list.set_item_metadata(item_index, item_index)
					if score == top_score:
						item_list.set_item_custom_bg_color(item_index,ColorN("red", 1))
					item_index += 1
		
		sort_options_button.add_item("By attainment (asc)", 0)
		sort_options_button.add_item("By attainment (desc)", 1)
		sort_options_button.add_item("By score (asc)", 2)
		sort_options_button.add_item("By score (desc)", 3)
		sort_options_button.theme = Theme.new()
		sort_options_button.theme.default_font = global.noto_font

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
	for list in item_lists: # Redo each list
		var num_items = list.get_item_count()
		var scores = []
		for index in num_items:
			scores.append([list.get_item_text(index), list.get_item_metadata(index)])
		
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
		
		list.clear()
		var item_index = 0
		for score in scores:
			list.add_item(score[0], null, false)
			list.set_item_metadata(item_index, score[1])
			if score[0] == top_score:
				list.set_item_custom_bg_color(item_index,ColorN("red", 1))
			item_index += 1

func _on_CloseButton_pressed():
	hide()
