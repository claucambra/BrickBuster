extends Node2D

onready var game_control = get_tree().get_root().get_node("MainGame")

func _ready():
	pass

func _process(delta):
	update() # Update _draw

func _draw():
	if game_control.drag_enabled && game_control.draw_touch_marker:
		# Touch/click marker
		draw_circle(game_control.first_click_position, 25, ColorN("white", 0.5))
