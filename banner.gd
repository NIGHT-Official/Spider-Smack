extends Label

var fade = 0.7

func _ready():
	modulate.a = 0.0

func show_text(words):
	text = words
	modulate.a = 1.0

func _process(delta):
	modulate.a = move_toward(modulate.a, 0.0, fade * delta)
