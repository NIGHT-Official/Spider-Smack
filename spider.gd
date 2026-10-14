extends Area3D

var patches = []
var crawl_speed = 0.3
var leap_speed = 3.0
var speed = 0.3
var patch
var target = Vector3.ZERO
var wait = 0.0
var turn_speed = 6.0
var hop_chance = 0.3
var hop_range = 0.4
var lift = 0.015
var normal = Vector3.UP
var want = Basis()
var route = []
var bend = 0.5
var max_bend = 0.5
var facing = 0.0
var strike_range = 0.8
var strike_after = 4.0
var strike_damage = 20.0
var lunge_speed = 4.0
var close_time = 0.0
var striking = false
var hide_after = 6.0
var retreat_speed = 1.0
var seen_time = 0.0
var links = {}
var link_distance = 0.1
var path = []
var final_spot = Vector3.ZERO
var final_normal = Vector3.UP
var goal_patch
var far_patches = []
var seek_chance = 0.8
var seek_speed = 0.5

func _ready():
	patches = get_parent().get_node("Patches").get_children()
	for each in patches:
		each.hide()
	patch = patches[0]
	position = next_spot()
	target = position
	build_links()
	goal_patch = find_goal()
	far_patches = find_far()

func next_spot():
	var points = patch.polygon
	var low = points[0]
	var high = points[0]
	for point in points:
		low = low.min(point)
		high = high.max(point)
	var spot = Vector2(randf_range(low.x, high.x), randf_range(low.y, high.y))
	while not Geometry2D.is_point_in_polygon(spot, points):
		spot = Vector2(randf_range(low.x, high.x), randf_range(low.y, high.y))
	var on_patch = patch.transform * Vector3(spot.x, spot.y, -patch.depth / 2)
	normal =  patch.transform.basis.z.normalized()
	var head = get_parent().get_node("Head").position
	if normal.dot(head - on_patch) < 0.0:
		normal = -normal
	return on_patch + normal * lift

func face(direction, up):
	var flat = direction - normal * direction.dot(up)
	if flat.length() > 0.001:
		want = Basis.looking_at(flat, up)

func wander():
	target = next_spot()
	face(target - position, normal)

func travel(spot, old_normal):
	var push = min(position.distance_to(spot) * bend, max_bend)
	var corner = (old_normal + normal) * (1.0 - old_normal.dot(normal))
	target = (position + spot) / 2 + corner * push
	route = [spot]
	face(target - position, old_normal)

func leap():
	striking = false
	close_time = 0.0
	seen_time = 0.0
	var old_normal = normal
	patch = far_patches.pick_random()
	travel(next_spot(), old_normal)
	speed = leap_speed
	wait = 0.0

func hop():
	var old = patch
	var old_normal = normal
	for attempt in 100:
		patch = patches.pick_random()
		var spot = next_spot()
		if patch != old and links[old].has(patch) and position.distance_to(spot) < hop_range:
			travel(spot, old_normal)
			return
	patch = old
	wander()

func is_seen(point):
	var camera = get_parent().get_node("Head/Camera3D")
	if not camera.is_position_in_frustum(point):
		return false
	var from = camera.global_position
	var to = point + (from - point).normalized() * 0.05
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var hit = get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty()

func lunge(camera, delta):
	var aim = camera.global_position - camera.global_transform.basis.z * 0.35
	global_position = global_position.move_toward(aim, lunge_speed * delta)
	var toward = Basis.looking_at(camera.global_position - global_position, Vector3.UP)
	global_transform.basis = global_transform.basis.orthonormalized().slerp(toward, min(turn_speed * delta, 1.0)).orthonormalized()
	if global_position.distance_to(aim) < 0.02:
		get_parent().hurt(strike_damage)
		camera.bump(0.6)
		striking = false
		close_time = 0.0
		patch = far_patches.pick_random()
		position = next_spot()
		target = position
		route = []
		wait = 1.0

func retreat():
	seen_time = 0.0
	var old = patch
	var old_normal = normal
	for attempt in 100:
		var goal = patches.pick_random()
		var way = find_path(old, goal)
		if goal != old and way.size() == 0:
			continue
		patch = goal
		var spot = next_spot()
		if not is_seen(get_parent().to_global(spot)):
			path = way
			final_spot = spot
			final_normal = normal
			patch = old
			normal = old_normal
			speed = retreat_speed
			wait = 0.0
			follow_path()
			return
	patch = old
	normal = old_normal
	route = []
	wander()

func edge_points(each):
	var result = []
	var points = each.polygon
	for i in points.size():
		var a = points[i]
		var b = points[(i + 1) % points.size()]
		var steps = int(a.distance_to(b) / 0.05) + 1
		for s in steps:
			var spot = a.lerp(b, float(s) / steps)
			result.append(each.transform * Vector3(spot.x, spot.y, -each.depth / 2))
	return result

func touches(a, b):
	for p in a:
		for q in b:
			if p.distance_to(q) < link_distance:
				return true
	return false

func build_links():
	for each in patches:
		links[each] = []
	for first in patches:
		var mine = edge_points(first)
		for second in patches:
			if second == first or links[first].has(second):
				continue
			if touches(mine, edge_points(second)):
				links[first].append(second)
				links[second].append(first)

func find_path(from_patch, to_patch):
	var came = {from_patch: null}
	var queue = [from_patch]
	while queue.size() > 0:
		var here = queue.pop_front()
		if here == to_patch:
			var result = []
			while here != from_patch:
				result.push_front(here)
				here = came[here]
			return result
		for next in links[here]:
			if not came.has(next):
				came[next] = here
				queue.append(next)
	return []

func follow_path():
	var old_normal = normal
	if path.size() > 1:
		patch = path.pop_front()
		var best = next_spot()
		var best_normal = normal
		for i in 30:
			var spot = next_spot()
			if spot.distance_to(position) < best.distance_to(position):
				best = spot
				best_normal = normal
		normal = best_normal
		travel(best, old_normal)
	else:
		if path.size() == 1:
			patch = path.pop_front()
		normal = final_normal
		travel(final_spot, old_normal)

func find_goal():
	var head = get_parent().get_node("Head").position
	var best = null
	var best_distance = 1000.0
	for each in patches:
		if each != patches[0] and find_path(patches[0], each).size() == 0:
			continue
		for point in edge_points(each):
			var d = point.distance_to(head)
			if d < best_distance:
				best_distance = d
				best = each
	print("seek goal: ", best.name, " ", best_distance)
	return best

func find_far():
	var head = get_parent().get_node("Head").position
	var scored = []
	for each in patches:
		var nearest = 1000.0
		for point in edge_points(each):
			nearest = min(nearest, point.distance_to(head))
		scored.append([nearest, each])
	scored.sort_custom(func(a, b): return a[0] > b[0])
	var result = []
	for i in 6:
		result.append(scored[i][1])
	return result

func jump_to(goal):
	var old_normal = normal
	patch = goal
	route = []
	travel(next_spot(), old_normal)
	speed = leap_speed
	wait = 0.0

func seek():
	if goal_patch == null:
		wander()
		return
	var step = patch
	if goal_patch != patch:
		var way = find_path(patch, goal_patch)
		if way.size() == 0:
			jump_to(goal_patch)
			return
		step = way[0]
	var old_normal = normal
	var head = get_parent().get_node("Head").position
	patch = step
	var best = next_spot()
	var best_normal = normal
	for i in 12:
		var spot = next_spot()
		if spot.distance_to(head) < best.distance_to(head):
			best = spot
			best_normal = normal
	if step == goal_patch and best.distance_to(head) >= position.distance_to(head):
		return
	normal = best_normal
	route = []
	travel(best, old_normal)
	speed = seek_speed

func _process(delta):
	var camera = get_parent().get_node("Head/Camera3D")
	if striking:
		lunge(camera, delta)
		return
	var seen = is_seen(global_position)
	var close = global_position.distance_to(camera.global_position)
	if close < strike_range:
		close_time += delta
		if close_time >= strike_after:
			striking = true
	else:
		close_time = 0.0
	if seen:
		seen_time += delta
		if seen_time >= hide_after and not striking:
			retreat()
	else:
		seen_time = 0.0
	basis = basis.orthonormalized().slerp(want, min(turn_speed * delta, 1.0)).orthonormalized()
	if wait > 0.0:
		wait -= delta
		return
	position = position.move_toward(target, speed * delta)
	if position == target:
		if route.size() > 0:
			target = route.pop_front()
			face(target - position, normal)
			return
		if path.size() > 0:
			follow_path()
			return
		speed = crawl_speed
		if randf() < seek_chance:
			seek()
		elif randf() < hop_chance:
			hop()
		else:
			wander()
		wait = randf_range(0.2, 1.5)

func _input_event(_camera, event, _position, _normal, _shape):
	if event.is_action_released("ready"):
			leap()
