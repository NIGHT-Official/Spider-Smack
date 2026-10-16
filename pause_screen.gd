extends Control

func _ready():
	visible = false
	%Resume.pressed.connect(resume)
	%Sensitivity.value_changed.connect(set_sensitivity)

func set_sensitivity(value):
	get_node("/root/Main/Track/Follower/Car/Head").sensitivity = value

func _input(event):
	if get_tree().paused and not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		if visible:
			resume()
		else:
			pause()
	
func pause():
	visible = true
	get_tree().paused = true
	%Resume.grab_focus()
	
func resume():
	visible = false
	get_tree().paused = false
