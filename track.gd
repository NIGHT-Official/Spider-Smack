extends Path3D

var dash_length = 4
var lane_width = 3.4

func _ready():
	var mesh = PlaneMesh.new()
	mesh.size = Vector2(0.3, dash_length)
	var paint = StandardMaterial3D.new()
	paint.albedo_color = Color.WHITE
	mesh.material = paint
	
	var lanes = [-lane_width, lane_width]
	var distance = 0.0
	while distance < curve.get_baked_length():
		
		var here = curve.sample_baked(distance) + Vector3(0, 0.02,0)
		var ahead = curve.sample_baked(distance + 1.0) + Vector3(0, 0.02, 0)
		var side = (ahead - here).normalized().cross(Vector3.UP)
		for lane in lanes:
			var dash = MeshInstance3D.new()
			dash.mesh = mesh
			add_child(dash)
			dash.position = here + side * lane
			dash.look_at(ahead + side * lane)
			distance += 8.0
		
