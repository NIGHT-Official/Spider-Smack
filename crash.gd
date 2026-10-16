extends AudioStreamPlayer

func make_thud():
	var rate = 22050     
   
	var length = 0.4
	var count = int(rate * length)
	var data = PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var t = float(i) / rate
		var fade = 1.0 - t / length
		var wave = sin(TAU * 70.0 * t) * fade
		wave += randf_range(-1.0, 1.0) * 0.3 * fade
		data.encode_s16(i * 2, int(clamp(wave, -1.0, 1.0) * 32000))
	var sound = AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = rate
	sound.data = data
	return sound

func _ready():
	stream = make_thud()

func thud(amount):
	if playing:
		return
	volume_db = linear_to_db(clamp(amount / 20.0, 0.15, 1.0))
	play()
