extends Node

## ASMR Audio Manager for The Grand Eggsposition.
## Handles tactile velvet snaps, clicks, Lo-Fi music fading, and chime feedback.
## Includes procedural audio fallbacks so feedback sounds function out-of-the-box.

var snap_stream: AudioStreamWAV
var tap_stream: AudioStreamWAV
var chime_stream: AudioStreamWAV
var harp_stream: AudioStreamWAV

func _ready() -> void:
	_generate_procedural_sounds()

## Plays the calibrated 180 Hz tactile velvet snap when an egg slots into a showcase.
func play_snap(pos: Vector3 = Vector3.ZERO) -> void:
	var player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	player.stream = snap_stream
	player.bus = &"Master"
	# Pitch modulation avoids auditory fatigue across 3,600 placements
	player.pitch_scale = randf_range(0.97, 1.03)
	player.unit_size = 12.0
	player.max_distance = 35.0
	add_child(player)
	if pos != Vector3.ZERO:
		player.global_position = pos
	player.play()
	player.finished.connect(player.queue_free)

## Plays a dry wood tap when an egg is picked up from the floor or table.
func play_pick_tap(pos: Vector3 = Vector3.ZERO) -> void:
	var player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	player.stream = tap_stream
	player.bus = &"Master"
	player.pitch_scale = randf_range(0.95, 1.05)
	player.unit_size = 8.0
	add_child(player)
	if pos != Vector3.ZERO:
		player.global_position = pos
	player.play()
	player.finished.connect(player.queue_free)

## Plays a bright resonant chime (used for Resonance Chime [Q] and secrets).
func play_chime(pos: Vector3 = Vector3.ZERO) -> void:
	var player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	player.stream = chime_stream
	player.bus = &"Master"
	player.unit_size = 20.0
	add_child(player)
	if pos != Vector3.ZERO:
		player.global_position = pos
	player.play()
	player.finished.connect(player.queue_free)

## Plays the C Major arpeggio chord when completing a full dozen (12/12).
func play_dozen_harp(pos: Vector3 = Vector3.ZERO) -> void:
	var player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	player.stream = harp_stream
	player.bus = &"Master"
	player.unit_size = 30.0
	add_child(player)
	if pos != Vector3.ZERO:
		player.global_position = pos
	player.play()
	player.finished.connect(player.queue_free)

# --- Procedural Audio Synthesizers for Instant In-Engine Audio ---

func _generate_procedural_sounds() -> void:
	snap_stream = _create_damped_sine(180.0, 0.18, 0.8)
	tap_stream = _create_damped_sine(440.0, 0.08, 0.6)
	chime_stream = _create_damped_sine(880.0, 0.7, 0.5)
	harp_stream = _create_arpeggio([523.25, 659.25, 783.99, 1046.5], 0.8)

func _create_damped_sine(freq: float, duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate: int = 44100
	var total_samples: int = int(duration * sample_rate)
	var data: PackedByteArray = PackedByteArray()
	data.resize(total_samples * 2) # 16-bit PCM mono
	
	for i in range(total_samples):
		var t: float = float(i) / float(sample_rate)
		var decay: float = exp(-t * (6.0 / duration))
		var sample: float = sin(2.0 * PI * freq * t) * decay * volume
		var val16: int = clampi(int(sample * 32767.0), -32768, 32767)
		data.encode_s16(i * 2, val16)
		
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

func _create_arpeggio(frequencies: Array, duration: float) -> AudioStreamWAV:
	var sample_rate: int = 44100
	var total_samples: int = int(duration * sample_rate)
	var data: PackedByteArray = PackedByteArray()
	data.resize(total_samples * 2)
	
	var note_duration: float = duration / float(frequencies.size())
	
	for i in range(total_samples):
		var t: float = float(i) / float(sample_rate)
		var note_idx: int = clampi(int(t / note_duration), 0, frequencies.size() - 1)
		var freq: float = frequencies[note_idx]
		var note_t: float = t - (float(note_idx) * note_duration)
		var decay: float = exp(-note_t * 5.0)
		var sample: float = sin(2.0 * PI * freq * note_t) * decay * 0.7
		var val16: int = clampi(int(sample * 32767.0), -32768, 32767)
		data.encode_s16(i * 2, val16)
		
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream
