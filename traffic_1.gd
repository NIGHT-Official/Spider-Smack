extends PathFollow3D

@export var speed := 8.0
var cruise = 0.0
var stun = 0.0
var direction = 1.0
var accel = 3.0
var brake = 8.0
var min_speed = 4.0
var look = 45.0
var safe_gap = 9.0

func _ready():
	cruise = speed
	if direction > 0.0:
		speed = cruise * randf_range(0.5, 1.0)
	accel = randf_range(1.5, 5.0)
	brake = randf_range(6.0, 12.0)
	min_speed = min(randf_range(3.0, 6.0), cruise)
	add_to_group("traffic")

func wanted_speed(follower, car):
	var best = look
	var lead_speed = 0.0
	var lead_is_player = false
	for other in get_tree().get_nodes_in_group("traffic"):
		if other == self or other.direction != direction:
			continue
		if abs(other.get_node("Body").position.x - $Body.position.x) > 2.2:
			continue
		var ahead = (other.progress - progress) * direction
		if ahead > 0.0 and ahead < best:
			best = ahead
			lead_speed = other.speed
			lead_is_player = false
	if direction > 0.0:
		var ahead_player = follower.progress - progress
		if ahead_player > 0.0 and ahead_player < best and abs(car.position.x - $Body.position.x) < 2.2:
			best = ahead_player
			lead_speed = follower.speed
			lead_is_player = true
	var want = cruise
	if best < look:
		want = clamp(lead_speed + (best - safe_gap) * 0.5, 0.0, cruise)
		if lead_is_player:
			want = max(want, min(min_speed, cruise))
	return want

func _process(delta):
	var follower = get_parent().get_node("Follower")
	var car = follower.get_node("Car")
	if stun > 0.0:
		stun -= delta
		speed = move_toward(speed, 0.0, 20.0 * delta)
	else:
		var want = wanted_speed(follower, car)
		var rate = accel
		if want < speed:
			rate = brake
		speed = move_toward(speed, want, rate * delta)
	progress += speed * direction * delta
	var gap = progress - follower.progress
	if gap < -60.0:
		queue_free()
		return
	var side = $Body.position.x - car.position.x
	var overlap_along = 4.0 - abs(gap)
	var overlap_side = 1.8 - abs(side)
	if overlap_along > 0.0 and overlap_side > 0.0:
		if direction < 0.0:
			var closing = follower.speed + speed
			if overlap_along < overlap_side:
				car.hurt(closing) 
				car.get_node("Head/Camera3D").bump(closing / 30.0)
				follower.speed *= 0.3
				queue_free()
			else:
				car.position.x = $Body.position.x -1.8 * sign(side)
				car.hurt(closing * 0.05)
			return
		var impact = follower.speed - speed
		if impact > 2.0: car.get_node("Head/Camera3D").bump(impact / 30.0)
		if overlap_along < overlap_side:
			if gap < 0.0 and speed > follower.speed:
				var shove = speed - follower.speed 
				follower.progress = progress + 4.0
				follower.speed = speed + shove * 0.5
				car.angle -= clamp(side / 1.8, -1.0, 1.0) * shove * 0.16 
				car.get_node("Head/Camera3D").bump(shove / 30.0)
				car.hurt(shove * 0.5)
				stun = 1.5
			else:
				follower.progress = progress - 4.0 * sign(gap)
				follower.speed = min(follower.speed, max(speed, 0.0))
				if impact > 2.0: car.hurt(impact)
		else:
			car.position.x = $Body.position.x - 1.8 * sign(side)
			if impact > 2.0: car.hurt(impact * 0.05)
