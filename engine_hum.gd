extends AudioStreamPlayer

func make_hum():
	var rate = 2205
	var count = rate
	var data = PackedByteArray()
	data.resize((count + 8) * 2)
	var smooth = 0.0
	var inputs = []
	for i in count:
		inputs.append(randf_range(-1.0, 1.0))
	for i in count:
		smooth = smooth * 0.9 + inputs[i] * 0.1
	for i in count + 8:
		var t = float(i) / rate
		smooth = smooth * 0.9 + inputs[i % count] * 0.1
		var wave = sin(TAU * 60.0 * t)
		wave += sin(TAU * 120.0 * t) * 0.6
		wave += smooth * 1.5
		wave *= 0.7 + 0.3 * sin(TAU * 12.0 * t)
		data.encode_s16(i * 2, int(clamp(wave * 0.4, -1.0, 1.0) * 32000))
	var sound = AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = rate
	sound.data = data
	sound.loop_mode = AudioStreamWAV.LOOP_FORWARD
	sound.loop_begin = 0
	sound.loop_end = count
	return sound

func _ready():
	stream = make_hum()
	volume_db = -20.0
	play()

func _process(delta):
	var speed = get_node("/root/Main/Track/Follower").speed
	var want = 0.8 + speed * 0.02
	pitch_scale = move_toward(pitch_scale, want, 0.5 * delta)
