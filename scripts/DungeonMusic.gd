extends AudioStreamPlayer
class_name DungeonMusic

const SAMPLE_RATE := 22050

var enabled := true
var volume := 0.36

var _playback: AudioStreamGeneratorPlayback
var _time := 0.0
var _step := 0
var _step_time := 0.0
var _bass_phase := 0.0
var _drone_a := 0.0
var _drone_b := 0.0
var _spark_phase := 0.0
var _bass_note := 55.0
var _pattern := [0, 0, -5, 0, -7, -7, -3, -5, 0, 2, -5, -3, -8, -7, -5, -3]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = SAMPLE_RATE
	generator.buffer_length = 0.45
	stream = generator
	volume_db = linear_to_db(volume)
	play()
	_playback = get_stream_playback()
	_fill_buffer()


func _process(_delta: float) -> void:
	if not enabled or _playback == null:
		return
	if not playing:
		play()
		_playback = get_stream_playback()
	_fill_buffer()


func _fill_buffer() -> void:
	if _playback == null:
		return
	var frames := _playback.get_frames_available()
	for i in frames:
		_playback.push_frame(_next_frame())


func set_enabled(value: bool) -> void:
	enabled = value
	stream_paused = not value


func _next_frame() -> Vector2:
	var dt := 1.0 / SAMPLE_RATE
	_time += dt
	_step_time += dt
	if _step_time >= 0.38:
		_step_time = 0.0
		_step = (_step + 1) % _pattern.size()
		_bass_note = 55.0 * pow(2.0, float(_pattern[_step]) / 12.0)

	_bass_phase = fmod(_bass_phase + _bass_note * dt, 1.0)
	_drone_a = fmod(_drone_a + 41.2 * dt, 1.0)
	_drone_b = fmod(_drone_b + 61.7 * dt, 1.0)
	_spark_phase = fmod(_spark_phase + 220.0 * dt, 1.0)

	var envelope := exp(-_step_time * 4.2)
	var bass := sin(_bass_phase * TAU) * envelope * 0.7
	var drone := sin(_drone_a * TAU) * 0.18 + sin(_drone_b * TAU + sin(_time * 0.35) * 0.7) * 0.14
	var pulse := 0.0
	if _step % 4 == 0:
		pulse = sin(_spark_phase * TAU) * exp(-_step_time * 18.0) * 0.28

	var sample := tanh((bass + drone + pulse) * 1.35) * volume
	return Vector2(sample, sample)
