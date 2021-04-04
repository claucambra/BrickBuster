extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var save_game = File.new()
var rng = RandomNumberGenerator.new()
onready var popup_menu = $CanvasLayer/MainMenu/VBoxContainer/ScoresButton/PopupMenu

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
			var popup_score_list = $CanvasLayer/MainMenu/VBoxContainer/ScoresButton/PopupMenu/MarginContainer/VBoxContainer/ItemList
			for score in past_scores:
				popup_score_list.add_item(String(score))
	
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
