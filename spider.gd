extends Area3D

var patches = []
var crawl_speed = 0.25
var leap_speed = 1.2
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
var strike_after = 12.0
var strike_damage = 5.0
var lunge_speed = 4.0
var close_time = 0.0
var striking = false
var hide_after = 13.0
var retreat_speed = 1.0
var seen_time = 0.0
var growth = 1.08
var damage_step = 1.25
var links = {}
var link_distance = 0.1
var path = []
var final_spot = Vector3.ZERO
var final_normal = Vector3.UP
var goal_patch
var far_patches = []
var seek_chance = 0.38
var seek_speed = 0.25
var leaping = false
var leap_from = Vector3.ZERO
var leap_to = Vector3.ZERO
var leap_t = 0.0
var leap_length = 1.0
var leap_height = 0.0
var jump_arc = 0.35
var jump_max = 0.5
var edge_cache = {}
var on_patch


func _ready():
	patches = get_parent().get_node("Patches").get_children()
	for each in patches:
		each.hide()
	patch = patches[0]
	on_patch = patch
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

func edge_between(a_patch, b_patch, spot):
	var best = null
	var best_cost = 1000.0
	for p in edge_cache[a_patch]:
		for q in edge_cache[b_patch]:
			if p.distance_to(q) < link_distance:
				var mid = (p + q) / 2
				var cost = position.distance_to(mid) + mid.distance_to(spot)
				if cost < best_cost:
					best_cost = cost
					best = mid
	return best

func travel(spot, old_normal):
	var edge = null
	if on_patch != patch and edge_cache.has(on_patch):
		edge = edge_between(on_patch, patch, spot)
	if edge == null:
		var push = min(position.distance_to(spot) * bend, max_bend)
		var corner = (old_normal + normal) * (1.0 - old_normal.dot(normal))
		target = (position + spot) / 2 + corner * push
	else:
		target = edge + (old_normal + normal).normalized() * lift
	route = [spot]
	face(target - position, old_normal)

func start_leap(spot, old_normal):
	leaping = true
	leap_from = position
	leap_to = spot
	leap_t = 0.0
	leap_length = max(position.distance_to(spot), 0.05)
	leap_height = min(leap_length * jump_arc, jump_max)
	route = []
	path = []
	face(spot - position, old_normal)
	wait = 0.0

func leap():
	striking = false
	close_time = 0.0
	seen_time = 0.0
	var old_normal = normal
	patch = far_patches.pick_random()
	start_leap(next_spot(), old_normal)

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

func grow():
	crawl_speed *= growth
	seek_speed *= growth
	retreat_speed *= growth
	lunge_speed *= growth
	leap_speed *= growth
	strike_after /= growth
	hide_after /= growth
	seek_chance = min(seek_chance * growth, 0.9)
	hop_chance = min(hop_chance * growth, 0.9)
	strike_damage += damage_step

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
		get_parent().hurt(strike_damage, false)
		camera.bump(0.6)
		striking = false
		leaping = false
		close_time = 0.0
		patch = far_patches.pick_random()
		position = next_spot()
		on_patch = patch
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
		edge_cache[each] = edge_points(each)
	for first in patches:
		var mine = edge_cache[first]
		for second in patches:
			if second == first or links[first].has(second):
				continue
			if touches(mine, edge_cache[second]):
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
	start_leap(next_spot(), old_normal)

func seek():
	if goal_patch == null:
		wander()
		return
	var step = patch
	var crossing = false
	if goal_patch != patch:
		var way = find_path(patch, goal_patch)
		if way.size() == 0:
			jump_to(goal_patch)
			return
		step = way[0]
		crossing = true
	var old_normal = normal
	var head = get_parent().get_node("Head").position
	var anchor = head
	if crossing:
		anchor = position
	patch = step
	var best = next_spot()
	var best_normal = normal
	for i in 30:
		var spot = next_spot()
		if spot.distance_to(anchor) < best.distance_to(anchor):
			best = spot
			best_normal = normal
	if not crossing and best.distance_to(head) >= position.distance_to(head):
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
		if seen_time >= hide_after and not striking and not leaping:
			retreat()
	else:
		seen_time = 0.0
	basis = basis.orthonormalized().slerp(want, min(turn_speed * delta, 1.0)).orthonormalized()
	if leaping:
		leap_t += leap_speed * delta / leap_length
		var along = min(leap_t, 1.0)
		position = leap_from.lerp(leap_to, along) + Vector3.UP * leap_height * 4.0 * along * (1.0 - along)
		if leap_t >= 1.0:
			leaping = false
			on_patch = patch
			position = leap_to
			target = position
			wait = 0.3
		return
	if wait > 0.0:
		wait -= delta
		return
	position = position.move_toward(target, speed * delta)
	if position == target:
		if route.size() > 0:
			target = route.pop_front()
			face(target - position, normal)
			return
		on_patch = patch
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

func hand_hits():
	var hand = get_tree().root.get_node("Main/CanvasLayer/Hand")
	var camera = get_parent().get_node("Head/Camera3D")
	for step in [-1.0, 0.0, 1.0]:
		var point = global_position + global_transform.basis.z * 0.03 * step
		if camera.is_position_behind(point):
			continue
		var screen = camera.unproject_position(point)
		var side = camera.unproject_position(point + camera.global_transform.basis.x * 0.017)
		if hand.touches(screen, screen.distance_to(side)):
			return true
	return false

func _input(event):
	if event.is_action_released("ready") and is_seen(global_position) and hand_hits():
		leap()
