extends Node
## Ses yönetimi (Aşama 6): ana ses, SFX ve Ambient kanalları, sentetik (telifsiz) sesler,
## döngülü ortam katmanları ve altyazı olayları. Gerçek ses dosyaları sonradan eklenir.

signal subtitle(text: String, duration: float)

const RATE := 22050

var _cache: Dictionary = {}
var _layers: Dictionary = {}  # katman id -> AudioStreamPlayer


func _ready() -> void:
	_ensure_bus("SFX")
	_ensure_bus("Ambient")
	GameManager.settings_changed.connect(_apply_volume)
	_apply_volume()


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")


func _vol_db(key: String) -> float:
	var v: float = clampf(float(GameManager.settings.get(key, 1.0)), 0.0, 1.0)
	return linear_to_db(maxf(v, 0.0001))


func _apply_volume() -> void:
	AudioServer.set_bus_volume_db(0, _vol_db("master_volume"))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), _vol_db("sfx_volume"))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Ambient"), _vol_db("ambient_volume"))


func say(text: String, duration: float = 3.0) -> void:
	if GameManager.settings.get("subtitles", true):
		subtitle.emit(text, duration)


# ------------------------------------------------------------------ çalma
## pos verilirse 3 boyutlu (konumlu), verilmezse 2 boyutlu çalar. Bitince kendini siler.
func play_sfx(sound: String, pos: Variant = null, db: float = 0.0) -> Node:
	var stream := get_sound(sound)
	if stream == null:
		return null
	var p: Node
	if pos is Vector3:
		var p3 := AudioStreamPlayer3D.new()
		p3.stream = stream
		p3.volume_db = db
		p3.bus = "SFX"
		p3.max_distance = 40.0
		p3.unit_size = 6.0
		p = p3
	else:
		var p2 := AudioStreamPlayer.new()
		p2.stream = stream
		p2.volume_db = db
		p2.bus = "SFX"
		p = p2
	p.finished.connect(p.queue_free)
	var host: Node = get_tree().current_scene if get_tree().current_scene else self
	host.add_child(p)
	if pos is Vector3:
		p.global_position = pos
	p.play()
	return p


func start_layer(id: String, db: float = -30.0) -> void:
	if _layers.has(id):
		return
	var stream := get_sound(id)
	if stream == null:
		return
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.bus = "Ambient"
	p.volume_db = db
	add_child(p)
	p.play()
	_layers[id] = p


func set_layer_db(id: String, db: float) -> void:
	if _layers.has(id):
		_layers[id].volume_db = db


func stop_layer(id: String) -> void:
	if _layers.has(id):
		_layers[id].queue_free()
		_layers.erase(id)


func has_layer(id: String) -> bool:
	return _layers.has(id)


# ------------------------------------------------------------------ sentez
func get_sound(sound: String) -> AudioStreamWAV:
	if _cache.has(sound):
		return _cache[sound]
	var s := _synth(sound)
	if s != null:
		_cache[sound] = s
	return s


func _synth(sound: String) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(sound)
	var n: int
	var d: PackedFloat32Array
	var loop := false
	match sound:
		"door_slam":
			n = int(RATE * 0.6)
			d.resize(n)
			for i in n:
				var t := float(i) / RATE
				d[i] = (rng.randf_range(-1, 1) * exp(-t * 16.0) * 0.8 + sin(TAU * 55.0 * t) * exp(-t * 8.0)) * 0.7
		"chime":
			n = int(RATE * 1.6)
			d.resize(n)
			for i in n:
				var t := float(i) / RATE
				var a := sin(TAU * 880.0 * t) * exp(-t * 3.0)
				if t > 0.4:
					a += sin(TAU * 660.0 * (t - 0.4)) * exp(-(t - 0.4) * 3.0)
				d[i] = a * 0.35
		"buzz":
			n = int(RATE * 0.8)
			d.resize(n)
			for i in n:
				var t := float(i) / RATE
				var gate := 1.0 if sin(TAU * 11.0 * t) > -0.2 else 0.15
				d[i] = (sin(TAU * 100.0 * t) + 0.5 * sin(TAU * 300.0 * t) + rng.randf_range(-0.2, 0.2)) * 0.25 * gate * exp(-t * 1.5)
		"thump":
			n = int(RATE * 0.5)
			d.resize(n)
			for i in n:
				var t := float(i) / RATE
				d[i] = sin(TAU * 42.0 * t) * exp(-t * 7.0) * 0.8
		"whisper":
			n = int(RATE * 1.8)
			d.resize(n)
			var lp := 0.0
			for i in n:
				var t := float(i) / RATE
				lp += (rng.randf_range(-1, 1) - lp) * 0.25
				d[i] = lp * 0.5 * sin(PI * t / 1.8) * (0.6 + 0.4 * sin(TAU * 6.0 * t))
		"phone":
			n = int(RATE * 2.2)
			d.resize(n)
			for i in n:
				var t := float(i) / RATE
				var on := fmod(t, 1.1) < 0.45
				d[i] = (sin(TAU * 440.0 * t) + sin(TAU * 480.0 * t)) * 0.2 * (1.0 if on else 0.0)
		"beep":
			n = int(RATE * 0.15)
			d.resize(n)
			for i in n:
				var t := float(i) / RATE
				d[i] = sin(TAU * 1200.0 * t) * 0.3 * (1.0 - t / 0.15)
		"error":
			n = int(RATE * 0.35)
			d.resize(n)
			for i in n:
				var t := float(i) / RATE
				d[i] = (1.0 if sin(TAU * 150.0 * t) > 0.0 else -1.0) * 0.25 * (1.0 - t / 0.35)
		"click":
			n = int(RATE * 0.06)
			d.resize(n)
			for i in n:
				d[i] = rng.randf_range(-1, 1) * 0.5 * (1.0 - float(i) / n)
		"rain":
			loop = true
			n = RATE * 4
			d.resize(n)
			var lp3 := 0.0
			for i in n:
				var x := rng.randf_range(-1, 1)
				lp3 += (x - lp3) * 0.3
				var fade := minf(1.0, minf(float(i), float(n - i)) / (RATE * 0.1))
				d[i] = (x - lp3) * 0.5 * fade
		"machine":
			loop = true
			n = RATE * 2
			d.resize(n)
			for i in n:
				var t := float(i) / RATE
				var pulse := 0.55 + 0.45 * sin(TAU * 4.0 * t)
				d[i] = (sin(TAU * 60.0 * t) * 0.5 + sin(TAU * 120.0 * t) * 0.3 + rng.randf_range(-0.1, 0.1)) * pulse * 0.7
		"radio":
			n = int(RATE * 1.8)
			d.resize(n)
			for i in n:
				var t := float(i) / RATE
				var gate := 1.0 if sin(TAU * 7.0 * t) > -0.3 else 0.4
				d[i] = (rng.randf_range(-1, 1) * 0.35 + sin(TAU * 660.0 * t) * 0.25) * gate * (1.0 - t / 1.8)
		"steam":
			n = int(RATE * 1.5)
			d.resize(n)
			var lp4 := 0.0
			for i in n:
				var t := float(i) / RATE
				lp4 += (rng.randf_range(-1, 1) - lp4) * 0.5
				d[i] = lp4 * 0.6 * minf(1.0, t * 8.0) * (1.0 - t / 1.5)
		"hum":
			loop = true
			n = RATE * 3
			d.resize(n)
			for i in n:
				var t := float(i) / RATE
				d[i] = (sin(TAU * 50.0 * t) * 0.5 + sin(TAU * 100.0 * t) * 0.25 + sin(TAU * 150.0 * t) * 0.1) * 0.6
		"wind":
			loop = true
			n = RATE * 4
			d.resize(n)
			var lp2 := 0.0
			for i in n:
				var t := float(i) / RATE
				lp2 += (rng.randf_range(-1, 1) - lp2) * 0.04
				var fade := minf(1.0, minf(float(i), float(n - i)) / (RATE * 0.1))
				d[i] = lp2 * 1.6 * (0.7 + 0.3 * sin(TAU * 0.5 * t)) * fade
		_:
			return null
	return _make_wav(d, loop)


func _make_wav(d: PackedFloat32Array, loop: bool) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(d.size() * 2)
	for i in d.size():
		bytes.encode_s16(i * 2, int(clampf(d[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = d.size()
	return w
