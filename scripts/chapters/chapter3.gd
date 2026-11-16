class_name Chapter3
extends ChapterBase
## Bölüm 3: Personel Katı (üst kat). 11 işçi kimliği (altısı ana görevi tamamlar), revir kodu 264 (üç ipucu),
## yemekhane çorba/sandalye olayı (+ kadın silueti, HorrorDirector), Yusuf'un kartı ve Sayıcı'nın 1–12 sayması.
## Akış: merdivenden çık → kimlikleri topla → ≥6 kimlik: personel bürosu açılır → Yusuf'un kartı → sayım → Bölüm 4.

const Y := 4.0
const CABINET_CODE := "264"
const NUMBERS := ["Bir", "İki", "Üç", "Dört", "Beş", "Altı", "Yedi", "Sekiz", "Dokuz", "On", "On bir", "On iki"]

var _wait := true               # sayım satırları gerçek zamanlı aralıkla (testte false)
var counting_lines: Array = []
var _chair: StaticBody3D
var _cabinet: Keypad

signal worker_collected(worker_id: String)


func _ready() -> void:
	_build_props()
	GameManager.area_entered.connect(_on_area)
	InventoryManager.item_added.connect(_on_item)
	_restore()


func _on_area(id: String, _n: String, _c: bool) -> void:
	if id in ["u_stairU", "u_dress"] and GameManager.has_flag("ch2_done") and not GameManager.has_flag("ch3_started"):
		begin()


func begin() -> void:
	GameManager.set_flag("ch3_started")
	GameManager.set_chapter(3)
	QuestManager.start_quest("ch3_collect_ids")
	QuestManager.start_quest("ch3_infirmary_code")
	AudioManager.say("Personel katı. Burada çalışanların kimlikleri kalmış olmalı. En az altısını bul.", 5.0)
	_checkpoint()


func _restore() -> void:
	if GameManager.has_flag("ch3_soup"):
		_spawn_worker_spot("kemal", Vector3(0.0, Y + 0.1, 11.0))
	if GameManager.has_flag("ch3_cabinet_open"):
		_spawn_worker_spot("zeynep", Vector3(15.3, Y + 1.0, 12.5))


# ------------------------------------------------------------------ kimlikler
## Kimliği envantere ekler (tekrar alınamaz). 6. kimlikte ana görev biter.
func give_worker(worker_id: String) -> bool:
	var item := WorkerData.item_id(worker_id)
	var w := WorkerData.get_worker(worker_id)
	if w.is_empty() or InventoryManager.has_item(item):
		AudioManager.say("Bu kimliği zaten aldın.", 2.0)
		return false
	GameManager.set_flag("pickup_ch3_" + worker_id)
	InventoryManager.add_item(item)
	var n := WorkerData.collected_count(InventoryManager)
	var msg := "%s  [Kimlik %d/11]" % [w["bio"], n]
	if GameManager.has_flag("ch3_ids_done") and n == WorkerData.REQUIRED_FOR_MAIN:
		msg += "  Altı kimlik tamam: personel bürosunun kilidi açıldı."
	AudioManager.play_sfx("click")
	AudioManager.say(msg, 8.0)
	worker_collected.emit(worker_id)
	return true


func _on_item(item_id: String) -> void:
	if item_id.begins_with("worker_id_"):
		if WorkerData.collected_count(InventoryManager) >= WorkerData.REQUIRED_FOR_MAIN and not GameManager.has_flag("ch3_ids_done"):
			GameManager.set_flag("ch3_ids_done")
			_complete("ch3_collect_ids")
			QuestManager.start_quest("ch3_yusuf_card")
			_checkpoint()
	elif item_id == "yusuf_card" and not GameManager.has_flag("ch3_done"):
		counting_scene()


## Sayıcı'nın sayımı: 1'den 12'ye; 12. sayıda Murat'ın adı. Bölüm 4'e geçiş ve kayıt.
func counting_scene() -> void:
	GameManager.set_flag("ch3_done")
	_complete("ch3_yusuf_card")
	GameManager.set_chapter(4)
	_checkpoint()
	counting_lines.clear()
	for i in NUMBERS.size():
		var line := "Sayıcı: %s." % NUMBERS[i]
		counting_lines.append(line)
		AudioManager.play_sfx("chime" if (i + 1) % 4 == 0 else "click")
		AudioManager.say(line, 1.2)
		HorrorDirector.intensity = clampf(HorrorDirector.intensity + 0.04, 0.0, 1.0)
		if _wait:
			await get_tree().create_timer(1.2).timeout
			if not is_inside_tree():
				return
	AudioManager.say("Sayıcı: On iki. On ikinci isim yazılı: Murat Demir.", 6.0)


# ------------------------------------------------------------------ yemekhane olayı
func soup() -> void:
	if GameManager.has_flag("ch3_soup"):
		AudioManager.say("Çorba hâlâ sıcak. Sandalye tabağın karşısında bekliyor.", 3.0)
		return
	GameManager.set_flag("ch3_soup")
	AudioManager.play_sfx("thump", _chair.global_position)
	AudioManager.say("Çorba hâlâ sıcak. 2004'ten beri... Sandalye kendi kendine geri çekildi.", 5.0)
	var tw := create_tween()
	tw.tween_property(_chair, "position:x", _chair.position.x + 0.7, 0.6)
	tw.parallel().tween_property(_chair, "rotation:y", 1.2, 0.6)
	_spawn_worker_spot("kemal", Vector3(0.0, Y + 0.1, 11.0))


func _spawn_worker_spot(worker_id: String, pos: Vector3) -> void:
	if InventoryManager.has_item(WorkerData.item_id(worker_id)):
		return
	var w := WorkerData.get_worker(worker_id)
	var sp: CallbackInteractable = _spot(factory, pos, Vector3(0.2, 0.05, 0.3), Color(0.8, 0.75, 0.3), func(): return "Al: %s'nin kimliği" % w["name"], func(_p): pass)
	sp.action_fn = func(_p):
		if give_worker(worker_id):
			sp.queue_free()


func _on_cabinet_open() -> void:
	_complete("ch3_infirmary_code")
	_spawn_worker_spot("zeynep", Vector3(15.3, Y + 1.0, 12.5))


# ------------------------------------------------------------------ sahne
func _worker_spot(pos: Vector3, prompt: String, worker_id: String, size := Vector3(0.28, 0.12, 0.2)) -> void:
	_spot(factory, pos, size, Color(0.75, 0.72, 0.55), func(): return prompt, func(_p): give_worker(worker_id))


func _locker(n: int, x: float, who: String, text: String, worker_id := "") -> void:
	_box(factory, Vector3(x, Y + 1.0, 15.5), Vector3(0.6, 2.0, 0.5), Color(0.28, 0.32, 0.3))
	_spot(factory, Vector3(x, Y + 1.5, 15.2), Vector3(0.45, 0.3, 0.05), Color(0.7, 0.7, 0.62), func(): return "İncele: Dolap %d" % n, func(_p):
		AudioManager.say("Dolap %d — %s. %s" % [n, who, text], 5.0)
		if worker_id != "":
			give_worker(worker_id))


func _build_props() -> void:
	# --- Soyunma (6 dolap kuzey duvarda): plakalar revir kodunun üçüncü ipucudur
	_locker(1, -15.0, "Hasan Çelik", "Dolabın içinde bir kimlik kartı var.", "hasan")
	_locker(2, -13.6, "Ayşe Yıldız", "Dolabın içinde bir kimlik kartı var.", "ayse")
	_locker(3, -12.2, "Fatma Demirci", "Dolabın içinde bir kimlik kartı var.", "fatma")
	_locker(4, -10.8, "Zeynep Aksoy", "İçinde yalnızca beyaz bir önlük var.")
	_locker(5, -9.4, "Mehmet Kaya", "Boş. Anahtarı arşivde kalmış olmalı.")
	_locker(6, -8.0, "Kemal Arslan", "Boş. Kimliğini yemekhanede unutmuş olmalı.")

	# --- Yemekhane: masa, sandalye, çorba; mutfak tezgâhı (isteğe bağlı Elif)
	_box(factory, Vector3(0.0, Y + 0.4, 12.5), Vector3(2.4, 0.8, 1.0), Color(0.3, 0.25, 0.2))
	_chair = _box(factory, Vector3(0.0, Y + 0.45, 11.4), Vector3(0.5, 0.9, 0.5), Color(0.25, 0.2, 0.16))
	_spot(factory, Vector3(0.4, Y + 0.85, 12.5), Vector3(0.3, 0.1, 0.3), Color(0.8, 0.6, 0.3), func(): return "İncele: Çorba", func(_p): soup())
	_box(factory, Vector3(3.0, Y + 0.45, 15.4), Vector3(3.0, 0.9, 0.6), Color(0.35, 0.35, 0.33))
	_worker_spot(Vector3(3.0, Y + 0.95, 15.4), "Tezgâh: bir kimlik", "elif")

	# --- Revir: yatak (isteğe bağlı Ramazan), defter, dolap notu, ilaç dolabı (kod 264)
	_box(factory, Vector3(8.2, Y + 0.25, 13.5), Vector3(0.9, 0.5, 2.0), Color(0.6, 0.6, 0.62))
	_worker_spot(Vector3(8.2, Y + 0.6, 13.5), "Yatağın altı: bir kimlik", "ramazan")
	_box(factory, Vector3(13.5, Y + 0.4, 8.8), Vector3(2.0, 0.8, 0.8), Color(0.3, 0.25, 0.2))
	_doc(Vector3(13.0, Y + 0.83, 8.8), "Revir defteri", "03.02 Ayşe Yıldız — baş ağrısı. 03.09 Kemal Arslan — el yarası. 03.14 Z. Aksoy — baş dönmesi (kendi kaydı).")
	_doc(Vector3(14.0, Y + 0.83, 8.8), "İlaç dolabı notu", "KOD: son üç hastanın dolap numaraları, geliş sırasıyla, arka arkaya. — Z.A.")
	var kp := Keypad.new()
	kp.position = Vector3(15.5, Y + 1.0, 12.5)
	kp.code = CABINET_CODE
	kp.power_flag = ""
	kp.unlock_flag = "ch3_cabinet_open"
	kp.quest_id = "ch3_infirmary_code"
	kp.title_text = "İlaç dolabı — 3 haneli kod"
	kp.ok_text = "Dolap açıldı. İçinde Zeynep'in kimliği var."
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.5, 2.0, 1.0)
	mi.mesh = bm
	mi.material_override = _mat(Color(0.7, 0.72, 0.7))
	kp.add_child(mi)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(0.6, 2.0, 1.1)
	cs.shape = bs
	kp.add_child(cs)
	factory.add_child(kp)
	kp.unlocked.connect(_on_cabinet_open)
	_cabinet = kp

	# --- Arşiv: masa üstünde dosyalar (Mehmet ana rota; Nuray, Cemal, Hüseyin isteğe bağlı)
	_box(factory, Vector3(-13.0, Y + 0.45, 0.0), Vector3(3.2, 0.9, 1.0), Color(0.3, 0.25, 0.2))
	_worker_spot(Vector3(-14.2, Y + 0.95, 0.0), "Çekmece: M. Kaya", "mehmet")
	_worker_spot(Vector3(-13.2, Y + 0.95, 0.0), "Dosya: N. Polat", "nuray")
	_worker_spot(Vector3(-12.2, Y + 0.95, 0.0), "Dosya: C. Erdem", "cemal")
	_worker_spot(Vector3(-11.2, Y + 0.95, 0.0), "Dosya: H. Taş", "huseyin")

	# --- Personel bürosu: Yusuf'un kartı
	_box(factory, Vector3(0.0, Y + 0.45, 3.0), Vector3(2.4, 0.9, 1.0), Color(0.3, 0.25, 0.2))
	_doc(Vector3(-0.7, Y + 0.93, 3.0), "Sayım defteri", "Vardiya sayımı: on bir isim yazılı, on ikinci satır boş bırakılmış. Altında: 'Y. Demir onayladı.'")
	_pickup(Vector3(0.6, Y + 0.95, 3.0), "yusuf_card", "ch3_yusuf_card")
