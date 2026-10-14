extends Camera3D

var trauma = 0.0
var decay = 1.5
var max_shake = 0.15

func bump(strength):
	trauma = clamp(max(trauma, strength), 0.0, 1.0)

func _process(delta):
	trauma = move_toward(trauma, 0.0, decay * delta)
	var amount = trauma * trauma * max_shake
	h_offset = randf_range(-1.0, 1.0) * amount
	v_offset = randf_range(-1.0, 1.0) * amount
