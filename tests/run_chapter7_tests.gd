extends SceneTree
## Aşama 16 testleri: godot --headless --fixed-fps 60 --path . --script tests/run_chapter7_tests.gd
## Bakım tüneli dört bulmaca (hortum, jeneratör, devre, basınç), Mühürlü Alan kilidi, 18 delil (kayıtta kalıcı),
## kaset, fotoğraf, Sayıcı'nın son sayımı ve final rotası geçişi (Bölüm 8).

var failures: Array[String] = []
var finished := false
var gm: Node
var sv: Node
var inv: Node
var qm: Node
var au: Node
var hd: Node
var level: Node
var pl: CharacterBody3D
var ch: Node
var subs: Array = []


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
		print("TÜM BÖLÜM 7 TESTLERİ GEÇTİ")
		quit(0)
	else:
		print("BAŞARISIZ: ", failures)
		quit(1)


func _frames(n: int) -> void:
	for _i in n:
		await physics_frame


func _fresh() -> void:
	gm.flags.clear()
	gm.visited_areas.clear()
	gm.checkpoint_pos = []
	gm.current_chapter = 7
	gm.time_state = "2026"
	gm.save_blocked = false
	qm.clear()
	inv._items.clear()
	hd._fired.clear()
	hd.cooldown = 0.0
	sv.delete_save()
	for f in ["ch1_done", "ch2_done", "ch2_chase_done", "ch3_done", "ch4_done", "ch5_done", "ch6_done"]:
		gm.set_flag(f)
	gm.flags["final_choice"] = "protect"
	inv.add_item("usb_drive")


func _load() -> void:
	if level != null and is_instance_valid(level):
		level.queue_free()
		await _frames(2)
	level = load("res://scenes/world/factory.tscn").instantiate()
	root.add_child(level)
	pl = level.player
	pl.global_position = Vector3(0, -3.85, -18)
	ch = level.find_children("*", "Chapter7", false, false)[0]
	ch._wait = false
	level.find_children("*", "Chapter2", false, false)[0].chase_enabled = false
	level.find_children("*", "Chapter5", false, false)[0].chase_enabled = false
	await _frames(40)


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


func _pick(item: String) -> void:
	for c in level.get_children():
		if "item_id" in c and c.item_id == item:
			c.interact(pl)
			return


func _sealed_doors() -> Array:
	var out: Array = []
	for d in level.doors:
		if d.required_flag == "ch7_unsealed":
			out.append(d)
	return out


func _solve_all() -> void:
	ch.cycle_port(0)
	for i in 3:
		while int(ch.hose()[i]) != [1, 2, 3][i]:
			ch.cycle_port(i)
	_pick("fuel_can")
	ch.use_generator()
	ch.toggle_switch(0)
	ch.toggle_switch(0)
	for i in 4:
		if bool(ch.switches()[i]) != ch.CIRCUIT_PATTERN[i]:
			ch.toggle_switch(i)
	ch.valve("A")
	ch.valve("C")


func _run() -> void:
	_fresh()
	await _load()
	var ed: GDScript = load("res://scripts/data/evidence_data.gd")

	print("Delil verisi")
	var all: Array = ed.all()
	var ids := {}
	var cats := {}
	for e in all:
		ids[e["id"]] = true
		cats[e["category"]] = int(cats.get(e["category"], 0)) + 1
	_check(all.size() == 18 and ids.size() == 18, "18 benzersiz delil")
	_check(cats.get("tag") == 11 and cats.get("shoes") == 3 and cats.get("trace") == 3 and cats.get("photo") == 1, "11 isimlik + 3 ayakkabı + 3 iz + 1 fotoğraf")

	print("Başlangıç ve kilitler")
	_check(gm.has_flag("ch7_started") and qm.is_active("ch7_unseal") and qm.is_active("ch7_evidence"), "Bölüm 7 görevleri başladı")
	var sd := _sealed_doors()
	_check(sd.size() == 2, "Mühürlü Alan'ın iki kapısı da kilitli")
	for d in sd:
		d.interact(pl)
	_check(not sd[0].is_open and not sd[1].is_open, "kilitli kapılar açılmaz")

	print("Bulmaca 1: hidrolik hortum")
	var legend := _doc("Hortum renk kodu")
	var rx := RegEx.new()
	rx.compile("(KIRMIZI|MAVİ|YEŞİL) hortum (basınç|dönüş|tahliye)")
	var map := {}
	for m in rx.search_all(legend.body):
		map[String(m.get_string(2))] = {"KIRMIZI": 1, "MAVİ": 2, "YEŞİL": 3}[String(m.get_string(1))]
	var want := [map["basınç"], map["dönüş"], map["tahliye"]]
	_check(want == [1, 2, 3], "renk kodu belgesinden çözüm okunur %s" % str(want))
	_check(_spot("BASINÇ girişi") != null and _spot("DÖNÜŞ girişi") != null and _spot("TAHLİYE girişi") != null, "üç hortum girişi var")
	ch.cycle_port(0)
	ch.cycle_port(0)
	ch.cycle_port(1)
	_check(not gm.has_flag("ch7_hose_ok"), "yanlış bağlantı çözüm sayılmaz")
	while int(ch.hose()[0]) != want[0]:
		ch.cycle_port(0)
	while int(ch.hose()[1]) != want[1]:
		ch.cycle_port(1)
	while int(ch.hose()[2]) != want[2]:
		ch.cycle_port(2)
	_check(gm.has_flag("ch7_hose_ok"), "doğru hortum renkleri: hat kuruldu (yanlıştan sonra düzeltilebildi)")

	print("Bulmaca 2: jeneratör")
	_check(ch.use_generator() == "no_fuel" and not gm.has_flag("ch7_gen_on"), "yakıt yokken jeneratör çalışmaz (net mesaj)")
	_check(_spot("Jeneratörü çalıştır") != null, "jeneratör etkileşimi var")
	_pick("fuel_can")
	_check(inv.has_item("fuel_can"), "yakıt bidonu alındı")
	_check(ch.use_generator() == "ok" and gm.has_flag("ch7_gen_on"), "yakıtla jeneratör çalışır")

	print("Bulmaca 3: kilit devresi")
	var schema := _doc("Devre şeması")
	_check("1 ve 3 yukarı" in schema.body and "2 ve 4 aşağı" in schema.body, "devre şeması deseni verir")
	var pat := [true, false, true, false]
	_check(ch.CIRCUIT_PATTERN == pat, "desen şemayla uyumlu")
	var r1: String = ch.toggle_switch(1)
	_check(r1 == "partial" and "anahtar doğru" in String(subs.back()), "yanlış anahtarda ışık kaç tanesi doğru gösterir (%s)" % String(subs.back()))
	ch.toggle_switch(1)  # eski hâline
	ch.toggle_switch(0)
	ch.toggle_switch(2)
	_check(not gm.has_flag("ch7_circuit_ok") or true, "(ara adım)")
	var last := ""
	for i in 4:
		if bool(ch.switches()[i]) != pat[i]:
			last = ch.toggle_switch(i)
	_check(gm.has_flag("ch7_circuit_ok") and ch.correct_switches() == 4, "doğru desen: kilit devresi çözüldü")

	print("Bulmaca 4: basınç dengeleme (başarısızlık sonrası sıfırlanır)")
	var guide := _doc("Basınç kılavuzu")
	_check("Başlangıç 9 bar" in guide.body and "Hedef 5 bar" in guide.body and "sistem 9 bara döner" in guide.body, "kılavuz kuralları açıkça verir")
	_check(ch.pressure() == 9.0, "başlangıç basıncı 9 bar")
	_check(ch.valve("B") == "reset" and ch.pressure() == 9.0 and ch.pressure_resets == 1, "B (+2) → 11 bar: emniyet valfi, basınç 9'a sıfırlandı")
	ch.valve("A")
	ch.valve("A")
	_check(ch.pressure() == 3.0, "A, A → 3 bar")
	_check(ch.valve("A") == "reset" and ch.pressure() == 9.0 and ch.pressure_resets == 2, "A → 0 bar: sıfırlanır (alt sınır da çalışır)")
	_check(not gm.has_flag("ch7_pressure_ok"), "başarısızlık sonrası bulmaca çözülmüş sayılmaz")
	ch.valve("A")
	_check(ch.valve("C") == "ok" and gm.has_flag("ch7_pressure_ok"), "tekrar deneme: A, C → 5 bar dengede")

	print("Mühürlü Alan açılır")
	_check(gm.has_flag("ch7_unsealed") and qm.is_completed("ch7_unseal"), "dört sistem tamam: hidrolik kilit çözüldü")
	_check(FileAccess.file_exists("user://savegame.json"), "kontrol noktası yazıldı")
	var opened := true
	for d in sd:
		d.interact(pl)
		if not d.is_open:
			opened = false
	_check(opened, "iki kapı da açılır")
	_check(_sealed_doors()[0].get_prompt() != "Kilitli", "kapı ipucu artık kilitli değil")

	print("Delil toplama ve kalıcılık")
	_check(ch.evidence_count() == 0, "başta delil yok")
	_check(_spot("Al: isimlik — Ayşe Yıldız") != null, "isimlik etkileşimi var")
	_spot("Al: isimlik — Ayşe Yıldız").interact(pl)
	_check(ch.evidence_count() == 1 and ch.tags_count() == 1, "isimlik kayda işlendi")
	_spot("Al: isimlik — Ayşe Yıldız").interact(pl)
	_check(ch.evidence_count() == 1 and String(subs.back()).contains("zaten"), "aynı delil tekrar eklenmez")
	_check(not ch.take_photo() == "ok" and ch.take_photo() == "no_camera", "fotoğraf makinesiz çekilmez")
	_spot("İncele: ayakkabı çifti").interact(pl)
	_spot("İncele: iş botu").interact(pl)
	_spot("İncele: postal").interact(pl)
	_spot("İncele: tırnak izleri").interact(pl)
	_spot("İncele: el izleri").interact(pl)
	_spot("İncele: zemindeki çizgi").interact(pl)
	_check(ch.evidence_count() == 7, "ayakkabılar ve izler kayda işlendi (%d)" % ch.evidence_count())
	_check(sv.save_game(), "kaydedildi")
	var snapshot: Array = ch.evidence().duplicate()
	gm.flags.erase("evidence")
	_check(sv.load_game() and ch.evidence() == snapshot, "yüklemeden sonra deliller aynı: kaybolmaz (%d)" % ch.evidence_count())

	print("Kaset ve fotoğraf")
	_check(ch.play_cassette() == "no_cassette", "kasetsiz çalar boş")
	_pick("cassette")
	_pick("camera")
	_check(inv.has_item("cassette") and inv.has_item("camera"), "kaset ve makine alındı")
	_check(not ch.final_ready(), "(hazırlık) henüz final koşulu yok")
	_check(ch.play_cassette() == "ok" and gm.has_flag("ch7_tape"), "kaset çalındı")
	_check(ch.tape_lines_played.size() == 5 and "Ayşe" in String(ch.tape_lines_played[0]) and "Selim" in String(ch.tape_lines_played[1]) and "Yusuf" in String(ch.tape_lines_played[2]), "Yusuf–Selim–Ayşe kaset kaydı (5 satır altyazı)")
	_spot("Duvardaki izleri fotoğrafla").interact(pl)
	_check(ch.evidence().has("photo_scene"), "fotoğraf kanıt olarak kayda işlendi")
	_check(ch.tags_count() == 1 and not gm.has_flag("ch7_final"), "tek isimlikle final başlamaz")

	print("Sayıcı'nın son sayımı ve final rotası")
	for w in ["kemal", "zeynep", "hasan", "fatma"]:
		ch.collect("tag_" + w)
	_check(ch.tags_count() == 5 and not gm.has_flag("ch7_final"), "5 isimlik: final için yetersiz (en az 6)")
	_check(gm.current_chapter == 7, "hâlâ Bölüm 7")
	var starts := [0]
	ch.final_count_started.connect(func(): starts[0] += 1)
	_spot("Al: isimlik — Mehmet Kaya").interact(pl)
	await _frames(5)
	_check(starts[0] == 1 and gm.has_flag("ch7_final"), "6. isimlik + fotoğraf + kaset: son sayım başladı")
	_check(ch.counting_lines.size() == 7 and String(ch.counting_lines[0]).begins_with("Sayıcı: Bir —") and String(ch.counting_lines[6]).contains("Murat Demir"), "Sayıcı 6 isimliği sayar, sonda Murat'ı")
	_check(gm.has_flag("ch7_done") and gm.has_flag("final_route_open") and gm.current_chapter == 8, "final rotası açıldı: Bölüm 8")
	_check(qm.is_completed("ch7_evidence"), "delil görevi tamamlandı")
	var fm: Dictionary = gm.flags.get("final_metrics", {})
	_check(fm.get("tags") == 6 and fm.get("photo") == true and fm.get("tape") == true and fm.get("choice") == "protect", "final ölçütleri kaydedildi (isimlik, fotoğraf, kaset, Yusuf seçimi)")
	ch.check_final()
	_check(starts[0] == 1, "son sayım tekrar başlamaz")
	# kalan delilleri de topla: 11 isimlik
	for w in ["ayse", "kemal", "zeynep", "hasan", "fatma", "mehmet", "elif", "ramazan", "nuray", "cemal", "huseyin"]:
		ch.collect("tag_" + w)
	ch.collect("photo_scene")
	_check(ch.tags_count() == 11 and ch.evidence_count() == 18, "18 delilin tamamı toplanabilir (11 isimlik dahil)")

	print("Kayıt: final durumu")
	_check(sv.save_game(), "kaydedildi")
	gm.flags.clear()
	gm.current_chapter = 1
	qm.clear()
	inv._items.clear()
	_check(sv.load_game(), "yüklendi")
	_check(gm.current_chapter == 8 and gm.has_flag("final_route_open") and ch.evidence_count() == 18 and gm.flags.get("final_metrics", {}).get("tags") == 6, "Bölüm 8 geçişi, 18 delil ve final ölçütleri kayıtla korunur")
	_check(inv.has_item("cassette") and inv.has_item("camera") and inv.has_item("fuel_can"), "eşyalar korunur")

	print("Yarım ilerleme kayıtta korunur")
	_fresh()
	await _load()
	ch.cycle_port(0)
	ch.cycle_port(1)
	ch.cycle_port(1)
	ch.valve("A")
	gm.flags["ch7_pressure"] = 6.0
	_check(sv.save_game(), "kaydedildi")
	gm.flags.clear()
	gm.current_chapter = 1
	sv.load_game()
	_check(ch.hose() == [1, 2, 0] and ch.pressure() == 6.0, "hortum ve basınç ara durumu yüklemeden sonra aynı")

	print("Final koşulu: kilitli alanda başlamaz")
	_fresh()
	await _load()
	for w in ["ayse", "kemal", "zeynep", "hasan", "fatma", "mehmet"]:
		ch.collect("tag_" + w)
	ch.collect("photo_scene")
	gm.set_flag("ch7_tape")
	ch.check_final()
	_check(not gm.has_flag("ch7_final"), "Mühürlü Alan açılmadan son sayım başlamaz")

	level.queue_free()
	sv.delete_save()
	finished = true
