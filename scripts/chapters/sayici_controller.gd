class_name SayiciController
extends ChapterBase
## Sayıcı'nın sahneye girişi, devriyesi, ölüm/yeniden doğma akışı; saklanma dolapları, dikkat dağıtma radyoları
## ve ses taklidi (yalnızca Bölüm 5+, devriyedeyken, bir kez). Bölüm 4 bitince (Bölüm 5) zemin kata inen oyuncuya karşı çıkar.

const ROUTE: Array[Vector3] = [Vector3(-11, 0, 1), Vector3(0, 0, -1), Vector3(11, 0, 0), Vector3(11, 0, 12), Vector3(0, 0, 12), Vector3(-10, 0, 11)]
const RADIO_NOISE := 16.0
const RADIO_COOLDOWN := 12.0

var sayici: Sayici
var voice_interval := 35.0
var deaths := 0
var _voice_t := 0.0

signal player_died


func _ready() -> void:
	_build_props()
	GameManager.area_entered.connect(_on_area)
	HorrorDirector.event_fired.connect(_on_event)


func active() -> bool:
	return GameManager.current_chapter >= 5 and GameManager.has_flag("ch4_done")


func _on_area(id: String, _n: String, counted: bool) -> void:
	if active() and counted and id.begins_with("g_") and sayici == null:
		spawn()


## Sayıcı oyuncudan en uzak devriye noktasında başlar (sebepsiz karşılaşma yok).
func spawn() -> void:
	if sayici != null or factory.player == null:
		return
	sayici = Sayici.new()
	factory.add_child(sayici)
	sayici.player = factory.player
	var far := ROUTE[0]
	for w in ROUTE:
		if w.distance_to(factory.player.global_position) > far.distance_to(factory.player.global_position):
			far = w
	sayici.global_position = far + Vector3(0, 0.05, 0)
	sayici.caught.connect(_on_caught)
	sayici.attack_started.connect(func(): AudioManager.say("Sayıcı kolunu kaldırıyor — kaç!", 1.5))
	sayici.start_patrol(ROUTE.duplicate())
	_voice_t = 0.0


func _process(delta: float) -> void:
	if sayici == null or not active():
		return
	if sayici.state == Sayici.State.PATROL and not sayici.sees_now:
		_voice_t += delta
		if _voice_t >= voice_interval:
			_voice_t = 0.0
			try_voice_mimic()


## Ses taklidi: yalnızca Bölüm 5+, Sayıcı devriyedeyken ve oyuncuyu görmüyorken; oyunda bir kez.
func try_voice_mimic() -> bool:
	if sayici == null or sayici.state != Sayici.State.PATROL or sayici.sees_now:
		return false
	return HorrorDirector.fire("ev_voice_mimic", 5)


func _on_event(id: String) -> void:
	if id == "ev_voice_mimic" and sayici != null and is_instance_valid(sayici):
		AudioManager.play_sfx("whisper", sayici.global_position)
		AudioManager.say("Hakan'ın sesi: Murat? Buraya gel, buradayım...", 5.0)
		sayici.hold_time = 6.0  # pusuda bekler


func _on_caught() -> void:
	deaths += 1
	factory.player.controls_enabled = false
	AudioManager.play_sfx("door_slam")
	AudioManager.say("Sayıcı seni saydı. Bir.", 2.5)
	player_died.emit()
	_fade(1.0, 1.0)
	await get_tree().create_timer(2.0).timeout
	if not is_inside_tree():
		return
	if sayici and is_instance_valid(sayici):
		sayici.queue_free()
	sayici = null
	factory.respawn_player()
	_fade(0.0, 0.8)


# ------------------------------------------------------------------ dikkat dağıtma
func use_radio(radio: Node3D) -> bool:
	var now := Time.get_ticks_msec() / 1000.0
	if radio.has_meta("until") and now < float(radio.get_meta("until")):
		AudioManager.say("Radyo hâlâ cızırdıyor.", 1.5)
		return false
	radio.set_meta("until", now + RADIO_COOLDOWN)
	AudioManager.play_sfx("radio", radio.global_position)
	AudioManager.say("Radyo yüksek sesle cızırdadı. Sayıcı bunu duymuş olabilir.", 3.0)
	GameManager.make_noise(radio.global_position, RADIO_NOISE, "radio")
	return true


# ------------------------------------------------------------------ sahne
func _hide_locker(pos: Vector3, exit_dir: Vector3) -> HideSpot:
	var h := HideSpot.new()
	h.position = pos
	h.exit_offset = exit_dir
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.7, 2.0, 0.7)
	mi.mesh = bm
	mi.material_override = _mat(Color(0.25, 0.3, 0.27))
	mi.position.y = 1.0
	h.add_child(mi)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(0.8, 2.0, 0.8)
	cs.shape = bs
	cs.position.y = 1.0
	h.add_child(cs)
	h.collision_layer = 5  # dünya + etkileşim (oyuncu içeri giremesin; saklanma ışınlama ile)
	factory.add_child(h)
	return h


func _radio(pos: Vector3) -> void:
	var r: CallbackInteractable = _spot(factory, pos, Vector3(0.3, 0.2, 0.15), Color(0.55, 0.3, 0.12), func(): return "Radyoyu aç (dikkat dağıt)", func(_p): pass)
	r.action_fn = func(_p): use_radio(r)


func _build_props() -> void:
	_hide_locker(Vector3(-13.3, 0, 15.3), Vector3(0, 0, -1.2))   # güvenlik kulübesi
	_hide_locker(Vector3(-15.3, 0, 6.5), Vector3(1.2, 0, 0))     # A Hattı
	_hide_locker(Vector3(15.3, 0, -2.5), Vector3(-1.2, 0, 0))    # C Hattı
	_radio(Vector3(13.0, 1.0, 7.6))    # C Hattı kuzey duvar
	_radio(Vector3(-13.0, 1.0, 7.6))   # A Hattı kuzey duvar
	_radio(Vector3(3.0, 0.95, -11.2))   # bakım odası masası
