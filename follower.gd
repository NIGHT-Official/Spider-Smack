extends PathFollow3D

var speed = 0.0
var top_speed = 20.0
var acceleration = 6.0
var braking = 10.0
var drag = 2.0
var look_distance = 8.0
var heading = 0.0
var turned = 0.0

func _process(delta):
	if Input.is_action_pressed("accelerate"):
		speed += acceleration * delta
	elif Input.is_action_pressed("brake"):
		speed -= braking * delta
	else: 
		speed -= drag * delta
	speed = clamp(speed, 0.0, top_speed)
	progress += speed * delta
	var curve = get_parent().curve
	var behind = curve.sample_baked(progress - look_distance)
	var ahead = curve.sample_baked(progress + look_distance)
	var direction = ahead - behind
	var target = atan2(-direction.x, -direction.z)
	turned = angle_difference(heading, target)
	heading = target
	rotation.y = target
	
	
	
