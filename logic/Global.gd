extends Node

var save_game = File.new()
var save_game_data = null
var rng = RandomNumberGenerator.new()
var config = ConfigFile.new()
var err = config.load("user://settings.cfg")
var noto_font = load("res://styling/fonts/NotoSans.tres")
var noto_font_bold = load("res://styling/fonts/NotoSans_Bold.tres")

var selected_ball_scene = null
var ball_scenes = []
var past_scores = {}
var game_modes = {}

var colour_themes = {
	"sunburst": {
		"display_name": "Sunburst",
		"top_health": Color("#ff3300"),
		"bottom_health": Color("#ffe600")
	},
	"supernova": {
		"display_name": "Supernova",
		"top_health": Color("#5500ff"),
		"bottom_health": Color("#00e1ff")
	},
	"aurora": {
		"display_name": "Aurora",
		"top_health": Color("#1f4037"),
		"bottom_health": Color("#99f2c8")
	},
	"nebula": {
		"display_name": "Nebula",
		"top_health": Color("#FC466B"),
		"bottom_health": Color("#3F5EFB")
	},
	"pulsar": {
		"display_name": "Pulsar",
		"top_health": Color("#16A085"),
		"bottom_health": Color("#F56217")
	},
	"quasar": {
		"display_name": "Quasar",
		"top_health": Color("#F4D03F"),
		"bottom_health": Color("#0B486B")
	}
}

var selected_standard_theme = "sunburst"
var selected_mega_theme = "supernova"

func reload_save_data():
	save_game.open("user://savegame.save", File.READ)
	save_game_data = parse_json(save_game.get_line())
	save_game.close()

func reload_selected_ball():
	selected_ball_scene = load("res://scenes/Balls/" + config.get_value("ball", "ball_file_name"))

func convert_past_scores(past_scores):
	var new_type_scores = {"standard": past_scores}
	
	var save_dict = {
		"game_mode": save_game_data["game_mode"],
		"score": save_game_data["score"],
		"ammo": save_game_data["ammo"],
		"launch_ball_position_x": save_game_data["launch_ball_position_x"],
		"launch_ball_position_y": save_game_data["launch_ball_position_y"],
		"destroyables" : save_game_data["destroyables"],
		"past_scores": new_type_scores
	}
	
	save_game.open("user://savegame.save", File.WRITE)
	save_game.store_line(to_json(save_dict))
	save_game.close()
	reload_save_data()
	return new_type_scores

func write_save_file(game_mode = "standard", first_save = false):
	var save_dict = {
		"game_mode": game_mode,
		"score": 0,
		"ammo": 1,
		"launch_ball_position_x": 360,
		"launch_ball_position_y": 1072,
		"destroyables" : []
	}
	
	if first_save:
		save_dict["past_scores"] = {"standard": []}
	else:
		save_dict["past_scores"] = save_game_data["past_scores"]
	
	save_game.open("user://savegame.save", File.WRITE)
	save_game.store_line(to_json(save_dict))
	save_game.close()
	reload_save_data()

func fetch_balls():
	var ball_scenes_dir = Directory.new()
	var path = "res://scenes/Balls/"
	ball_scenes_dir.open(path)
	ball_scenes_dir.list_dir_begin()

	while true:
		var file_name = ball_scenes_dir.get_next()
		if file_name == "":
			break
		elif not file_name.begins_with("."):
			var ball_scene = load(path + file_name)
			ball_scenes.append({"filename": file_name, "ball_scene": ball_scene})

	ball_scenes_dir.list_dir_end()

func fetch_game_modes():
	var game_modes_dir = Directory.new()
	var path = "res://logic/GameModes/"
	game_modes_dir.open(path)
	game_modes_dir.list_dir_begin()

	while true:
		var file_name = game_modes_dir.get_next()
		if file_name == "":
			break
		elif not file_name.begins_with("."):
			var game_mode_file = load(path + file_name)
			var holder_node = Node2D.new()
			holder_node.set_script(game_mode_file)
			var game_mode_details = holder_node.get("game_mode_details")
			game_modes[game_mode_details.name] = {}
			game_modes[game_mode_details.name]["path"] = path + file_name
			game_modes[game_mode_details.name]["name"] = game_mode_details.name
			game_modes[game_mode_details.name]["display_name"] = game_mode_details.display_name
			game_modes[game_mode_details.name]["description"] = game_mode_details.description
	game_modes_dir.list_dir_end()

func set_theme():
	selected_standard_theme = config.get_value("theme", "standard_bricks")
	selected_mega_theme = config.get_value("theme", "mega_bricks")

func _ready():
	if save_game.file_exists("user://savegame.save"):
		reload_save_data()
		past_scores = save_game_data["past_scores"]
		if typeof(past_scores) == TYPE_ARRAY: # Convert old type score store
			past_scores = convert_past_scores(past_scores)
	
	var need_to_save_config = false
	if err == ERR_FILE_NOT_FOUND:
		config.set_value("lighting", "enabled", true)
		config.set_value("audio", "volume", 10)
		config.set_value("ball", "color", "#ffffff")
		config.set_value("ball", "ball_file_name", "Ball.tscn")
		config.set_value("theme", "standard_bricks", "sunburst")
		config.set_value("theme", "mega_bricks", "supernova")
		config.save("user://settings.cfg")
		config.load("user://settings.cfg")
	
	if config.get_value("lighting", "enabled") == null:
		config.set_value("lighting", "enabled", true)
		need_to_save_config = true
	
	if config.get_value("audio", "volume") == null:
		config.set_value("audio", "volume", 10)
		need_to_save_config = true
	
	if config.get_value("ball", "color") == null:
		config.set_value("ball", "color", "#ffffff")
		need_to_save_config = true
	
	if config.get_value("ball", "ball_file_name") == null:
		config.set_value("ball", "ball_file_name", "Ball.tscn")
		need_to_save_config = true
	
	if config.get_value("theme", "standard_bricks") == null:
		config.set_value("theme", "standard_bricks", "sunburst")
		config.set_value("theme", "mega_bricks", "supernova")
		need_to_save_config = true
	
	if need_to_save_config:
		config.save("user://settings.cfg")
		config.load("user://settings.cfg")
	
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), config.get_value("audio", "volume") == 0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), config.get_value("audio", "volume"))
	
	fetch_game_modes()
	fetch_balls()
	reload_selected_ball()
	set_theme()

