extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var game_modes = {
	"standard": "GameStandard.gd",
	"chaotic": "GameChaotic.gd"
}

var save_game = File.new()

onready var board = get_parent().get_node("Board")

# Called when the node enters the scene tree for the first time.
func _ready():
	var selected_game_mode
	
	if save_game.file_exists("user://savegame.save"):
		save_game.open("user://savegame.save", File.READ)
		var node_data = parse_json(save_game.get_line())
		print(node_data)
		
		# Avoid breakage for those on old versions of the game
		var game_mode = null
		if "game_mode" in node_data:
			selected_game_mode = node_data["game_mode"]
		
		if game_mode == null:
			selected_game_mode = "standard"
		
		print(game_modes[selected_game_mode])
		var script = load("res://logic/GameModes/" + game_modes[selected_game_mode])
		board.set_script(script)
		# _ready() func in a node's script listens for NOTIFICATION_READY
		# Without this, the _ready() func won't be run
		board.notification(NOTIFICATION_READY)
		board.set_process(true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
