extends SceneTree
## Aşama 15 testleri: godot --headless --fixed-fps 60 --path . --script tests/run_chapter6_tests.gd
## Üç bulmaca (beton + 2004 geçişi, 041117 kodu, şalter panosu), 2004 atmosferi, 11 işçi koridoru, uzayan koridor kaçışı,
## Yusuf telefon seçimi (kayıtlı, finale taşınır, geçmiş değişmez), şalter sahnesi, ölüm/tekrar, kayıt.

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
var tl: Node
var sc: Node
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
		print("TÜM BÖLÜM 6 TESTLERİ GEÇTİ")
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
	gm.current_chapter = 6
	gm.time_state = "2026"
	gm.save_blocked = false
	qm.clear()
	inv._items.clear()
	hd._fired.clear()
	hd.cooldown = 0.0
	sv.delete_save()
	for f in ["ch1_done", "ch2_done", "ch2_chase_done", "ch3_done", "ch4_done", "ch4_evidence", "ch5_fans", "ch5_chase_done", "ch5_done"]:
		gm.set_flag(f)
	inv.add_item("usb_drive")
	inv.add_item("yusuf_card")
	inv.add_item("worker_id_ayse")


func _load() -> void:
	if level != null and is_instance_valid(level):
		level.queue_free()
		await _frames(2)
	level = load("res://scenes/world/factory.tscn").instantiate()
	root.add_child(level)
	pl = level.player
	tl = level.time_layers
	tl.instant = true
	ch = level.find_children("*", "Chapter6", false, false)[0]
	ch.chase_wait = false
	sc = level.find_children("*", "SayiciController", false, false)[0]
	level.find_children("*", "Chapter2", false, false)[0].chase_enabled = false
	level.find_children("*", "Chapter5", false, false)[0].chase_enabled = false
	await _frames(60)


func _spot(prefix: String) -> Node:
	for c in level.get_children():
		if "prompt_fn" in c and c.get_prompt().begins_with(prefix):
			return c
	return null


func _keypad(code: String) -> Node:
	for c in level.get_children():
		if c.has_method("try_code") and c.code == code:
			return c
	return null


func _reader() -> Node:
	for c in level.get_children():
		if "required_item" in c and c.required_item == "yusuf_card" and c.has_method("get_prompt") and not ("item_id" in c):
			return c
	return null


func _cast(from: Vector3, to: Vector3) -> float:
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.7
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = cap
	q.transform = Transform3D(Basis(), from + Vector3(0, 0.9, 0))
	q.motion = to - from
	q.collision_mask = 1
	var r: Array = level.get_world_3d().direct_space_state.cast_motion(q)
	return 1.0 if r.is_empty() else float(r[0])


func _walk_to(xmax: float, speed := 3.0, track := true) -> Dictionary:
	var min_gap := 999.0
	var frames := 0
	var gaps_at_loops: Array = []
	var last_loops: int = ch.loops
	while pl.global_position.x < xmax and frames < 6000:
		pl.global_position = Vector3(pl.global_position.x + speed / 60.0, 0.1, ch.Z0)
		pl.velocity = Vector3.ZERO
		await physics_frame
		frames += 1
		if track and sc.sayici != null and is_instance_valid(sc.sayici):
			min_gap = minf(min_gap, absf(pl.global_position.x - sc.sayici.global_position.x))
			if ch.loops != last_loops:
				gaps_at_loops.append(pl.global_position.x - sc.sayici.global_position.x)
				last_loops = ch.loops
		if ch.end_reached:
			break
	return {"min_gap": min_gap, "frames": frames, "gaps_at_loops": gaps_at_loops}


func _run() -> void:
	_fresh()
	await _load()

	print("Bölüm 6 başlangıcı")
	_check(gm.has_flag("ch6_started") and qm.is_active("ch6_alcove") and qm.is_active("ch6_locker") and qm.is_active("ch6_breaker"), "Bölüm 6 görevleri başladı")
	_check(gm.time_state == "2026", "bölüm 2026'da başlar")

	print("Bulmaca 1: beton duvar, 2004 geçişi")
	var z_ok := _cast(Vector3(12.5, 0.0, 12.0), Vector3(14.2, 0.0, 12.0))
	_check(z_ok < 0.99, "2026: Yükleme deposunun doğu ucu betonla kapalı (kapsül geçemez: %.2f)" % z_ok)
	_check(_spot("Vardiya terminali").visible == false, "2026: terminal yok (2004'e özel)")
	_spot("Vardiya terminali").interact(pl)
	_check(not gm.has_flag("ch6_code_seen"), "2026'da terminal kullanılamaz")
	subs.clear()
	_spot("İncele: Beton duvar").interact(pl)
	_check(subs.any(func(t): return "2004" in String(t)), "ipucu: beton duvar notu 2004'e yönlendirir")
	var rd := _reader()
	_check(rd != null and rd.get_prompt().contains("2004"), "kart okuyucu 2004'e geçmeyi sunar")
	await _frames(240)
	rd.interact(pl)
	await _frames(5)
	_check(gm.time_state == "2004", "Yusuf'un kartıyla 2004'e geçildi")
	var z_open := _cast(Vector3(12.5, 0.0, 12.0), Vector3(14.2, 0.0, 12.0))
	_check(z_open > 0.99, "2004: beton yok, depoya geçilir (%.2f)" % z_open)
	_check(_spot("İncele: Beton duvar").visible == false, "2004: beton not alanı da yok")

	print("2004 atmosferi")
	var workers := get_nodes_in_group("time_2004").filter(func(n): return String(n.name).begins_with("TimeNpc_"))
	_check(workers.size() >= 14, "2004: işçi siluetleri (%d: 3 hat + 11 koridor)" % workers.size())
	var ch2: Node = level.find_children("*", "Chapter2", false, false)[0]
	var mat: StandardMaterial3D = ch2._machines["B"].material_override
	_check(mat.emission_enabled, "2004: makineler çalışıyor (parlıyor)")
	_check(au.has_layer("machine"), "2004: makine sesi çalıyor")

	print("Bulmaca 2: 041117 kodu (2004 terminali → 2026 dolabı)")
	subs.clear()
	_spot("Vardiya terminali").interact(pl)
	_check(gm.has_flag("ch6_code_seen") and qm.is_completed("ch6_alcove"), "terminal okundu, görev ilerledi")
	var rx := RegEx.new()
	rx.compile("(\\d\\d)-(\\d\\d)-(\\d\\d)")
	var m := rx.search(String(subs[0]))
	var derived: String = m.get_string(1) + m.get_string(2) + m.get_string(3)
	_check(derived == "041117", "terminal metninden çıkan kod 041117 (%s)" % derived)
	_check(_keypad("041117").visible == false, "2004'te 2026 dolabı yok")
	await _frames(240)
	rd.interact(pl)
	await _frames(5)
	_check(gm.time_state == "2026", "2026'ya dönüldü")
	var kp := _keypad("041117")
	_check(kp.visible, "2026: vardiya dolabı görünür")
	subs.clear()
	_spot("Oku: dolap etiketi").interact(pl)
	_check(subs.any(func(t): return "altı hane" in String(t) and "kayıt" in String(t)), "etiket ipucu: şifre = kapanış kayıt numarası (altı hane)")
	_check(not kp.try_code("123456") and not kp.try_code("041118"), "yanlış kodlar reddedilir, tekrar deneme serbest")
	_check(_spot("Al: şalter kolu") == null, "kod girilmeden kol görünmez")
	_check(kp.try_code(derived) and qm.is_completed("ch6_locker"), "terminalden alınan kod dolabı açar")
	var hs := _spot("Al: şalter kolu")
	_check(hs != null, "dolap açılınca şalter kolu belirir")
	hs.interact(pl)
	_check(inv.has_item("breaker_handle") and gm.has_flag("pickup_ch6_handle"), "şalter kolu alındı")

	print("Bulmaca 3: şalter panosu")
	_check(_spot("Ana şalter panosu").visible == false, "2026: pano yok (2004'e özel)")
	await _frames(240)
	rd.interact(pl)
	await _frames(5)
	var panel := _spot("Ana şalter panosu")
	_check(panel.visible and gm.time_state == "2004", "2004: bakım odasında ana şalter panosu")
	inv._items.erase("breaker_handle")
	_check(ch.use_breaker_panel() == "no_handle" and not ch.corridor_active, "kol olmadan pano çalışmaz (net mesaj)")
	inv.add_item("breaker_handle")
	var before_flags: Dictionary = gm.flags.duplicate(true)
	var before_items: Array = inv._items.duplicate()
	var before_visited: Array = gm.visited_areas.duplicate()
	pl.global_position = Vector3(0, 0.15, -9)
	await _frames(3)
	_check(ch.use_breaker_panel() == "ok", "kolla pano çalışır: zaman bozulur")
	await _frames(10)
	_check(ch.corridor_active and gm.time_state == "2004" and qm.is_completed("ch6_breaker") and qm.is_active("ch6_corridor"), "koridor sahnesi başladı")
	_check(pl.global_position.x > ch.X0 + 10.0, "oyuncu koridora alındı (x=%.0f)" % pl.global_position.x)
	_check(sc.sayici != null and absf(sc.sayici.chase_speed - ch.CHASER_SPEED) < 0.01 and sc.sayici.chase_speed < 3.0, "Sayıcı kovalıyor ama yürümeden yavaş (%.1f m/sn)" % sc.sayici.chase_speed)
	var npcs := get_nodes_in_group("time_2004").filter(func(n): return String(n.name).begins_with("TimeNpc_kor"))
	_check(npcs.size() == 11, "koridorda 11 işçi iki yanda duruyor")

	print("Uzayan koridor kaçışı")
	var gap0: float = pl.global_position.x - sc.sayici.global_position.x
	_check(ch.pull_switch() == "not_ready", "şalter koridor sonuna varmadan kullanılamaz")
	var r := await _walk_to(ch.X0 + 200.0, 3.0)
	_check(ch.loops == 3, "koridor 3 kez uzadı (%d)" % ch.loops)
	_check(r["gaps_at_loops"].size() == 3 and (r["gaps_at_loops"] as Array).all(func(g): return absf(g - gap0) < 12.0 or g > 4.0), "uzama sırasında Sayıcı ile mesafe korunur %s" % str(r["gaps_at_loops"]))
	_check(r["min_gap"] > 1.5, "durmadan yürüyen oyuncu hiç yakalanmadı (en yakın %.1f m)" % r["min_gap"])
	_check(ch.end_reached, "koridorun sonuna ulaşıldı")
	_check(sc.sayici != null and not sc.sayici.enabled, "sona varınca zaman durur: Sayıcı donar")
	_check(ch._choice_ui != null, "Yusuf'un telefonu: seçim penceresi açıldı")

	print("Yusuf telefonu: iki seçenek, geçmiş değişmez")
	_check(ch.pull_switch() == "no_choice", "cevap vermeden şalter indirilemez")
	_check(ch.choose("belki") == "invalid", "geçersiz seçenek reddedilir")
	_check(ch.choose("protect") == "protect", "seçenek B kaydedildi (koru)")
	_check(gm.flags.get("ch6_choice") == "protect" and gm.flags.get("final_choice") == "protect", "seçim bayrağı finale taşınacak şekilde kayıtlı")
	_check(ch.choose("expose") == "already" and gm.flags.get("final_choice") == "protect", "ikinci cevap kabul edilmez: geçmiş değişmez")
	var intact := true
	for k in before_flags:
		if k in ["ch6_breaker_used"]:
			continue
		if not gm.flags.has(k) or gm.flags[k] != before_flags[k]:
			intact = false
	_check(intact, "seçimden önceki tüm bayraklar aynı kaldı")
	_check(inv._items == before_items.duplicate() or (before_items.all(func(i): return inv._items.has(i))), "envanter değişmedi")
	_check(before_visited.all(func(a): return gm.visited_areas.has(a)), "daha önce ziyaret edilen alanlar silinmedi")

	print("Şalter sahnesi ve dönüş")
	await _frames(5)
	_check(ch.pull_switch() == "ok", "şalter indirilir")
	await _frames(30)
	_check(gm.has_flag("ch6_done") and qm.is_completed("ch6_corridor"), "Bölüm 6 tamamlandı")
	_check(gm.time_state == "2026" and not ch.corridor_active, "2026'ya dönüldü")
	_check(pl.global_position.distance_to(ch.MAINT_RETURN) < 2.0 and not tl.is_blocked(pl.global_position), "oyuncu bakım odasında güvenli konumda")
	_check(sc.sayici == null or sc.sayici.global_position.x < 40.0, "koridordaki Sayıcı kaldırıldı (varsa fabrikadaki devriyedir)")
	_check(gm.current_chapter == 7, "Bölüm 7'ye geçiş")
	_check(pl.controls_enabled and not gm.save_blocked, "kontroller açık, kayıt kilidi yok")

	print("Kayıt")
	gm.flags.clear()
	gm.current_chapter = 1
	qm.clear()
	inv._items.clear()
	_check(sv.load_game(), "kayıt yüklenir")
	_check(gm.current_chapter == 7 and gm.flags.get("final_choice") == "protect" and gm.has_flag("ch6_done"), "Bölüm 7 geçişi ve seçim bayrağı kayıtla korunur")
	_check(inv.has_item("breaker_handle") and gm.time_state == "2026", "eşya ve zaman durumu korunur")

	print("Ölüm ve tekrar (koridor)")
	_fresh()
	await _load()
	inv.add_item("breaker_handle")
	gm.set_time_state("2004")
	tl.apply("2004")
	pl.global_position = Vector3(0, 0.15, -9)
	await _frames(5)
	var died := [0]
	sc.player_died.connect(func(): died[0] += 1)
	ch.use_breaker_panel()
	await _frames(10)
	_check(ch.corridor_active, "koridor başladı (2. senaryo)")
	var f := 0
	while died[0] == 0 and f < 3000:
		await physics_frame
		f += 1
	_check(died[0] == 1, "koridorda durursan Sayıcı yakalar (%.1f sn)" % (f / 60.0))
	await _frames(240)
	_check(not ch.corridor_active and pl.global_position.distance_to(Vector3(0, 0.15, -9)) < 1.5, "ölünce bakım odasındaki kontrol noktasına dönülür")
	_check(inv.has_item("breaker_handle") and gm.time_state == "2004", "kol kaybolmaz; zaman durumu tutarlı (2004)")
	_check(not tl.is_blocked(pl.global_position), "dönüşte oyuncu duvar içinde değil")
	_check(ch.use_breaker_panel() == "ok", "pano yeniden kullanılır: tekrar denenebilir")
	await _frames(10)
	_check(ch.corridor_active and sc.sayici != null, "koridor yeniden başladı")

	level.queue_free()
	sv.delete_save()
	finished = true
