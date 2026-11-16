class_name Chapter2
extends ChapterBase
## Bölüm 2: Üretim Hattı. Faz sırası belgeden okunur (2. hat, 3. hat, 1. hat = B, C, A);
## yanlış sırada sistem sıfırlanır ve tekrar denenir. Dolap kodu 317 = hat sayısı (3) + en son duran hattın sayacı (17),
## belgelerden çıkarılır. Üç hat çalışınca final sahnesi: bakım kapısı açılır. Dolaptan kat anahtarı alınır.

const SEQUENCE := ["B", "C", "A"]
const COUNTERS := {"A": "04", "B": "11", "C": "17"}
const LINE_NAMES := {"A": "Hat 1 (A)", "B": "Hat 2 (B)", "C": "Hat 3 (C)"}
const CABINET_CODE := "317"

var _machines: Dictionary = {}  # hat -> MeshInstance3D
var _cabinet: Node
var _wait := true  # final altyazıları gerçek zamanlı beklesin (testte false)

# --- Taklitçi kovalamacası (Aşama 9)
var chase_enabled := true      # testte kapatılabilir
var chase_active := false
var activate_delay := 1.5      # oyuncu bakım odasından çıktıktan sonra Taklitçi'nin uyanma gecikmesi
var dormant_timeout := 10.0    # oyuncu çıkmasa da uyanma süresi
var deaths := 0
var mimic: Mimic
var shutter: Shutter
var _lever: Node

signal player_died
signal chase_succeeded


func _ready() -> void:
	_build_props()
	GameManager.chapter_changed.connect(func(c): if c >= 2: _begin())
	InventoryManager.item_added.connect(_on_item)
	GameManager.area_entered.connect(_on_area)
	if GameManager.current_chapter >= 2:
		_begin()
	_restore()
	# Kontrol noktasından yüklenince (ölüm / F9) bitmemiş kovalamaca yeniden başlar.
	if GameManager.has_flag("ch2_done") and not GameManager.has_flag("ch2_chase_done") and chase_enabled:
		get_tree().create_timer(2.0).timeout.connect(start_chase)


func _begin() -> void:
	QuestManager.start_quest("ch2_start_lines")
	QuestManager.start_quest("ch2_cabinet_code")


# ------------------------------------------------------------------ bulmaca mantığı
func lines_started() -> Array:
	var out := []
	for l in SEQUENCE:
		if GameManager.has_flag("ch2_line_" + l):
			out.append(l)
	return out


## Hat başlatma düğmesi. Doğru sıra: B, C, A. Yanlışta her şey sıfırlanır (kilitlenme yok).
func press_line(line: String) -> void:
	if GameManager.has_flag("ch2_machines_on"):
		AudioManager.say("%s çalışıyor." % LINE_NAMES[line], 2.0)
		return
	var done := lines_started()
	if done.has(line):
		AudioManager.say("%s zaten çalışıyor." % LINE_NAMES[line], 2.0)
		return
	if line != SEQUENCE[done.size()]:
		_reset_lines()
		AudioManager.play_sfx("error")
		AudioManager.say("Faz uyumsuz! Sistem sıfırlandı. Çizelgedeki sırayı kontrol et.", 4.0)
		return
	GameManager.set_flag("ch2_line_" + line)
	_set_machine(line, true)
	AudioManager.play_sfx("click")
	AudioManager.say("%s çalıştı." % LINE_NAMES[line], 2.0)
	if lines_started().size() == SEQUENCE.size():
		machines_online()


func _reset_lines() -> void:
	for l in SEQUENCE:
		GameManager.flags.erase("ch2_line_" + l)
		_set_machine(l, false)


## Final sahnesi: üç makine eşzamanlı çalışır, bakım kapısının kilidi düşer.
func machines_online() -> void:
	GameManager.set_flag("ch2_machines_on")
	_complete("ch2_start_lines")
	AudioManager.start_layer("machine", -12.0)
	AudioManager.play_sfx("chime")
	HorrorDirector.intensity = clampf(HorrorDirector.intensity + 0.3, 0.0, 1.0)
	AudioManager.say("Üç hat aynı anda çalışmaya başladı. Bakım kapısının kilidi düştü.", 5.0)
	_pulse_lights()
	if _wait:
		await get_tree().create_timer(5.5).timeout
		if is_inside_tree():
			AudioManager.say("[Anons] Sayım devam ediyor. Eksik: bir kişi.", 5.0)


func _pulse_lights() -> void:
	var reduced: bool = GameManager.settings.get("flash_reduction", true)
	for l in get_tree().get_nodes_in_group("room_light"):
		var rid: String = l.get_meta("room_id", "")
		if rid not in ["g_lineA", "g_lineB", "g_lineC"]:
			continue
		var base: float = l.get_meta("base_energy", l.light_energy)
		var tw := create_tween()
		var step := 0.5 if reduced else 0.12  # azaltılmışta yavaş nefes, değilse hızlı titreme
		tw.tween_property(l, "light_energy", base * 0.5, step)
		tw.tween_property(l, "light_energy", base * 1.2, step)
		tw.tween_property(l, "light_energy", base, step)


func _on_cabinet_open() -> void:
	_complete("ch2_cabinet_code")
	_spawn_key()


func _spawn_key() -> void:
	if InventoryManager.has_item("floor_key") or GameManager.has_flag("pickup_ch2_floor_key"):
		return
	_pickup(Vector3(-5.25, 1.2, -8.0), "floor_key", "ch2_floor_key")


func _on_item(item_id: String) -> void:
	if item_id == "floor_key" and not GameManager.has_flag("ch2_done"):
		GameManager.set_flag("ch2_done")
		_complete("ch2_floor_key")
		AudioManager.say("Kat anahtarını aldın. Merdivendeki kapı artık açılır.", 4.0)
		_checkpoint()  # kontrol noktası
		if chase_enabled:
			get_tree().create_timer(1.5).timeout.connect(start_chase)


func _restore() -> void:
	for l in lines_started():
		_set_machine(l, true)
	if GameManager.has_flag("ch2_machines_on"):
		AudioManager.start_layer("machine", -12.0)
	if GameManager.has_flag("ch2_cabinet_open"):
		_spawn_key()


func _set_machine(line: String, on: bool) -> void:
	var m: MeshInstance3D = _machines.get(line)
	if m == null:
		return
	var mat := m.material_override as StandardMaterial3D
	mat.emission_enabled = on
	mat.emission = Color(0.1, 0.6, 0.25)
	mat.emission_energy_multiplier = 0.6


# ------------------------------------------------------------------ sahne
func _build_props() -> void:
	var centers := {"A": -8.5, "B": 2.5, "C": 13.5}
	var plate_text := {}
	for l in SEQUENCE:
		var mx: float = centers[l]
		var body := _box(factory, Vector3(mx, 0.8, 4.5), Vector3(2.4, 1.6, 2.6), Color(0.22, 0.24, 0.27))
		_machines[l] = body.get_child(0)
		var mat := _mat(Color(0.22, 0.24, 0.27))
		_machines[l].material_override = mat
		var line: String = l
		_spot(factory, Vector3(mx, 1.3, 3.15), Vector3(0.8, 0.35, 0.05), Color(0.75, 0.72, 0.6), func(): return "İncele: %s plakası" % LINE_NAMES[line], func(_p): AudioManager.say("%s — makine sayacı donmuş: %s" % [LINE_NAMES[line], COUNTERS[line]], 4.0))
		_spot(factory, Vector3(mx - 1.8, 0.6, 3.6), Vector3(0.4, 1.2, 0.5), Color(0.55, 0.15, 0.12), func(): return "Başlat: %s" % LINE_NAMES[line], func(_p): press_line(line))
	# Çizelge (Hat B odasında, güney duvarda)
	_spot(factory, Vector3(-3.0, 1.6, -3.7), Vector3(0.9, 0.6, 0.05), Color(0.8, 0.78, 0.65), func(): return "Oku: Vardiya çizelgesi", func(_p): AudioManager.say("VARDİYA ÇİZELGESİ — Faz sırası: 2. hat, 3. hat, 1. hat. Sıra bozulursa sistem kendini sıfırlar. (1=A, 2=B, 3=C)", 7.0))
	# Dilekçe (A hattı masası)
	_box(factory, Vector3(-13.5, 0.45, -2.2), Vector3(2.4, 0.9, 0.9), Color(0.3, 0.25, 0.2))
	_doc(Vector3(-13.0, 0.93, -2.2), "Dilekçe", "Bakım iptal edildi. Makineler A, B, C sırasıyla durdu; sayaçlar 04, 11 ve 17'de kaldı. Biz hâlâ içerideyiz.")
	# Bakım odası: form ve dolap
	_box(factory, Vector3(2.0, 0.45, -11.2), Vector3(2.4, 0.9, 0.9), Color(0.3, 0.25, 0.2))
	_doc(Vector3(2.0, 0.93, -11.2), "Bakım iptal formu", "Dolap kodu = hat sayısı, ardından en son duran hattın sayacı. Başlama: 03.17.")
	var kp := Keypad.new()
	kp.position = Vector3(-5.3, 1.0, -8.0)
	kp.code = CABINET_CODE
	kp.power_flag = ""
	kp.unlock_flag = "ch2_cabinet_open"
	kp.quest_id = "ch2_cabinet_code"
	kp.title_text = "Bakım dolabı — 3 haneli kod"
	kp.ok_text = "Dolap açıldı. İçinde bir kat anahtarı var."
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.5, 2.0, 1.0)
	mi.mesh = bm
	mi.material_override = _mat(Color(0.25, 0.3, 0.25))
	kp.add_child(mi)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(0.6, 2.0, 1.1)
	cs.shape = bs
	kp.add_child(cs)
	factory.add_child(kp)
	kp.unlocked.connect(_on_cabinet_open)
	_cabinet = kp
	# Güvenlik kepengi: B Hattı ↔ A Hattı geçidi (x=-6, z=2). Kol A Hattı tarafında.
	shutter = Shutter.new()
	shutter.position = Vector3(-6.1, 0.0, 2.0)
	factory.add_child(shutter)
	_lever = _spot(factory, Vector3(-6.3, 1.3, 3.6), Vector3(0.1, 0.5, 0.3), Color(0.7, 0.2, 0.1), func(): return "Kepenk kolunu çek", func(_p): pull_lever())
	shutter.state_changed.connect(func(down: bool): if down: factory.rebake_navigation())


# ------------------------------------------------------------------ Taklitçi kovalamacası
func _on_area(id: String, _n: String, _c: bool) -> void:
	if not chase_active or mimic == null or not is_instance_valid(mimic):
		return
	if id == "g_lineB" and mimic.state == Mimic.State.DORMANT:
		get_tree().create_timer(activate_delay).timeout.connect(_activate_mimic)
	elif id == "g_stairU" and shutter.is_down:
		succeed()


func _activate_mimic() -> void:
	if chase_active and mimic and is_instance_valid(mimic):
		mimic.activate()


## Senaryo: kat anahtarı alınınca bakım odasının köşesinde Taklitçi belirir. Oyuncu odadan çıkınca uyanır.
## Kaçış: B Hattı ile A Hattı arasındaki geçide kepenk kolu çekip kepengi indirmek.
func start_chase() -> void:
	if chase_active or GameManager.has_flag("ch2_chase_done") or factory.player == null:
		return
	chase_active = true
	shutter.set_state_instant(false)
	for d in factory.doors:
		if d.door_id == "d09":
			d.force_open()  # çıkış garanti: bakım kapısı açık
	QuestManager.start_quest("ch2_escape")
	AudioManager.say("Işıklar titredi. Odanın köşesinde biri duruyor.", 4.0)
	_pulse_lights()
	mimic = Mimic.new()
	factory.add_child(mimic)
	mimic.global_position = Vector3(5.0, 0.05, -11.0)
	mimic.player = factory.player
	mimic.caught.connect(_on_caught)
	mimic.gave_up.connect(succeed)
	AudioManager.play_sfx("thump", mimic.global_position)
	get_tree().create_timer(dormant_timeout).timeout.connect(_activate_mimic)


func pull_lever() -> void:
	if not shutter.is_down:
		var blockers: Array = [factory.player]
		if mimic and is_instance_valid(mimic):
			blockers.append(mimic)
		if not shutter.lower(blockers):
			AudioManager.say("Geçitte biri var.", 2.0)
			return
		AudioManager.play_sfx("door_slam", shutter.global_position)
		AudioManager.say("Kepenk indi!", 2.0)
	elif not chase_active:
		shutter.raise()
		AudioManager.say("Kepenk kalktı.", 2.0)
		factory.rebake_navigation()
	else:
		AudioManager.say("Kepenk zaten inik.", 1.5)


func succeed() -> void:
	if not chase_active:
		return
	chase_active = false
	GameManager.set_flag("ch2_chase_done")
	_complete("ch2_escape")
	if mimic and is_instance_valid(mimic):
		mimic.retreat()
		var m := mimic
		var tw := create_tween()
		tw.tween_interval(2.0)
		tw.tween_callback(m.queue_free)
	AudioManager.play_sfx("whisper", factory.player.global_position)
	AudioManager.say("Taklitçi geri çekildi. Üst kata çıkabilirsin.", 4.0)
	_checkpoint()
	chase_succeeded.emit()


func _on_caught() -> void:
	if not chase_active:
		return
	chase_active = false
	deaths += 1
	GameManager.add_death()
	factory.player.controls_enabled = false
	AudioManager.play_sfx("door_slam")
	AudioManager.say("Taklitçi seni yakaladı.", 2.5)
	player_died.emit()
	_fade(1.0, 1.0)
	await get_tree().create_timer(2.0).timeout
	if not is_inside_tree():
		return
	_cleanup_chase()
	factory.respawn_player()  # kontrol noktası: kaydı yükler, oyuncuyu yerine koyar
	_fade(0.0, 0.8)
	get_tree().create_timer(2.0).timeout.connect(start_chase)


func _cleanup_chase() -> void:
	if mimic and is_instance_valid(mimic):
		mimic.queue_free()
	mimic = null
	if shutter.is_down:
		shutter.set_state_instant(false)
		factory.rebake_navigation()
