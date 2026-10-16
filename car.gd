extends Node3D

var turn_rate = 0.5
var max_angle = 0.5
var road_edge = 5.9
var angle = 0.0
var health = 100.0

func _process(delta):
	var follower = get_parent()
	var steer = Input.get_axis("steer left", "steer right")
	angle -= steer * turn_rate * delta
	angle -= follower.turned
	angle = clamp(angle, -max_angle, max_angle)
	rotation.y = angle
	position.x -= sin(angle) * follower.speed * delta
	position.x = clamp(position.x, -road_edge, road_edge)

func hurt(amount, crash = true):
	health -= amount
	health = max(health, 0.0)
	get_node("/root/Main/CanvasLayer/Flash").flash(amount / 20.0)
	print("Health: ", health)
	if crash:
		get_node("/root/Main/Crash").thud(amount)
	if health <= 0.0:
		get_node("/root/Main/CanvasLayer/GameOver").show_over()

func heal(amount):
	health = min(health + amount, 100.0)

func drain(amount):
	health = max(health - amount, 0.0)
	if health <= 0.0:
		get_tree().reload_current_scene()
