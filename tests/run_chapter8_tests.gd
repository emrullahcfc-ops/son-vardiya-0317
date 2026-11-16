extends SceneTree
## Aşama 17 testleri: godot --headless --fixed-fps 60 --path . --script tests/run_chapter8_tests.gd
## Final kaçış rotası, Sayıcı final devriyesi (güvenli pencereler), enerji kararı (USB kopyala / elektriği kes),
## personel defteri (imzala/kapat/rapor), turnike ve sayım kararı, FinalInput, 12 karar yolunun tamamı, kayıt.

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
var sc: Node
var subs: Array = []
var SY: GDScript


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
	SY = load("res://scripts/enemy/sayici.gd")
	await process_frame
	await _run()
	print("")
	if not finished:
		failures.append("test sonuna ulaşılamadı (çalışma hatası)")
	if failures.is_empty():
		print("TÜM BÖLÜM 8 TESTLERİ GEÇTİ")
		quit(0)
	else:
		print("BAŞARISIZ: ", failures)
		quit(1)


func _worker_ids() -> Array:
	return load("res://scripts/data/worker_data.gd").ids()


func _frames(n: int) -> void:
	for _i in n:
		await physics_frame


func _fresh() -> void:
	gm.flags.clear()
	gm.visited_areas.clear()
	gm.checkpoint_pos = []
	gm.current_chapter = 8
	gm.time_state = "2026"
	gm.save_blocked = false
	gm.deaths_total = 0
	qm.clear()
	inv._items.clear()
	hd._fired.clear()
	hd.cooldown = 0.0
	sv.delete_save()
	for f in ["ch1_done", "ch2_done", "ch2_chase_done", "ch3_done", "ch4_done", "ch4_tape", "ch5_done", "ch6_done", "ch6_choice", "ch7_done", "ch7_tape", "final_route_open"]:
		gm.set_flag(f)
	gm.flags["final_choice"] = "protect"
	gm.flags["evidence"] = ["tag_ayse", "tag_kemal", "tag_zeynep", "tag_hasan", "tag_fatma", "tag_mehmet", "shoes_1", "trace_nails", "photo_scene"]
	inv.add_item("usb_drive")
	inv.add_item("worker_id_ayse")
	inv.add_item("worker_id_kemal")


func _load() -> void:
	if level != null and is_instance_valid(level):
		level.queue_free()
		await _frames(2)
	level = load("res://scenes/world/factory.tscn").instantiate()
	root.add_child(level)
	pl = level.player
	ch = level.find_children("*", "Chapter8", false, false)[0]
	ch._wait = false
	sc = level.find_children("*", "SayiciController", false, false)[0]
	level.find_children("*", "Chapter2", false, false)[0].chase_enabled = false
	level.find_children("*", "Chapter5", false, false)[0].chase_enabled = false
	await _frames(60)


func _place(p: Vector3) -> void:
	pl.global_position = p
	pl.velocity = Vector3.ZERO


func _spot(prefix: String) -> Node:
	for c in level.get_children():
		if "prompt_fn" in c and c.get_prompt().begins_with(prefix):
			return c
	return null


func _reset_ch8() -> void:
	for k in ["ch8_started", "ch8_energy", "ch8_backup", "ch8_ledger", "ch8_count", "ch8_done", "ending_pending", "final_input"]:
		gm.flags.erase(k)
	qm.clear()
	ch.copying = false
	ch.copy_progress = 0.0
	ch._begin()


func _run() -> void:
	_fresh()
	await _load()

	print("Başlangıç ve kaçış rotası")
	_check(gm.has_flag("ch8_started") and qm.is_active("ch8_escape") and qm.is_active("ch8_energy") and qm.is_active("ch8_ledger") and qm.is_active("ch8_exit"), "Bölüm 8 görevleri başladı")
	var map: RID = level.get_world_3d().navigation_map
	var path: PackedVector3Array = NavigationServer3D.map_get_path(map, Vector3(-11, -4, -18), Vector3(-1.8, 0, 12.0), true)
	var plen := 0.0
	for i in range(1, path.size()):
		plen += path[i].distance_to(path[i - 1])
	var ymin := 0.0
	for v in path:
		ymin = minf(ymin, v.y)
	_check(path.size() > 5 and path[path.size() - 1].distance_to(Vector3(-1.8, 0.2, 12.0)) < 1.5, "Mühürlü Alan'dan turnikeye yol var (bodrum → üretim → hol): %.0f m" % plen)
	_check(ymin < -3.5 and plen < 160.0, "rota bodrumdan çıkar (en alt %.1f) ve makul uzunlukta" % ymin)
	for id in [["Güvenlik bilgisayarı", "Güvenlik bilgisayarı"], ["Personel defteri", "Personel defteri"], ["Turnike", "Turnike"]]:
		_check(_spot(id[0]) != null, "etkileşim noktası: %s" % id[1])

	print("Kilit sırası: karar olmadan çıkış yok")
	_check(ch.use_ledger() == "no_energy", "enerji kararı olmadan defter kilitli (net mesaj)")
	_check(ch.use_turnstile() == "locked", "kararlar olmadan turnike kilitli")
	_check(ch.decide_ledger("sign") == "no_energy", "enerji kararı olmadan defter yazılamaz")

	print("Sayıcı final devriyesi ve güvenli pencereler")
	_place(Vector3(0, 0.1, 22))   # dış alan: sessiz
	gm.enter_area("g_entry", "Giriş")
	var sy: Node = sc.sayici
	_check(sy != null and absf(sy.patrol_speed - 2.0) < 0.01 and sy.waypoint_pause == 4.0, "final devriyesi: daha hızlı (2,0), noktalarda 4 sn bekler")
	var ts := Vector3(-1.8, 0.0, 13.3)
	var win_best := 0.0
	var win_cur := 0.0
	var windows := 0
	var passes := 0
	var near := false
	var was_win := false
	for i in 10800:   # 180 sn
		await physics_frame
		var d: float = Vector2(sy.global_position.x - ts.x, sy.global_position.z - ts.z).length()
		if d > 12.0:
			win_cur += 1.0 / 60.0
			if win_cur >= 15.0 and not was_win:
				windows += 1
				was_win = true
		else:
			win_best = maxf(win_best, win_cur)
			win_cur = 0.0
			was_win = false
		if d < 4.0 and not near:
			passes += 1
			near = true
		elif d > 6.0:
			near = false
		if sy.state != SY.State.PATROL:
			break
	win_best = maxf(win_best, win_cur)
	_check(sy.state == SY.State.PATROL, "oyuncu sessizken Sayıcı devriyeden çıkmaz (şüphe yok)")
	_check(windows >= 2, "turnike çevresinde en az 2 güvenli pencere (Sayıcı >12 m uzakta, ≥15 sn): %d, en uzun %.0f sn" % [windows, win_best])
	_check(passes >= 1, "Sayıcı turnike çevresinden de geçer (rota boş değil): %d geçiş" % passes)
	var hides := 0
	for h in get_nodes_in_group("hide_spots"):
		hides += 1
	_check(hides >= 3, "rota boyunca saklanma dolapları var (%d)" % hides)
	if is_instance_valid(sy):
		sy.queue_free()
	sc.sayici = null
	await _frames(3)

	print("Enerji kararı: elektriği kes")
	var dim_before: float = get_nodes_in_group("room_light")[0].light_energy
	_check(ch.decide_energy("belki") == "invalid", "geçersiz seçenek reddedilir")
	_check(ch.decide_energy("cut") == "cut" and ch.energy_choice() == "cut", "elektrik kesildi")
	_check(get_nodes_in_group("room_light")[0].light_energy < dim_before * 0.5, "ışıklar kısıldı")
	_check(sc.sayici == null and qm.is_completed("ch8_energy"), "Sayıcı susar, enerji görevi tamamlandı")
	_check(ch.decide_energy("backup") == "already" and ch.energy_choice() == "cut", "karar bir kez verilir")
	_check(not gm.has_flag("ch8_backup"), "elektrik kesilince yedek alınmaz")

	print("Defter ve turnike (kesme yolu)")
	_check(ch.decide_ledger("belki") == "invalid", "geçersiz defter seçeneği reddedilir")
	_check(ch.decide_ledger("report") == "report" and qm.is_completed("ch8_ledger"), "rapor bırakıldı")
	_check(String(subs.back()).contains("rapor eksik"), "yedek yokken rapor eksik uyarısı")
	_check(ch.decide_ledger("sign") == "already" and ch.ledger_choice() == "report", "defter kararı değişmez")
	_check(ch.decide_count("belki") == "invalid", "geçersiz sayım cevabı reddedilir")
	_check(ch.decide_count("reject") == "reject" and gm.has_flag("ch8_done"), "sayım reddedildi: çıkış tamamlandı")
	_check(qm.is_completed("ch8_exit") and qm.is_completed("ch8_escape"), "çıkış görevleri tamamlandı")
	var fi: Dictionary = gm.flags.get("final_input", {})
	_check(fi.get("energy") == "cut" and fi.get("backup") == false and fi.get("ledger") == "report" and fi.get("report_complete") == false and fi.get("count_decision") == "reject", "final girdisi: seçimler doğru")
	_check(gm.has_flag("ending_pending"), "final çözümleyici bekliyor bayrağı")

	print("Enerji kararı: USB'ye kopyala (terminalde kal)")
	_reset_ch8()
	_place(Vector3(-10.0, 0.1, 13.0))
	await _frames(5)
	inv._items.erase("usb_drive")
	_check(ch.decide_energy("backup") == "no_usb", "USB yoksa kopyalama reddedilir (elektriği kesme yolu açık)")
	inv.add_item("usb_drive")
	sc.sayici = null
	_check(ch.use_terminal() == "ask", "terminal seçim penceresini açar")
	_check(ch.decide_energy("backup") == "copying" and ch.copying, "kopyalama başladı")
	if sc.sayici:
		sc.sayici.queue_free()
		sc.sayici = null
	_check(ch.hud_text().begins_with("KOPYALANIYOR"), "ekranda kopyalama ilerlemesi")
	await _frames(300)   # 5 sn terminalin yanında
	var p5: float = ch.copy_progress
	_check(p5 > 4.5 and p5 < 5.6, "terminalin yanında ilerler (%.1f sn)" % p5)
	_place(Vector3(0, 0.1, 22))   # uzaklaş (dış alan: sayılan alan değil, Sayıcı belirmez)
	await _frames(300)
	_check(absf(ch.copy_progress - p5) < 0.2, "uzaklaşınca duraklar, ilerleme kaybolmaz (%.1f)" % ch.copy_progress)
	_check(ch.hud_text().contains("duraklatıldı"), "ekranda 'duraklatıldı: terminale yaklaş'")
	_place(Vector3(-10.0, 0.1, 13.0))
	await _frames(int((ch.COPY_SECONDS - ch.copy_progress) * 60.0) + 30)
	_check(not ch.copying and ch.energy_choice() == "backup" and gm.has_flag("ch8_backup"), "25 sn tamamlanınca deliller USB'ye kopyalandı")
	_check(qm.is_completed("ch8_energy"), "enerji görevi tamamlandı")

	print("Kopyalama sırasında Sayıcı: saklanma ile")
	_reset_ch8()
	gm.deaths_total = 0
	if sc.sayici:
		sc.sayici.queue_free()
		sc.sayici = null
	_place(Vector3(-12.0, 0.1, 13.2))
	await _frames(5)
	_check(ch.decide_energy("backup") == "copying", "(hazırlık) kopyalama başladı")
	_check(sc.sayici != null, "Sayıcı sesi duyup terminale yöneldi")
	sc.sayici.hide_check_chance = 0.0
	var lock: Node = null
	for h in get_nodes_in_group("hide_spots"):
		if h.global_position.distance_to(Vector3(-13.3, 0.0, 15.3)) < 0.6:
			lock = h
	lock.interact(pl)
	_check(pl.hidden, "oyuncu kulübedeki dolaba saklandı (kopyalama menzilinde)")
	var f2 := 0
	while ch.copying and f2 < 3600:
		await physics_frame
		f2 += 1
	_check(not ch.copying and ch.energy_choice() == "backup" and pl.hidden and gm.deaths_total == 0, "dolapta saklanarak kopyalama tamamlandı, yakalanmadı (%.0f sn)" % (f2 / 60.0))
	lock.exit_spot()
	if sc.sayici:
		sc.sayici.queue_free()
		sc.sayici = null
	await _frames(5)

	print("Kopyalama sırasında yakalanma: tekrar deneme")
	_reset_ch8()
	_place(Vector3(-9.5, 0.1, 13.0))
	await _frames(5)
	var died := [0]
	sc.player_died.connect(func(): died[0] += 1)
	ch.decide_energy("backup")
	var f3 := 0
	while died[0] == 0 and f3 < 4000:
		await physics_frame
		f3 += 1
	_check(died[0] == 1 and gm.deaths_total >= 1, "açıkta durursan Sayıcı yakalar (%.0f sn); ölüm sayacı artar" % (f3 / 60.0))
	await _frames(240)
	_check(not ch.copying and ch.copy_progress == 0.0, "ölünce kopyalama sıfırlanır")
	_check(gm.deaths_total >= 1, "ölüm sayısı kontrol noktası yüklemesinde geri sarılmaz")
	_check(ch.energy_choice() == "", "karar verilmemiş sayılır: yeniden seçilebilir")
	_check(ch.decide_energy("cut") == "cut", "tekrar deneme: bu kez elektriği kes")

	print("Final girdisi (tüm bayraklar)")
	_reset_ch8()
	gm.flags["ch8_energy"] = "backup"
	gm.set_flag("ch8_backup")
	gm.set_flag("doc_nuray")
	gm.set_flag("doc_cemal")
	for w in _worker_ids():
		inv.add_item("worker_id_" + w)
	gm.flags["evidence"] = ["photo_scene"]
	for w in _worker_ids():
		gm.flags["evidence"].append("tag_" + w)
	gm.flags["evidence"] += ["shoes_1", "shoes_2", "shoes_3", "trace_nails", "trace_hands", "trace_line"]
	ch.decide_ledger("report")
	ch.decide_count("reject")
	fi = gm.flags.get("final_input", {})
	_check(fi.get("workers") == 11 and fi.get("workers_all") == true, "11 işçi kimliği aktarıldı")
	_check(fi.get("evidence_total") == 18 and fi.get("tags") == 11 and fi.get("shoes") == 3 and fi.get("traces") == 3 and fi.get("photo") == true, "18 delil ve kategorileri aktarıldı")
	_check(fi.get("yusuf_records") == 4 and fi.get("yusuf_all") == true, "4 Yusuf kaydı aktarıldı")
	_check(fi.get("special_docs") == 2, "iki özel belge aktarıldı")
	_check(fi.get("yusuf_choice") == "protect" and fi.get("backup") == true and fi.get("report_complete") == true and fi.get("count_decision") == "reject", "Yusuf seçimi, yedek, eksiksiz rapor ve sayım cevabı aktarıldı")
	for k in ["workers", "tags", "evidence_total", "yusuf_records", "special_docs", "yusuf_choice", "usb", "backup", "energy", "ledger", "report_complete", "count_decision", "deaths"]:
		if not fi.has(k):
			_check(false, "final girdisinde eksik alan: %s" % k)

	print("Özel belgeler (Arşiv)")
	gm.flags.erase("doc_nuray")
	gm.flags.erase("doc_cemal")
	_spot("Oku: Nuray'ın muhasebe defteri").interact(pl)
	_spot("Oku: Cemal'in imzasız bakım iptali").interact(pl)
	_check(gm.has_flag("doc_nuray") and gm.has_flag("doc_cemal"), "iki özel belge okunur ve bayrak olarak kayda geçer")

	print("12 karar yolunun tamamı oynanabilir")
	var all_ok := true
	var combos := 0
	for energy in ["backup", "cut"]:
		for ledger in ["sign", "close", "report"]:
			for count in ["accept", "reject"]:
				_reset_ch8()
				if energy == "backup":
					ch.decide_energy("backup")
					ch.copy_progress = ch.COPY_SECONDS - 0.01
					await _frames(10)
					if sc.sayici:
						sc.sayici.queue_free()
						sc.sayici = null
					_place(Vector3(-10.0, 0.1, 13.0))
					await _frames(10)
				else:
					ch.decide_energy("cut")
				ch.decide_ledger(ledger)
				ch.decide_count(count)
				var r: Dictionary = gm.flags.get("final_input", {})
				var good: bool = gm.has_flag("ch8_done") and gm.has_flag("ending_pending") and r.get("energy") == energy and r.get("ledger") == ledger and r.get("count_decision") == count and r.get("backup") == (energy == "backup") and r.get("report_complete") == (ledger == "report" and energy == "backup") and qm.is_completed("ch8_exit")
				combos += 1
				if not good:
					all_ok = false
					print("    başarısız yol: ", energy, " / ", ledger, " / ", count, " -> ", r)
	_check(all_ok and combos == 12, "enerji × defter × sayım = %d yolun tamamı bitişe ulaşır ve doğru girdi üretir" % combos)

	print("Kayıt")
	_check(sv.save_game(), "kaydedildi")
	gm.flags.clear()
	gm.current_chapter = 1
	qm.clear()
	inv._items.clear()
	_check(sv.load_game(), "yüklendi")
	_check(gm.has_flag("ch8_done") and gm.has_flag("ending_pending") and gm.flags.get("final_input", {}).get("count_decision") == "reject" or gm.flags.get("final_input", {}).get("count_decision") == "accept", "final girdisi ve bitiş bayrağı kayıtla korunur")

	level.queue_free()
	sv.delete_save()
	finished = true
