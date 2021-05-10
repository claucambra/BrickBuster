extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var game_modes = {}
var selected_game_mode = null

var save_game = File.new()

onready var game_control = get_tree().get_root().get_node("MainGame")
onready var board = get_parent().get_node("Board")

func on_game_prepped():
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
			game_modes[game_mode_details.name] = path + file_name
			iterator += 1
	game_modes_dir.list_dir_end()
	
	if save_game.file_exists("user://savegame.save"):
		save_game.open("user://savegame.save", File.READ)
		var node_data = parse_json(save_game.get_line())
		
		# Avoid breakage for those on old versions of the game
		var game_mode = null
		if "game_mode" in node_data:
			selected_game_mode = node_data["game_mode"]
		elif game_mode == null:
			selected_game_mode = "standard"
		
		var script = load(game_modes[selected_game_mode])
		board.set_script(script)
		# _ready() func in a node's script listens for NOTIFICATION_READY
		# Without this, the _ready() func won't be run
		board.notification(NOTIFICATION_READY)
		board.set_process(true)

# Called when the node enters the scene tree for the first time.
func _ready():
	game_control.connect("game_prepped", self, "on_game_prepped")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
