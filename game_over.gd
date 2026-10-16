extends Control

func _ready():
	visible = false
	%Restart.pressed.connect(restart)

func show_over():
	visible = true
	get_tree().paused = true
	%Restart.grab_focus()

func restart():
	get_tree().paused = false
	get_tree().reload_current_scene()
