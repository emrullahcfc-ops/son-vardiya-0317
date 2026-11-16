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


func _ready() -> void:
	_build_props()
	GameManager.chapter_changed.connect(func(c): if c >= 2: _begin())
	InventoryManager.item_added.connect(_on_item)
	if GameManager.current_chapter >= 2:
		_begin()
	_restore()


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
		SaveManager.save_game()  # kontrol noktası


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
