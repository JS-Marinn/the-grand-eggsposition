extends Node

## ASMR Audio Manager for The Grand Eggsposition.
## Handles tactile velvet snaps, clicks, Lo-Fi music fading, and chime feedback.
## Includes procedural audio fallbacks so feedback sounds function out-of-the-box.

signal sound_played(sound_name: String, pos: Vector3)

var snap_stream: AudioStreamWAV
var tap_stream: AudioStreamWAV
var chime_stream: AudioStreamWAV
var harp_stream: AudioStreamWAV
var ui_hover_stream: AudioStreamWAV
var ui_click_stream: AudioStreamWAV
var slide_stream: AudioStreamWAV
var suction_stream: AudioStreamWAV
var page_turn_stream: AudioStreamWAV
var wax_stamp_stream: AudioStreamWAV

func _ready() -> void:
	_generate_procedural_sounds()


## Plays an ultra-soft wood tick on button hover
func play_ui_hover() -> void:
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = ui_hover_stream
	player.bus = &"Master"
	player.volume_db = -8.0
	player.pitch_scale = randf_range(0.98, 1.02)
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

## Plays a damped tactile velvet click on button press
func play_ui_click() -> void:
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = ui_click_stream
	player.bus = &"Master"
	player.volume_db = -4.0
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

## Plays the calibrated 180 Hz tactile velvet snap when an egg slots into a showcase.
func play_snap(pos: Vector3 = Vector3.ZERO) -> void:
	sound_played.emit("snap", pos)
	var player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	player.stream = snap_stream
	player.bus = &"Master"
	if SettingsManager.soft_continuous_sfx:
		player.volume_db -= 4.0
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
	sound_played.emit("pick_tap", pos)
	var player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	player.stream = tap_stream
	player.bus = &"Master"
	if SettingsManager.soft_continuous_sfx:
		player.volume_db -= 4.0
	player.pitch_scale = randf_range(0.95, 1.05)
	player.unit_size = 8.0
	add_child(player)
	if pos != Vector3.ZERO:
		player.global_position = pos
	player.play()
	player.finished.connect(player.queue_free)

## Plays a bright resonant chime (used for Resonance Chime [Q] and secrets).
func play_chime(pos: Vector3 = Vector3.ZERO) -> void:
	sound_played.emit("chime", pos)
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
	sound_played.emit("dozen_harp", pos)
	var player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	player.stream = harp_stream
	player.bus = &"Master"
	player.unit_size = 30.0
	add_child(player)
	if pos != Vector3.ZERO:
		player.global_position = pos
	player.play()
	player.finished.connect(player.queue_free)

## Plays a soft velvet fabric friction slide when performing a Velvet Dash.
func play_velvet_slide(pos: Vector3 = Vector3.ZERO) -> void:
	sound_played.emit("velvet_slide", pos)
	var player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	player.stream = slide_stream
	player.bus = &"Master"
	if SettingsManager.soft_continuous_sfx:
		player.volume_db -= 4.0
	player.unit_size = 10.0
	player.pitch_scale = randf_range(0.96, 1.04)
	add_child(player)
	if pos != Vector3.ZERO:
		player.global_position = pos
	player.play()
	player.finished.connect(player.queue_free)

## Plays a gentle air swirl when activating Sweep Suction on a batch of eggs.
func play_suction_swirl(pos: Vector3 = Vector3.ZERO) -> void:
	sound_played.emit("suction_swirl", pos)
	var player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	player.stream = suction_stream
	player.bus = &"Master"
	if SettingsManager.soft_continuous_sfx:
		player.volume_db -= 4.0
	player.unit_size = 12.0
	add_child(player)
	if pos != Vector3.ZERO:
		player.global_position = pos
	player.play()
## Plays a tactile crisp paper/parchment turn when flipping journal tabs
func play_page_turn() -> void:
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = page_turn_stream
	player.bus = &"Master"
	player.volume_db = -5.0
	player.pitch_scale = randf_range(0.95, 1.05)
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

## Plays a heavy dampened stamp sound with sizzling hot wax when stamping a seal
func play_wax_stamp() -> void:
	sound_played.emit("wax_stamp", Vector3.ZERO)
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = wax_stamp_stream
	player.bus = &"Master"
	player.volume_db = -2.0
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)


# --- Procedural Audio Synthesizers for Instant In-Engine Audio ---

func _generate_procedural_sounds() -> void:
	snap_stream = _create_damped_sine(180.0, 0.18, 0.8)
	tap_stream = _create_damped_sine(440.0, 0.08, 0.6)
	chime_stream = _create_damped_sine(528.0, 0.8, 0.6) # 528 Hz tuning-fork chime
	harp_stream = _create_arpeggio([523.25, 659.25, 783.99, 1046.5], 0.8)
	ui_hover_stream = _create_damped_sine(587.33, 0.04, 0.35) # High gentle wood tick
	ui_click_stream = _create_damped_sine(293.66, 0.08, 0.6)  # Soft tactile click
	slide_stream = _create_slide_sound(0.24, 0.5)
	suction_stream = _create_chirp_sound(260.0, 560.0, 0.32, 0.55)
	page_turn_stream = _create_slide_sound(0.16, 0.40)
	wax_stamp_stream = _create_damped_sine(130.0, 0.28, 0.85)

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

func _create_slide_sound(duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate: int = 44100
	var total_samples: int = int(duration * sample_rate)
	var data: PackedByteArray = PackedByteArray()
	data.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t: float = float(i) / float(sample_rate)
		var progress: float = t / duration
		var envelope: float = sin(progress * PI)
		var s1: float = sin(2.0 * PI * 140.0 * t)
		var s2: float = sin(2.0 * PI * 220.0 * t) * 0.5
		var noise: float = (randf() * 2.0 - 1.0) * 0.25
		var sample: float = (s1 + s2 + noise) * envelope * volume
		var val16: int = clampi(int(sample * 32767.0), -32768, 32767)
		data.encode_s16(i * 2, val16)
		
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

func _create_chirp_sound(start_freq: float, end_freq: float, duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate: int = 44100
	var total_samples: int = int(duration * sample_rate)
	var data: PackedByteArray = PackedByteArray()
	data.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t: float = float(i) / float(sample_rate)
		var progress: float = t / duration
		var freq: float = lerpf(start_freq, end_freq, progress)
		var envelope: float = sin(progress * PI)
		var sample: float = sin(2.0 * PI * freq * t) * envelope * volume
		var val16: int = clampi(int(sample * 32767.0), -32768, 32767)
		data.encode_s16(i * 2, val16)
		
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream
