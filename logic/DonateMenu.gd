extends Popup


func _ready():
	pass

func _on_CloseButton_pressed():
	visible = false


func _on_LearnMeButton_toggled(button_pressed):
	OS.shell_open("https://github.com/claucambra")


func _on_LearnGodotButton_pressed():
	OS.shell_open("https://godotengine.org/")


func _on_MeDonateButton_pressed():
	OS.shell_open("https://liberapay.com/claucambra/")


func _on_GodotDonateButton_pressed():
	OS.shell_open("https://godotengine.org/donate")
