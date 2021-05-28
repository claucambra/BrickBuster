extends Popup


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


func _on_LearnMeButton_toggled(button_pressed):
	OS.shell_open("https://github.com/claucambra")


func _on_LearnGodotButton_pressed():
	OS.shell_open("https://godotengine.org/")


func _on_MeDonateButton_pressed():
	OS.shell_open("https://liberapay.com/claucambra/")


func _on_GodotDonateButton_pressed():
	OS.shell_open("https://godotengine.org/donate")
