extends PopupDialog

onready var tab_container = $MarginContainer/VBoxContainer/TabContainer

func _ready():
	var animation = Animation.new()
	var track_index = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_index, String(self.get_path()) + ":modulate:a")
	animation.track_insert_key(track_index, 0.0, 1.0)
	animation.track_insert_key(track_index, 0.3, 0.0)
	$AnimationPlayer.add_animation("fadeout", animation)
	$AnimationPlayer.connect("animation_finished", self, "on_Fadeout_finished")

func _on_CloseButton_pressed():
	$AnimationPlayer.play("fadeout")

func on_Fadeout_finished(_anim_name):
	hide()


func _on_NextButton_pressed():
	tab_container.current_tab += 1


func _on_PrevButton_pressed():
	tab_container.current_tab -= 1
