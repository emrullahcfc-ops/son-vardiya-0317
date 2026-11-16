class_name Chapter1
extends ChapterBase
## Bölüm 1: Giriş ve Güvenlik. Eşyaları, görevleri, telefon görüşmelerini ve geçişi kurar.
## Akış: dışarıda telefon → Giriş'te kulübe anahtarı → Güvenlik: ölçü aleti, pano (ölç + şalter),
## saat/defter ipucu → Giriş: tuş takımı (0317) → personel kapısı → 03.17 anonsu → Bölüm 2 + kayıt.

const CODE := "0317"

var ring_time := 2.2  # telefon çalma süresi (testte 0)


func _ready() -> void:
	_build_props()
	GameManager.area_entered.connect(_on_area)
	InventoryManager.item_added.connect(_on_item)
	if not GameManager.has_flag("ch1_intro"):
		GameManager.set_flag("ch1_intro")
		_intro()


# ------------------------------------------------------------------ akış
func _on_area(id: String, _name: String, _counted: bool) -> void:
	# Yağmur dışarıda yüksek, içeride kısık.
	AudioManager.set_layer_db("rain", -18.0 if id == "g_out" else -38.0)
	if id == "g_entry" and not QuestManager.is_completed("ch1_enter_factory"):
		_complete("ch1_enter_factory")
		if not QuestManager.is_completed("ch1_booth_key"):
			QuestManager.start_quest("ch1_booth_key")
	if id == "g_lineB" and GameManager.has_flag("ch1_staff_unlocked") and not GameManager.has_flag("ch1_done"):
		finish_chapter()


func _on_item(item_id: String) -> void:
	if item_id == "key_security_booth":
		_complete("ch1_booth_key")
		if not QuestManager.is_completed("ch1_power_staff_door"):
			QuestManager.start_quest("ch1_power_staff_door")
		if not QuestManager.is_completed("ch1_find_door_code"):
			QuestManager.start_quest("ch1_find_door_code")


func _intro() -> void:
	AudioManager.say("WASD yürü · Shift koş · Ctrl çömel · E etkileşim · ESC fareyi bırak", 5.0)
	await get_tree().create_timer(ring_time + 4.0 if ring_time > 0.0 else 0.0).timeout
	if not is_inside_tree():
		return
	await _call([
		["Hakan: Murat? Fabrikanın önündesin, değil mi?", 3.5],
		["Hakan: Kuzey İplik. 2004'ten beri kapalı. Elektrik panosu güvenlik kulübesinde.", 5.0],
		["Hakan: Personel kapısına enerji ver, kodu bul, içeri gir. Sonra raporu yazarsın.", 5.0],
		["Hakan: Dikkatli ol. Saat 03.17'den önce çıkmaya bak.", 4.0],
	])


## Telefon görüşmesi: zil sesi, sonra altyazılı satırlar.
func _call(lines: Array) -> void:
	AudioManager.play_sfx("phone")
	if ring_time > 0.0:
		await get_tree().create_timer(ring_time).timeout
	for l in lines:
		if not is_inside_tree():
			return
		AudioManager.say(String(l[0]), float(l[1]))
		if ring_time > 0.0:
			await get_tree().create_timer(float(l[1]) + 0.3).timeout


# ------------------------------------------------------------------ etkileşimler (mantık)
func fuse_panel() -> void:
	if GameManager.has_flag("ch1_power_on"):
		AudioManager.say("Şalter açık. Hat gerilimi: 24 V.", 2.5)
	elif not InventoryManager.has_item("multimeter"):
		AudioManager.say("Sigorta panosu. Hattı ölçmek için ölçü aleti lazım.", 3.0)
	elif not GameManager.has_flag("ch1_measured"):
		GameManager.set_flag("ch1_measured")
		AudioManager.say("Ölçüm: 0 V. Şalter kapalı. Kolu çekmen gerek.", 3.5)
	else:
		GameManager.set_flag("ch1_power_on")
		AudioManager.play_sfx("click")
		AudioManager.say("Şalter açıldı. Ölçüm: 24 V. Personel kapısı enerjilendi.", 4.0)
		_complete("ch1_power_staff_door")


## 11 işçi panosu. 12. siluet YALNIZCA enerji açıkken ve ilk incelemede belirir.
func photo_board() -> void:
	if not GameManager.has_flag("ch1_power_on"):
		AudioManager.say("Pano: on bir işçi fotoğrafı. Karanlıkta yüzler seçilmiyor.", 3.5)
		return
	if GameManager.has_flag("ch1_photo12"):
		AudioManager.say("Pano: on bir yüz ve on ikinci bir karaltı.", 3.0)
		return
	GameManager.set_flag("ch1_photo12")
	_show_twelfth()
	AudioManager.play_sfx("whisper", _photo_pos)
	AudioManager.say("Panoda on bir fotoğraf var. On ikinci çerçeve boş değil: bir karaltı. Altındaki listede yeni satır: '12. — Murat Demir'.", 7.0)
	_call([
		["Hakan: Murat, hattan paraziti var. Listeni okuyabiliyor musun?", 4.0],
		["Murat: Listede... benim adım var.", 3.0],
		["Hakan: Hemen çık oradan. Hayır... önce kapıyı geç. Sayıcı seni bekliyor.", 4.5],
	])


func finish_chapter() -> void:
	GameManager.set_flag("ch1_done")
	_complete("ch1_find_door_code")
	_complete("ch1_power_staff_door")
	AudioManager.play_sfx("chime")
	AudioManager.say("[Anons] Saat 03.17. Vardiya başlıyor. On iki kişi sayılacak.", 5.0)
	GameManager.set_chapter(2)
	_checkpoint()  # kontrol noktası: Bölüm 2 geçişi kayıtla korunur
	if ring_time > 0.0:
		await get_tree().create_timer(5.4).timeout
		if is_inside_tree():
			AudioManager.say("Kontrol noktası kaydedildi.", 2.0)


# ------------------------------------------------------------------ sahne
var _photo_pos := Vector3.ZERO
var _twelfth: MeshInstance3D


func _show_twelfth() -> void:
	if _twelfth:
		_twelfth.visible = true


func _build_props() -> void:
	# --- Dış alan: araç, yağmur
	_box(factory, Vector3(4.0, 0.6, 20.5), Vector3(1.9, 0.8, 4.2), Color(0.12, 0.15, 0.2), 0.12)
	_box(factory, Vector3(4.0, 1.3, 20.2), Vector3(1.6, 0.7, 2.0), Color(0.1, 0.12, 0.16), 0.12)
	var hl := OmniLight3D.new()
	hl.position = Vector3(3.6, 0.9, 18.2)
	hl.light_color = Color(1.0, 0.9, 0.6)
	hl.light_energy = 1.2
	hl.omni_range = 5.0
	factory.add_child(hl)
	var rain := CPUParticles3D.new()
	rain.position = Vector3(0, 6.0, 20.0)
	rain.amount = 500
	rain.lifetime = 0.5
	rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	rain.emission_box_extents = Vector3(6, 0.1, 4)
	rain.direction = Vector3(0, -1, 0)
	rain.spread = 2.0
	rain.initial_velocity_min = 14.0
	rain.initial_velocity_max = 16.0
	var rm := BoxMesh.new()
	rm.size = Vector3(0.01, 0.4, 0.01)
	rain.mesh = rm
	rain.material_override = _mat(Color(0.6, 0.7, 0.9, 1), true)
	factory.add_child(rain)
	AudioManager.start_layer("rain", -18.0)

	# --- Giriş: masa, anahtar, kroki, tuş takımı, pano, turnike
	_box(factory, Vector3(4.2, 0.45, 14.8), Vector3(2.6, 0.9, 0.9), Color(0.3, 0.25, 0.2))
	_pickup(Vector3(3.6, 0.95, 14.8), "key_security_booth", "ch1_booth_key")
	_doc(Vector3(4.8, 0.93, 14.8), "Kat krokisi", "Zemin: giriş, güvenlik (batı), yükleme (doğu), üretim hatları (güney). Merdivenler iki uçta. Personel kapısı üretim hattına açılır.")
	var kp := Keypad.new()
	kp.position = Vector3(1.4, 1.3, 8.28)
	kp.code = CODE
	var kmi := MeshInstance3D.new()
	var kbm := BoxMesh.new()
	kbm.size = Vector3(0.25, 0.35, 0.05)
	kmi.mesh = kbm
	kmi.material_override = _mat(Color(0.1, 0.35, 0.2))
	kp.add_child(kmi)
	var kcs := CollisionShape3D.new()
	var kbs := BoxShape3D.new()
	kbs.size = Vector3(0.4, 0.5, 0.2)
	kcs.shape = kbs
	kp.add_child(kcs)
	factory.add_child(kp)
	_photo_pos = Vector3(-3.5, 1.7, 15.7)
	var board := _spot(factory, _photo_pos, Vector3(2.6, 1.2, 0.05), Color(0.25, 0.2, 0.15), func(): return "İncele: 11 işçi panosu", func(_p): photo_board())
	for i in 12:
		var f := MeshInstance3D.new()
		var fm := BoxMesh.new()
		fm.size = Vector3(0.28, 0.36, 0.02)
		f.mesh = fm
		var dark := i == 11
		f.material_override = _mat(Color(0.02, 0.02, 0.02) if dark else Color(0.7, 0.68, 0.62), dark)
		f.position = Vector3(-1.0 + (i % 6) * 0.4, 0.2 - (i / 6) * 0.45, -0.04)
		board.add_child(f)
		if dark:
			_twelfth = f
			f.visible = GameManager.has_flag("ch1_photo12")
	_box(factory, Vector3(-1.8, 0.5, 13.5), Vector3(0.25, 1.0, 0.25), Color(0.35, 0.35, 0.38))
	_box(factory, Vector3(-1.8, 0.9, 13.0), Vector3(0.1, 0.1, 0.9), Color(0.5, 0.5, 0.52))

	# --- Güvenlik kulübesi: masa, ölçü aleti, defter, saat, sigorta panosu
	_box(factory, Vector3(-9.0, 0.45, 14.8), Vector3(3.0, 0.9, 0.9), Color(0.3, 0.25, 0.2))
	_pickup(Vector3(-10.0, 0.95, 14.8), "multimeter", "ch1_multimeter")
	_doc(Vector3(-8.2, 0.93, 14.8), "Vardiya defteri", "'Personel kapısı kodu, vardiya değişim saatidir. Kimseye söyleme.' — Y. Demir")
	_spot(factory, Vector3(-12.0, 1.9, 15.7), Vector3(0.5, 0.5, 0.05), Color(0.8, 0.8, 0.75), func(): return "İncele: Duvar saati", func(_p): AudioManager.say("Duvar saati 03.17'de durmuş. Pilsiz bile olsa... neden bu saatte?", 4.0))
	_spot(factory, Vector3(-13.7, 1.4, 12.0), Vector3(0.1, 1.0, 0.7), Color(0.3, 0.32, 0.3), func(): return "Sigorta panosu", func(_p): fuse_panel())
