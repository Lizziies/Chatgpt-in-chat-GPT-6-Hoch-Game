extends Node
## Standalone offline synthesized sound: generates samples in RAM, not user files.
class_name VoidAudio

const SAMPLE_RATE: int = 22050
var effect_player: AudioStreamPlayer
var drone: AudioStreamPlayer
var enabled: bool = true
var cache: Dictionary = {}

func _ready() -> void:
	effect_player = AudioStreamPlayer.new()
	effect_player.volume_db = -12.0
	add_child(effect_player)
	drone = AudioStreamPlayer.new()
	drone.volume_db = -30.0
	add_child(drone)
	cache["build"] = _make_wave(410.0, 0.17, false)
	cache["research"] = _make_wave(580.0, 0.33, false)
	cache["alarm"] = _make_wave(125.0, 0.42, false)
	cache["combat"] = _make_wave(165.0, 0.15, false)
	cache["prestige"] = _make_wave(265.0, 0.55, false)
	cache["belt"] = _make_wave(305.0, 0.13, false)
	drone.stream = _make_wave(55.0, 1.5, true)
	drone.play()

func _make_wave(frequency: float, seconds: float, looping: bool) -> AudioStreamWAV:
	var count: int = int(float(SAMPLE_RATE) * seconds)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in range(count):
		var time: float = float(i) / float(SAMPLE_RATE)
		var envelope: float = 0.42 if looping else pow(maxf(0.0, 1.0 - time / seconds), 2.2)
		var sample: float = sin(TAU * frequency * time)
		sample += 0.27 * sin(TAU * frequency * 1.51 * time)
		sample += 0.10 * sin(TAU * frequency * 2.02 * time)
		var value: int = clampi(int(sample * envelope * 15000.0), -32767, 32767)
		bytes.encode_s16(i * 2, value)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = bytes
	if looping:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = count
	return wav

func play_event(event_name: String) -> void:
	if enabled and cache.has(event_name):
		effect_player.stream = cache[event_name]
		effect_player.play()

func toggle_audio() -> void:
	enabled = not enabled
	effect_player.stream_paused = not enabled
	drone.stream_paused = not enabled

func set_volume(value: float) -> void:
	var scaled: float = clampf(value, 0.0, 1.0)
	effect_player.volume_db = linear_to_db(maxf(scaled, 0.0001)) - 8.0
	drone.volume_db = linear_to_db(maxf(scaled, 0.0001)) - 25.0
