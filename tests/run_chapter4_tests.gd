extends SceneTree
## Aşama 11 testleri: godot --headless --path . --script tests/run_chapter4_tests.gd
## 6 kamera, klip oynatma, doğru sırada işaretleme (yanlışta sıfırlama/tekrar), canlı kamera korkusu,
## Selim–Yusuf kaydı, bodrum görevi, Bölüm 5 geçişi, kayıt, monitör arayüzü.

var failures: Array[String] = []
var finished := false
var gm: Node
var sv: Node
var inv: Node
var qm: Node
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
	await process_frame
	await _run()
	print("")
	if not finished:
		failures.append("test sonuna ulaşılamadı (çalışma hatası)")
	if failures.is_empty():
		print("TÜM BÖLÜM 4 TESTLERİ GEÇTİ")
		quit(0)
	else:
		print("BAŞARISIZ: ", failures)
		quit(1)


func _fresh(with_ch3_done := true) -> void:
	gm.flags.clear()
	gm.visited_areas.clear()
	gm.checkpoint_pos = []
	gm.current_chapter = 4 if with_ch3_done else 3
	qm.clear()
	inv._items.clear()
	root.get_node("HorrorDirector")._fired.clear()
	sv.delete_save()
	if with_ch3_done:
		gm.set_flag("ch3_done")
	gm.set_flag("ch2_chase_done")
	gm.set_flag("ch2_done")


func _load_level() -> void:
	level = load("res://scenes/world/factory.tscn").instantiate()
	root.add_child(level)
	await physics_frame
	await physics_frame
	pl = level.player
	ch = level.find_children("*", "Chapter4", false, false)[0]
	ch._wait = false
	level.find_children("*", "Chapter2", false, false)[0].chase_enabled = false


func _actor_count() -> int:
	var n := 0
	for c in level.get_children():
		if String(c.name).begins_with("CctvActor_"):
			n += 1
	return n


func _run() -> void:
	_fresh()
	await _load_level()
	var cd: GDScript = load("res://scripts/data/cctv_data.gd")

	print("Veri")
	_check(cd.CAMERAS.size() == 6, "6 kamera tanımlı")
	var times := []
	for id in cd.ORDER:
		times.append(String(cd.get_clip(id)["time"]))
	_check(times == ["03.14", "03.16", "03.17"], "kritik klipler: 03.14, 03.16, 03.17")
	var crit := 0
	var decoys := 0
	for c in cd.CLIPS:
		if c["critical"]:
			crit += 1
		else:
			decoys += 1
	_check(crit == 3 and decoys >= 4, "3 kritik + %d ilgisiz (yanıltıcı) klip" % decoys)
	var cams_ok := true
	for c in cd.CLIPS:
		if cd.get_camera(c["cam"]).is_empty():
			cams_ok = false
	_check(cams_ok, "her klip geçerli bir kameraya bağlı")
	_check(cd.TAPE.size() >= 5 and String(cd.TAPE[0]).begins_with("Selim") and String(cd.TAPE[1]).begins_with("Yusuf"), "Selim–Yusuf kaydı tanımlı")

	print("Başlangıç")
	_check(qm.is_active("ch4_mark_evidence"), "Bölüm 4 görevi aktif")
	_check(ch.monitors_on(), "monitörler Bölüm 3 bitince açık")

	print("İşaretleme sırası")
	_check(ch.mark_clip("c_0314") == "not_seen", "izlemeden işaretlenmez")
	ch.play_clip("c_0306")
	_check(ch.mark_clip("c_0306") == "decoy", "ilgisiz klip işaretlenmez (rutin kayıt)")
	_check(ch.marks().is_empty(), "ilgisiz işaret kayıt dışı")
	ch.play_clip("c_0317")
	_check(_actor_count() == 11, "03.17 klibinde 11 işçi figürü yürür (%d)" % _actor_count())
	_check(ch.played_lines.any(func(t): return String(t).begins_with("[Anons]")), "03.17 klibinde anons altyazısı")
	_check(ch.mark_clip("c_0317") == "wrong_order", "yanlış sıra: 03.17 önce işaretlenemez")
	_check(ch.marks().is_empty(), "yanlış sırada işaretler sıfırlandı")
	ch.stop_clip()
	_check(_actor_count() == 0, "klip durunca figürler silinir")
	ch.play_clip("c_0314")
	_check(ch.mark_clip("c_0314") == "ok" and ch.marks() == ["c_0314"], "03.14 doğru: 1/3")
	ch.play_clip("c_0317")
	_check(ch.mark_clip("c_0317") == "wrong_order" and ch.marks().is_empty(), "03.16'yı atlayınca sıfırlanır (tekrar deneme)")

	print("Canlı kamera korkusu")
	_check(not ch.live_view_entered("k5"), "hiç işaret yokken korku tetiklenmez")
	_check(not ch.live_view_entered("k3"), "K5 dışındaki kamerada tetiklenmez")
	ch.play_clip("c_0314")
	ch.mark_clip("c_0314")
	_check(ch.live_view_entered("k5"), "bir işaret sonrası K5 canlıda siluet + anons")
	_check(ch.scare_node != null and ch.scare_node.global_position.distance_to(Vector3(14.2, 4.9, 2.0)) < 2.5, "siluet sandalyenin hemen arkasında")
	ch.live_view_left()
	_check(ch.scare_node == null, "ekran değişince siluet kaybolur (arkana bakınca kimse yok)")
	_check(not ch.live_view_entered("k5"), "korku yalnızca bir kez")

	print("Kayıt: yarım ilerleme korunur")
	_check(sv.save_game(), "kaydedildi")
	gm.flags.clear()
	gm.current_chapter = 1
	_check(sv.load_game() and ch.marks() == ["c_0314"] and gm.current_chapter == 4, "1/3 işaret ve bölüm yüklemede korunur")
	_check(ch.has_seen("c_0314"), "izlenen klipler korunur")

	print("Doğru sıra: delil tamamlanır")
	ch.play_clip("c_0316")
	_check(ch.mark_clip("c_0316") == "ok", "03.16 doğru: 2/3")
	ch.play_clip("c_0317")
	_check(ch.mark_clip("c_0317") == "ok_done", "03.17 doğru: delil tamamlandı")
	await process_frame
	_check(gm.has_flag("ch4_evidence") and qm.is_completed("ch4_mark_evidence"), "görev tamamlandı")
	_check(inv.has_item("usb_drive"), "kayıtlar USB belleğe kopyalandı")
	_check(ch.tape_lines.size() == 6 and "Yusuf" in String(ch.tape_lines[1]), "Selim–Yusuf ses kaydı oynatıldı (6 satır)")
	_check(qm.is_active("ch4_basement"), "görev güncellemesi: bodruma in")
	_check(gm.current_chapter == 5 and gm.has_flag("ch4_done"), "Bölüm 5'e geçiş")
	_check(ch.mark_clip("c_0314") == "already", "tamamlanınca tekrar işaretlenmez")
	level.queue_free()
	await process_frame
	gm.flags.clear()
	gm.current_chapter = 1
	qm.clear()
	inv._items.clear()
	_check(sv.load_game() and gm.current_chapter == 5 and qm.is_active("ch4_basement") and inv.has_item("usb_drive"), "Bölüm 5 geçişi, görev ve USB kayıtla korunur")

	print("Monitör arayüzü")
	_fresh(false)
	await _load_level()
	_check(not ch.open_monitor() and ch.ui == null, "Bölüm 3 bitmeden monitör kapalı")
	gm.set_flag("ch3_done")
	_check(ch.open_monitor() and ch.ui != null, "monitör açılır")
	await process_frame
	_check(not pl.controls_enabled, "monitör açıkken oyuncu kontrolü kapalı")
	var btns := 0
	for k in ch.ui._cam_buttons:
		btns += 1
	_check(btns == 6, "arayüzde 6 kamera düğmesi")
	ch.ui.select_camera("k3")
	await process_frame
	_check(ch.ui.cam_id == "k3", "kamera seçilir")
	ch.ui.play("c_0314")
	await process_frame
	_check(ch.current_clip == "c_0314", "arayüzden klip oynatılır")
	_check(ch.ui.mark_current() == "ok", "arayüzden işaretlenir")
	ch.close_monitor()
	await process_frame
	_check(ch.ui == null and pl.controls_enabled, "kapatınca kontrol geri gelir")
	_check(ch.current_clip == "", "kapatınca klip durur")
	level.queue_free()
	sv.delete_save()
	finished = true
