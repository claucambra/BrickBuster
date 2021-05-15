extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var selected_game_mode = null

onready var global = get_node("/root/Global")
onready var game_control = get_tree().get_root().get_node("MainGame")
onready var board = get_parent().get_node("Board")

func on_game_prepped():
	global.fetch_game_modes()
	
	if global.save_game:
		
		# Avoid breakage for those on old versions of the game
		if "game_mode" in global.save_game_data:
			selected_game_mode = global.save_game_data["game_mode"]
		else:
			selected_game_mode = "standard"
		
		var script = load(global.game_modes[selected_game_mode].path)
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
