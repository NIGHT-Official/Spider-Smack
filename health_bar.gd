extends ColorRect

var full_width = 200.0

func _process(_delta):
	var car = get_node("/root/Main/Track/Follower/Car")
	var fraction = car.health / 100.0
	size.x = full_width * fraction
	if fraction <= 0.40:
		color = Color.RED
	else:
		color = Color.GREEN
