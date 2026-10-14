extends ColorRect

var fade = 2.0

func flash(strength):
	color.a = max(color.a, clamp(0.15 + strength, 0.0, 0.6))

func _process(delta):
	color.a = move_toward(color.a, 0.0, fade * delta)
