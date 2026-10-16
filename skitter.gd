extends AudioStreamPlayer3D

func make_skitter():
	var rate = 22050
	var count = rate
	var size = 150
	var clicks = 14
	var slot = float(count - size) / clicks
	var data = PackedByteArray()
	data.resize(count * 2)
	for k in clicks:
		var start = int((k + randf_range(0.0, 0.7)) * slot)
		var loud = randf_range(0.4, 0.9)
		var last = 0.0
		for j in size:
			var fade = 1.0 - float(j) / size
			var noise = randf_range(-1.0, 1.0)
			var wave = (noise - last) * 0.8 * fade * fade
			last = noise
			data.encode_s16((start + j) * 2, int(wave * loud * 32000))
	var sound = AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = rate
	sound.data = data
	sound.loop_mode = AudioStreamWAV.LOOP_FORWARD
	sound.loop_begin = 0
	sound.loop_end = count
	return sound

func _ready():
	stream = make_skitter()
	volume_db = 0.0

func _process(_delta):
	var spider = get_parent()
	var moving = spider.wait <= 0.0 and spider.position != spider.target
	moving = moving and not spider.leaping and not spider.striking
	if moving and not playing:
		play()
	elif not moving and playing:
		stop()
	pitch_scale = 0.9 + spider.speed * 0.8
