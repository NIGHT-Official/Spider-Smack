extends ProgressBar

var level = 1
var goal = 600.0
var goal_growth = 150.0
var level_start = 0.0

func _ready():
	max_value = goal
	value = 0.0

func _process(_delta):
	var travelled = get_node("/root/Main/Track/Follower").travelled
	value = travelled - level_start
	if value >= goal:
		level_up(travelled)

func level_up(travelled):
	level += 1
	level_start = travelled
	goal += goal_growth
	max_value = goal
	$Label.text = "LEVEL " + str(level)
	get_node("/root/Main/CanvasLayer/Banner").show_text("LEVEL " + str(level))
	get_node("/root/Main/CanvasLayer/GreenFlash").flash(0.3)
	get_node("/root/Main/Track/Follower/Car").heal(15.0)
	get_node("/root/Main/Track/Follower/Car/Spider").grow()
