extends Node2D

onready var game_control = get_tree().get_root().get_node("MainGame")


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var launch_cooldown_timer = Timer.new()
var countdown_label = Label.new()
var launch_cooling_down = false
var blocks_moving = false

func on_launch_cooldown_timer_timeout():
	launch_cooling_down = false
	blocks_moving = true

# Called when the node enters the scene tree for the first time.
func _ready():
	launch_cooling_down = true
	launch_cooldown_timer.connect("timeout", self, "on_launch_cooldown_timer_timeout")
	launch_cooldown_timer.wait_time = 3
	launch_cooldown_timer.autostart = true
	launch_cooldown_timer.one_shot = true
	add_child(launch_cooldown_timer)
	add_child(countdown_label)
	countdown_label.anchor_left = 50
	countdown_label.anchor_top = 50
	game_control.new_destroyable_line(0 + 1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !game_control.game_over:
		if blocks_moving:
			for live_destroyable in game_control.get_children():
				if "Brick" in live_destroyable.name or "Special" in live_destroyable.name:
					live_destroyable.position.y += 1
		var last_destroyable = game_control.live_destroyables[game_control.live_destroyables.size() - 1]
		if last_destroyable.position.y >= $Column0.get_point_position(1).y:
			game_control.new_destroyable_line(0 + 1)
		
		if !launch_cooling_down && game_control.live_balls.size() != game_control.ammo:
			game_control.drag_enabled = true
			countdown_label.visible = false
			if Input.is_action_just_released("click") && game_control.reasonable_angle:
				game_control.launch_balls(game_control.line_direction.normalized(), game_control.ammo - game_control.live_balls.size())
		else:
			game_control.drag_enabled = false
			if launch_cooldown_timer.time_left > 0:
				game_control.high_score_label.text = String(launch_cooldown_timer.time_left)
				countdown_label.visible = true
			else:
				countdown_label.visible = false
