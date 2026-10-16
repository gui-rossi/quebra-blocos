extends Node

# Short sound effects synthesized at startup (no audio files), played on the SFX bus.
# To use a real file instead, put an AudioStream in _clips under the same name.

const MIX_RATE := 44100
const POOL_SIZE := 8  # how many sounds can overlap

var _clips := {}
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0

func _ready() -> void:
	for i in range(POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.bus = Settings.SFX_BUS
		add_child(player)
		_players.append(player)

	_clips["place"] = _make_clip(0.09, _place_sample)
	_clips["line_clear"] = _make_clip(0.4, _line_clear_sample)
	_clips["combo_up"] = _make_clip(0.3, _combo_up_sample)
	_clips["click"] = _make_clip(0.05, _click_sample)
	_clips["game_over"] = _make_clip(0.8, _game_over_sample)
	_clips["laser"] = _make_clip(0.35, _laser_sample)

func play(clip_name: String, pitch: float = 1.0) -> void:
	var clip = _clips.get(clip_name)
	if clip == null:
		return
	var player = _players[_next_player]
	_next_player = (_next_player + 1) % POOL_SIZE
	player.stream = clip
	player.pitch_scale = pitch
	player.play()

# ---------------- Synthesis ----------------

# Renders `duration` seconds of `sample_fn(t, progress) -> float` (-1..1) into a mono 16 bit clip
func _make_clip(duration: float, sample_fn: Callable) -> AudioStreamWAV:
	var count = int(duration * MIX_RATE)
	var data = PackedByteArray()
	data.resize(count * 2)
	for i in range(count):
		var t = float(i) / MIX_RATE
		var s = clampf(sample_fn.call(t, t / duration), -1.0, 1.0)
		data.encode_s16(i * 2, int(s * 32767.0))

	var clip = AudioStreamWAV.new()
	clip.format = AudioStreamWAV.FORMAT_16_BITS
	clip.mix_rate = MIX_RATE
	clip.stereo = false
	clip.data = data
	return clip

# Quick fade in, then a curved fade out to silence at the end
func _envelope(progress: float, attack: float = 0.02) -> float:
	return minf(progress / attack, 1.0) * pow(1.0 - progress, 2.0)

# Phase of a tone gliding linearly from f0 to f1 Hz over `duration`
func _glide_phase(t: float, f0: float, f1: float, duration: float) -> float:
	return TAU * (f0 * t + (f1 - f0) * t * t / (2.0 * duration))

# Soft wooden "thock" when a piece lands
func _place_sample(t: float, p: float) -> float:
	var body = sin(_glide_phase(t, 420.0, 170.0, 0.09)) * _envelope(p, 0.05) * 0.7
	var tap = randf_range(-1.0, 1.0) * pow(1.0 - p, 10.0) * 0.25
	return body + tap

# Bright chime for a cleared line (played higher as the combo grows)
func _line_clear_sample(t: float, p: float) -> float:
	var tone = sin(TAU * 880.0 * t) + 0.5 * sin(TAU * 1320.0 * t) + 0.25 * sin(TAU * 1760.0 * t)
	return tone * _envelope(p, 0.01) * 0.35

# Three rising notes when the multiplier goes up
func _combo_up_sample(t: float, p: float) -> float:
	var notes = [660.0, 880.0, 1100.0]
	var index = mini(int(p * 3.0), 2)
	var note_progress = p * 3.0 - index
	var wave = sin(TAU * notes[index] * t)
	var soft_square = signf(wave) * 0.3 + wave * 0.7
	return soft_square * _envelope(note_progress, 0.05) * 0.3

# UI button tick
func _click_sample(t: float, p: float) -> float:
	return sin(TAU * 1200.0 * t) * pow(1.0 - p, 4.0) * 0.4

# Laser zap: a buzzy tone sweeping down fast, with some crackle
func _laser_sample(t: float, p: float) -> float:
	var phase = fposmod(_glide_phase(t, 1900.0, 260.0, 0.35) / TAU, 1.0)
	var saw = phase * 2.0 - 1.0
	var crackle = randf_range(-1.0, 1.0) * 0.25 * (1.0 - p)
	return (saw * 0.55 + crackle) * _envelope(p, 0.01) * 0.35

# Slow falling tone when the run ends
func _game_over_sample(t: float, p: float) -> float:
	var phase = fposmod(_glide_phase(t, 440.0, 196.0, 0.8) / TAU, 1.0)
	var triangle = 4.0 * absf(phase - 0.5) - 1.0
	return triangle * _envelope(p, 0.02) * 0.4
