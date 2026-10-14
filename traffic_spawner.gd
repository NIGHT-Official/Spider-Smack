extends Node

var car_scene = preload("res://traffic_1.tscn")
var spawn_ahead = 120.0
var max_cars = 50
var timer = 0.0
var want_same = 9
var want_oncoming = 12


func _process(delta):
	timer -= delta
	if timer > 0.0:
		return
	timer = 0.1
	var follower = get_parent().get_node("Follower")
	var same = 0
	var oncoming = 0
	for each in get_tree().get_nodes_in_group("traffic"):
		var gap = each.progress - follower.progress
		if gap > 0.0 and gap < spawn_ahead + 40.0:
			if each.direction < 0.0:
				oncoming += 1
			else:
				same += 1
	var at = follower.progress + spawn_ahead + randf_range(0.0, 40.0)
	if oncoming < want_oncoming:
		spawn_at(at, [-5.1, -1.7])
	elif same < want_same:
		spawn_at(at, [1.7, 5.1])

func _ready():
	populate.call_deferred()

func populate():
	for i in want_oncoming:
		spawn_at(randf_range(25.0, spawn_ahead + 40.0), [-5.1, -1.7])
	for i in want_same:
		spawn_at(randf_range(25.0, spawn_ahead + 40.0), [1.7, 5.1])

func spawn_at(at, choices):
	var track = get_parent()
	if get_tree().get_nodes_in_group("traffic").size() >= max_cars:
		return
	if at > track.curve.get_baked_length() - 10.0:
		return
	var lane = choices.pick_random()
	var near = 0
	for other in get_tree().get_nodes_in_group("traffic"):
		var apart = abs(other.progress - at)
		if other.get_node("Body").position.x == lane and apart < 15.0:
			return
		if apart < 10.0:
			near += 1
	if near >= 3:
		return
	var car = car_scene.instantiate()
	car.direction = -1.0 if lane < 0.0 else 1.0
	if car.direction < 0.0:
		car.speed = randf_range(12.0, 22.0)
	else:
		car.speed = randf_range(8.0, 22.0)
	track.add_child(car)
	car.get_node("Body").position.x = lane
	car.progress = at
