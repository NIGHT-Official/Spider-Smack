extends Node2D

var radius = 14.0
var squash = 1.6

func _process(_delta):
	visible = Input.is_action_pressed("ready")
	position = get_viewport().get_mouse_position()

func _draw():
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(squash, 1.0))
	draw_circle(Vector2.ZERO, radius, Color(1.0, 0.8, 0.7, 0.85))

func touches(point, pad):
	var local = point - position
	var across = radius * squash + pad
	var down = radius + pad
	return pow(local.x / across, 2) + pow(local.y / down, 2) <= 1.0
