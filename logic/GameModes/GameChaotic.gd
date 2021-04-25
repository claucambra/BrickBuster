extends Node2D

onready var game_control = get_tree().get_root().get_node("MainGame")


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var launch_cooldown_timer = Timer.new()
var launch_cooling_down = false

func on_launch_cooldown_timer_timeout():
	launch_cooling_down = false

# Called when the node enters the scene tree for the first time.
func _ready():
	launch_cooling_down = true
	launch_cooldown_timer.connect("timeout", self, "on_launch_cooldown_timer_timeout")
	launch_cooldown_timer.wait_time = 3
	add_child(launch_cooldown_timer)
	game_control.new_destroyable_line(0 + 1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if !game_control.game_over:
		if !launch_cooling_down && game_control.live_balls.size() != game_control.ammo:
			game_control.drag_enabled = true
			if Input.is_action_just_released("click") && game_control.reasonable_angle:
				launch_cooling_down = true
				launch_cooldown_timer.start()
				game_control.launch_balls(game_control.line_direction.normalized(), game_control.ammo - game_control.live_balls.size())
		else:
			game_control.drag_enabled = false
