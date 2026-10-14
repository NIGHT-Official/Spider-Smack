extends Node3D

var max_turn = 80.0
var max_up = 50.0
var max_down = 60.0
var min_down = 30.0
var follow_speed = 2.3
var degrees_per_pixel = 0.1
var dead_zone = 30.0
var swing_speed = 15.0
var edge_margin = 40.0
var edge_speed = 3.0
var turn = 0.0
var tilt = 0.0

func aim(step):
		turn -= step.x * degrees_per_pixel
		tilt -= step.y * degrees_per_pixel
		turn = clamp(turn, -max_turn, max_turn)
		var down_limit = lerp(max_down, min_down, abs(turn) / max_turn)
		tilt = clamp(tilt, -down_limit, max_up)

func _process(delta):
		var centre = get_viewport().get_visible_rect().size / 2
		var mouse = get_viewport().get_mouse_position()
		var offset = mouse - centre
		var glancing = Input.is_action_pressed("glance")
		if Input.is_action_pressed("ready"):
				var inner = centre - Vector2(edge_margin, edge_margin)
				var over = (offset.abs() - inner).max(Vector2.ZERO)
				aim(over * offset.sign() * edge_speed * delta)
		elif not glancing and offset.length() > dead_zone:
				var step = offset * follow_speed * delta
				aim(step)
		var want_turn = turn
		var want_tilt = tilt
		if glancing:
				want_turn = 0.0
				want_tilt = 0.0
		rotation_degrees.y = lerp(rotation_degrees.y, want_turn, swing_speed * delta)
		rotation_degrees.x = lerp(rotation_degrees.x, want_tilt, swing_speed * delta)
