extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var save_game = File.new()
var rng = RandomNumberGenerator.new()
onready var popup_menu = $CanvasLayer/MainMenu/VBoxContainer/ScoresButton/PopupMenu
onready var popup_score_list = $CanvasLayer/MainMenu/VBoxContainer/ScoresButton/PopupMenu/MarginContainer/VBoxContainer/ItemList

# Called when the node enters the scene tree for the first time.
func _ready():
	if not save_game.file_exists("user://savegame.save"):
		$CanvasLayer/MainMenu/VBoxContainer/ContinueButton.visible = false
		$CanvasLayer/MainMenu/VBoxContainer/ScoresButton.disabled = true
		popup_menu.disabled = true
	else:
		save_game.open("user://savegame.save", File.READ)
		while save_game.get_position() < save_game.get_len():
			var node_data = parse_json(save_game.get_line())
			var past_scores = node_data["past_scores"]
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
		var sort_options_button = $CanvasLayer/MainMenu/VBoxContainer/ScoresButton/PopupMenu/MarginContainer/VBoxContainer/HBoxContainer/SortOptionButton
		sort_options_button.add_item("By attainment (asc)", 0)
		sort_options_button.add_item("By attainment (desc)", 1)
		sort_options_button.add_item("By score (asc)", 2)
		sort_options_button.add_item("By score (desc)", 3)
	
	rng.randomize()
	$TitleBrick.health = 90000
	$TitleBrick.max_possible_health = 100000
	$Ball.launch(Vector2(rng.randf_range(1, -1),rng.randf_range(-0, -1)))
	
	popup_menu.popup_centered()
	popup_menu.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_ContinueButton_pressed():
	get_tree().change_scene("res://scenes/Board.tscn")
	
func _on_NewGameButton_pressed():
	if save_game.file_exists("user://savegame.save"):
		save_game.open("user://savegame.save", File.READ)
		
		var node_data = parse_json(save_game.get_line())
		var save_dict = {
			"score": 0,
			"past_scores": node_data["past_scores"],
			"ammo": 1,
			"launch_ball_position_x": 360,
			"launch_ball_position_y": 1072,
			"destroyables" : []
		}
		save_game.close()
		
		save_game.open("user://savegame.save", File.WRITE)
		save_game.store_line(to_json(save_dict))
		save_game.close()
	
	get_tree().change_scene("res://scenes/Board.tscn")

func _on_QuitButton_pressed():
	get_tree().quit()

func _on_Ball_body_entered(body):
	pass # Replace with function body.

func _on_ScoresButton_pressed():
	popup_menu.visible = !popup_menu.visible

class Sorter:
	static func sort_id_ascending(a, b):
		if a[1] < b[1]:
			return true
		return false
	
	static func sort_id_descending(a, b):
		if a[1] > b[1]:
			return true
		return false
	
	static func sort_score_ascending(a, b):
		if a[0] < b[0]:
			return true
		return false
	
	static func sort_score_descending(a, b):
		if a[0] > b[0]:
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
