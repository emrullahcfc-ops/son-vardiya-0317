extends SceneTree
## Aşama 10 testleri: godot --headless --path . --script tests/run_chapter3_tests.gd
## 11 işçi kimliği (6 zorunlu + 5 isteğe bağlı), revir kodu 264 (belgelerden), yemekhane olayları,
## Yusuf'un kartı, Sayıcı sayımı, Bölüm 4 geçişi ve kayıt.

var failures: Array[String] = []
var finished := false
var gm: Node
var sv: Node
var inv: Node
var qm: Node
var au: Node
var hd: Node
var subs: Array = []
var level: Node
var pl: Node
var ch: Node


func _check(cond: bool, name: String) -> void:
	print("  ", "PASS" if cond else "FAIL", "  ", name)
	if not cond:
		failures.append(name)


func _initialize() -> void:
	var names := {
		"GameManager": "res://scripts/autoload/game_manager.gd",
		"SaveManager": "res://scripts/autoload/save_manager.gd",
		"QuestManager": "res://scripts/autoload/quest_manager.gd",
		"InventoryManager": "res://scripts/autoload/inventory_manager.gd",
		"AudioManager": "res://scripts/autoload/audio_manager.gd",
		"HorrorDirector": "res://scripts/autoload/horror_director.gd",
	}
	for n in names:
		if root.get_node_or_null(n) == null:
			var node := Node.new()
			node.name = n
			node.set_script(load(names[n]))
			root.add_child(node)
	gm = root.get_node("GameManager")
	sv = root.get_node("SaveManager")
	inv = root.get_node("InventoryManager")
	qm = root.get_node("QuestManager")
	au = root.get_node("AudioManager")
	hd = root.get_node("HorrorDirector")
	au.subtitle.connect(func(t, _d): subs.append(t))
	await process_frame
	await _run()
	print("")
	if not finished:
		failures.append("test sonuna ulaşılamadı (çalışma hatası)")
	if failures.is_empty():
		print("TÜM BÖLÜM 3 TESTLERİ GEÇTİ")
		quit(0)
	else:
		print("BAŞARISIZ: ", failures)
		quit(1)


func _spot(prefix: String) -> Node:
	for c in level.get_children():
		if "prompt_fn" in c and c.get_prompt().begins_with(prefix):
			return c
	return null


func _doc(title: String) -> Node:
	for c in level.get_children():
		if "title" in c and "body" in c and c.title == title:
			return c
	return null


func _door(id: String) -> Node:
	for d in level.doors:
		if d.door_id == id:
			return d
	return null


func _use(prefix: String) -> bool:
	var s := _spot(prefix)
	if s == null:
		return false
	s.interact(pl)
	return true


func _count() -> int:
	var n := 0
	for id in ["ayse", "kemal", "zeynep", "hasan", "fatma", "mehmet", "elif", "ramazan", "nuray", "cemal", "huseyin"]:
		if inv.has_item("worker_id_" + id):
			n += 1
	return n


func _run() -> void:
	gm.flags.clear()
	gm.visited_areas.clear()
	gm.checkpoint_pos = []
	gm.current_chapter = 2
	qm.clear()
	inv._items.clear()
	hd._fired.clear()
	sv.delete_save()
	gm.set_flag("ch2_done")
	gm.set_flag("ch2_chase_done")
	inv.add_item("floor_key")
	level = load("res://scenes/world/factory.tscn").instantiate()
	root.add_child(level)
	await physics_frame
	await physics_frame
	pl = level.player
	ch = level.find_children("*", "Chapter3", false, false)[0]
	ch._wait = false
	level.find_children("*", "Chapter2", false, false)[0].chase_enabled = false
	hd.cooldown = 0.0

	print("Veri tutarlılığı")
	var wd: GDScript = load("res://scripts/data/worker_data.gd")
	var req := 0
	var lockers := {}
	var names_ok := true
	for w in wd.WORKERS:
		if w["required"]:
			req += 1
		lockers[w["locker"]] = true
		if not String(w["bio"]).begins_with(String(w["name"])):
			names_ok = false
	_check(wd.WORKERS.size() == 11, "11 işçi tanımlı")
	_check(req == 6 and wd.WORKERS.size() - req == 5, "6 zorunlu + 5 isteğe bağlı")
	_check(lockers.size() == 11, "dolap numaraları benzersiz")
	_check(names_ok, "her işçi dosyası kendi adıyla başlar (tutarlı)")
	var all_defined := true
	for id in wd.ids():
		if not inv.ITEMS.has("worker_id_" + id):
			all_defined = false
	_check(all_defined, "11 kimlik de envanter tanımında")

	print("Bölüm 3 başlangıcı")
	_check(gm.current_chapter == 2, "başta Bölüm 2")
	for id in ["d16", "d18", "d19"]:
		_check(_door(id).get_prompt() == "Kilitli", "personel bürosu kapısı %s kilitli" % id)
	gm.enter_area("u_stairU", "Merdiven (üst)", false)
	_check(gm.current_chapter == 3 and gm.has_flag("ch3_started"), "merdivenden çıkınca Bölüm 3 başlar")
	_check(qm.is_active("ch3_collect_ids") and qm.is_active("ch3_infirmary_code"), "görevler başladı")
	_check(FileAccess.file_exists("user://savegame.json"), "kontrol noktası yazıldı")
	hd.cooldown = 0.0

	print("Zorunlu altı kimlik (ana rota)")
	_check(_use("İncele: Dolap 1") and inv.has_item("worker_id_hasan"), "dolap 1: Hasan'ın kimliği")
	_check(_use("İncele: Dolap 2") and inv.has_item("worker_id_ayse"), "dolap 2: Ayşe'nin kimliği")
	_check(_use("İncele: Dolap 3") and inv.has_item("worker_id_fatma"), "dolap 3: Fatma'nın kimliği")
	_use("İncele: Dolap 3")
	_check(_count() == 3 and subs.back() == "Bu kimliği zaten aldın.", "aynı kimlik iki kez alınmaz")
	# Yemekhane: çorba / sandalye / Kemal
	_check(_spot("Al: Kemal") == null, "çorba incelenmeden Kemal'in kimliği görünmez")
	subs.clear()
	_use("İncele: Çorba")
	_check(gm.has_flag("ch3_soup") and "Çorba hâlâ sıcak" in String(subs[0]), "çorba olayı: sandalye hareket eder")
	_check(_spot("Al: Kemal") != null, "olaydan sonra Kemal'in kimliği belirir")
	_use("Al: Kemal")
	_check(inv.has_item("worker_id_kemal"), "Kemal'in kimliği alındı")
	_use("İncele: Çorba")
	_check(subs.back().begins_with("Çorba hâlâ sıcak. Sandalye"), "çorba tekrar incelenebilir (olay tekrarlanmaz)")
	# Arşiv: Mehmet
	_use("Çekmece: M. Kaya")
	_check(inv.has_item("worker_id_mehmet") and _count() == 5, "arşiv çekmecesi: Mehmet (5/6)")
	_check(not gm.has_flag("ch3_ids_done") and _door("d16").get_prompt() == "Kilitli", "5 kimlikle büro hâlâ kilitli")

	print("Revir kodu 264: üç ipucu, tahmin yok")
	var log := _doc("Revir defteri")
	var note := _doc("İlaç dolabı notu")
	_check(log != null and note != null, "revir defteri ve dolap notu var")
	_check("geliş sırasıyla" in note.body and "dolap numaraları" in note.body, "ipucu 1: kural (geliş sırası + dolap numaraları)")
	var rx := RegEx.new()
	rx.compile("\\d\\d\\.\\d\\d ([^—]+?) —")
	var order: Array = []
	for m in rx.search_all(log.body):
		order.append(String(m.get_string(1)).split(" ")[-1])
	_check(order == ["Yıldız", "Arslan", "Aksoy"], "ipucu 2: defterden geliş sırası %s" % str(order))
	var plate := {}
	for n in range(1, 7):
		subs.clear()
		_use("İncele: Dolap %d" % n)
		var rx2 := RegEx.new()
		rx2.compile("Dolap (\\d+) — ([^.]+)\\.")
		var mm := rx2.search(String(subs[0]))
		plate[String(mm.get_string(2)).split(" ")[-1]] = mm.get_string(1)
	var derived := ""
	for s in order:
		derived += String(plate.get(s, "?"))
	_check(derived == "264", "ipucu 3: dolap plakalarından kod 264 (%s)" % derived)
	var cab: Node = null
	for c in level.get_children():
		if c.has_method("try_code") and c.code == "264":
			cab = c
	_check(not cab.try_code("123") and not cab.try_code("462"), "yanlış kodlar reddedilir, tekrar deneme serbest")
	_check(_spot("Al: Zeynep") == null, "kod girilmeden Zeynep'in kimliği görünmez")
	_check(cab.try_code(derived) and qm.is_completed("ch3_infirmary_code"), "belgelerden çıkan kod dolabı açar")
	_use("Al: Zeynep")
	_check(inv.has_item("worker_id_zeynep"), "Zeynep'in kimliği alındı")
	_check(gm.has_flag("ch3_ids_done") and _count() == 6, "altı kimlik: ana görev tamamlanır")
	_check(qm.is_completed("ch3_collect_ids") and qm.is_active("ch3_yusuf_card"), "görev: Yusuf'un kartını bul başladı")
	_check(subs.size() > 0 and "personel bürosunun kilidi açıldı" in String(subs.back()), "altıncı kimlikte büro açıldı mesajı")

	print("İsteğe bağlı beş kimlik (toplam 11)")
	for p in ["Tezgâh: bir kimlik", "Yatağın altı: bir kimlik", "Dosya: N. Polat", "Dosya: C. Erdem", "Dosya: H. Taş"]:
		_check(_use(p), "bulundu: %s" % p)
	_check(_count() == 11, "11 kimliğin tamamı toplandı (%d)" % _count())

	print("Kadın silueti (yemekhane)")
	var fired := []
	hd.event_fired.connect(func(id): fired.append(id))
	hd._fired.clear()
	gm.enter_area("u_cant", "Yemekhane")
	_check(fired.has("ev_cant_woman"), "yemekhaneye girince kadın silueti olayı tetiklenir (Bölüm 3)")
	gm.current_chapter = 2
	hd._fired.clear()
	fired.clear()
	gm.enter_area("u_cant", "Yemekhane")
	_check(not fired.has("ev_cant_woman"), "Bölüm 3 öncesi tetiklenmez")
	gm.current_chapter = 3

	print("Yusuf'un kartı ve sayım")
	var d16 := _door("d16")
	_check(d16.get_prompt() != "Kilitli", "büro kapısı açılabilir")
	d16.interact(pl)
	_check(d16.is_open, "büro kapısı açıldı")
	var card: Node = null
	for c in level.get_children():
		if "item_id" in c and c.item_id == "yusuf_card":
			card = c
	_check(card != null and not inv.has_item("yusuf_card"), "Yusuf'un kartı büroda")
	card.interact(pl)
	_check(inv.has_item("yusuf_card"), "Yusuf'un kartı alındı")
	_check(ch.counting_lines.size() == 12, "Sayıcı 12 satır sayar")
	_check(ch.counting_lines[0] == "Sayıcı: Bir." and ch.counting_lines[11] == "Sayıcı: On iki.", "1'den 12'ye sıralı")
	_check(gm.has_flag("ch3_done") and gm.current_chapter == 4, "Bölüm 4'e geçiş")
	_check(qm.is_completed("ch3_yusuf_card"), "Yusuf kartı görevi bitti")
	level.queue_free()
	await process_frame

	print("Kayıt")
	gm.flags.clear()
	gm.current_chapter = 1
	qm.clear()
	inv._items.clear()
	_check(sv.load_game(), "kayıt yüklenir")
	_check(gm.current_chapter == 4 and gm.has_flag("ch3_done"), "Bölüm 4 geçişi kayıtla korunur")
	_check(_count() == 11 and inv.has_item("yusuf_card"), "11 kimlik ve Yusuf'un kartı kayıtta")
	level = load("res://scenes/world/factory.tscn").instantiate()
	root.add_child(level)
	await physics_frame
	level.find_children("*", "Chapter2", false, false)[0].chase_enabled = false
	_check(_spot("Al: Kemal") == null and _spot("Al: Zeynep") == null, "alınan kimlikler yüklemeden sonra tekrar çıkmaz")
	level.queue_free()
	sv.delete_save()
	finished = true
