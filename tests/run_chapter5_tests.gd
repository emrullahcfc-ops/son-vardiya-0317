extends SceneTree
## Aşama 13 testleri: godot --headless --fixed-fps 60 --path . --script tests/run_chapter5_tests.gd
## Gaz modeli, filtre kaynağı (iki tam deneme), gazlı alanlar, fan sırası F2→F1→F3 (belgeden, yanlışta toparlanma),
## Sayıcı kovalamacası (buhar perdesi + saklanma, ölüm/tekrar), Yusuf onayı, interkom, kayıt.

var failures: Array[String] = []
var finished := false
var gm: Node
var sv: Node
var inv: Node
var qm: Node
var au: Node
var hd: Node
var level: Node
var pl: Node
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
		print("TÜM BÖLÜM 5 TESTLERİ GEÇTİ")
		quit(0)
	else:
		print("BAŞARISIZ: ", failures)
		quit(1)


func _frames(n: int) -> void:
	for _i in n:
		await physics_frame


func _fresh_state() -> void:
	gm.flags.clear()
	gm.visited_areas.clear()
	gm.checkpoint_pos = []
	gm.current_chapter = 5
	qm.clear()
	inv._items.clear()
	hd._fired.clear()
	hd.cooldown = 0.0
	sv.delete_save()
	for f in ["ch2_done", "ch2_chase_done", "ch3_done", "ch4_done"]:
		gm.set_flag(f)
	inv.add_item("usb_drive")
	inv.add_item("yusuf_card")


func _load() -> void:
	if level != null and is_instance_valid(level):
		level.queue_free()
		await _frames(2)
	_fresh_state()
	level = load("res://scenes/world/factory.tscn").instantiate()
	root.add_child(level)
	pl = level.player
	ch = level.find_children("*", "Chapter5", false, false)[0]
	sc = level.find_children("*", "SayiciController", false, false)[0]
	ch._wait = false
	ch.steam_duration = 12.0
	level.find_children("*", "Chapter2", false, false)[0].chase_enabled = false
	await _frames(60)


func _place(p: Vector3) -> void:
	pl.global_position = p
	pl.velocity = Vector3.ZERO


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _walk(points: Array, speed := 3.0) -> void:
	for wp in points:
		var guard := 0
		while _flat(pl.global_position, wp) > 0.05 and guard < 2000:
			var d := Vector2(wp.x - pl.global_position.x, wp.z - pl.global_position.z)
			var step := minf(speed / 60.0, d.length())
			var n := d.normalized() * step
			pl.global_position = Vector3(pl.global_position.x + n.x, pl.global_position.y, pl.global_position.z + n.y)
			await physics_frame
			guard += 1


func _spot(prefix: String, near := Vector3.INF) -> Node:
	for c in level.get_children():
		if "prompt_fn" in c and c.get_prompt().begins_with(prefix):
			if near == Vector3.INF or c.global_position.distance_to(near) < 1.0:
				return c
	return null


func _doc(title: String) -> Node:
	for c in level.get_children():
		if "title" in c and "body" in c and c.title == title:
			return c
	return null


func _pickup(item: String) -> Node:
	for c in level.get_children():
		if "item_id" in c and c.item_id == item:
			return c
	return null


func _enter_basement() -> void:
	_place(Vector3(18, -3.9, -6))
	await _frames(3)
	gm.enter_area("b_land", "Bodrum inişi", false)


func _route_attempt() -> Dictionary:
	# Bodrum inişinde başla: filtre dolabı → boru → fan odası (filtre + 3 fan) → pompa → kontrol odası
	await _enter_basement()
	ch.take_from_locker()
	await _walk([Vector3(18, -3.9, -8), Vector3(11, -3.9, -8), Vector3(9.8, -3.9, -6.0)])
	ch.take_filter("pipe")
	await _walk([Vector3(11, -3.9, -8), Vector3(11, -3.9, -13)])
	await _walk([Vector3(11, -3.9, -17), Vector3(8.8, -3.9, -21.0)])
	ch.take_filter("fan")
	await _walk([Vector3(14.5, -3.9, -17)])
	ch.press_fan(2)
	await _frames(300)
	ch.press_fan(1)
	await _frames(300)
	ch.press_fan(3)
	await _walk([Vector3(11, -3.9, -13), Vector3(11, -3.9, -8), Vector3(0, -3.9, -8), Vector3(-11, -3.9, -8)])
	return {"collapsed": ch._dead, "exposure": ch.exposure, "fans": gm.has_flag("ch5_fans"), "filters_left": ch.filters(), "filter_left": ch.filter_left(), "deaths": ch.deaths}


func _run() -> void:
	await _load()

	print("Kaynak dengesi (iki tam deneme)")
	var need := int(ceil(ch.ROUTE_GAS_SECONDS / ch.FILTER_SECONDS))
	var supply: int = ch.LOCKER_STOCK + 2
	_check(supply >= 2 * need, "dünyadaki filtre (%d) iki tam rota denemesine yeter (rota ≈ %d filtre)" % [supply, need])
	_check(ch.CARRY_MAX >= need, "bir seferde taşınabilir filtre (%d) bir rotaya yeter" % ch.CARRY_MAX)

	print("Bodrum başlangıcı")
	await _enter_basement()
	_check(gm.has_flag("ch5_started") and qm.is_active("ch5_fans") and qm.is_active("ch5_seal"), "bodruma inince görevler başlar")
	_check(FileAccess.file_exists("user://savegame.json"), "kontrol noktası yazıldı")
	var meter := _pickup("gas_meter")
	meter.interact(pl)
	_check(inv.has_item("gas_meter"), "gaz ölçer alındı")
	_check(ch.take_from_locker() == 3 and ch.filters() == 3 and ch.locker_stock() == 2, "yedek dolap: 3 filtre alındı, dolapta 2 kaldı")
	_check(ch.take_from_locker() == 0 and ch.locker_stock() == 2, "taşıma sınırı: fazla alınmaz, dolap korunur")

	print("Gaz modeli")
	ch.exposure = 0.0
	ch._set_filters(1)
	ch._set_filter_left(0.0)
	subs.clear()
	ch.tick(1.0, 0.04)
	_check(ch.filters() == 0 and absf(ch.filter_left() - 29.0) < 0.01 and ch.exposure == 0.0, "gazda filtre otomatik takılır; filtreliyken zehirlenme yok")
	for i in 22:
		ch.tick(1.0, 0.04)
	_check(subs.any(func(t): return "bitmek üzere" in String(t)), "uyarı: filtre bitmek üzere (yedek yok)")
	for i in 8:
		ch.tick(1.0, 0.04)
	_check(ch.filter_left() == 0.0 and subs.any(func(t): return "Filtre bitti" in String(t)), "net sonuç: 'Filtre bitti!' mesajı")
	ch.tick(10.0, 0.04)
	_check(absf(ch.exposure - 0.44) < 0.01, "filtresiz maruziyet yoğunluk × süre kadar artar (%.2f)" % ch.exposure)
	ch.tick(5.0, 0.0)
	_check(ch.exposure < 0.05, "gazdan çıkınca toparlanır (%.2f)" % ch.exposure)
	_check(ch.hud_text().contains("FİLTRE YOK") == false, "gazsızken 'filtre yok' alarmı yok")
	ch._set_filters(0)
	ch._in["b_pipe"] = true
	_check(ch.hud_text().contains("FİLTRE YOK"), "gazdayken filtresiz: ekranda 'FİLTRE YOK — GAZDAN ÇIK'")
	ch._in.clear()

	print("Gazlı alanlar")
	var zone_ok := true
	for t in [["b_pipe", Vector3(11, -3.9, -8), 0.04], ["b_fan", Vector3(11, -3.9, -18), 0.06], ["b_pump", Vector3(0, -3.9, -8), 0.07], ["b_ctrl", Vector3(-11, -3.9, -8), 0.09], ["b_land", Vector3(18, -3.9, -8), 0.0]]:
		_place(t[1])
		await _frames(4)
		if absf(ch.density_here() - t[2]) > 0.001:
			zone_ok = false
			print("    alan ", t[0], " beklenen ", t[2], " bulunan ", ch.density_here())
	_check(zone_ok, "oda içindeki gaz yoğunluğu alana göre (boru 0.04 … kontrol 0.09, iniş 0)")

	print("Fan bulmacası")
	var guide := _doc("Havalandırma kılavuzu")
	var note := _doc("Kazancı Hüseyin'in notu")
	_check(guide != null and note != null, "iki ipucu belgesi var (kılavuz + kazancı notu)")
	var rx := RegEx.new()
	rx.compile("F(\\d), ardından F(\\d), en son F(\\d)")
	var m := rx.search(guide.body)
	var order := [int(m.get_string(1)), int(m.get_string(2)), int(m.get_string(3))]
	_check(order == [2, 1, 3], "kılavuzdan çıkan fan sırası F2, F1, F3 %s" % str(order))
	_check("iki" in note.body and note.body.find("bir") > note.body.find("iki") and note.body.find("üç") > note.body.find("bir"), "ikinci ipucu aynı sırayı söyler (iki, bir, üç)")
	ch._set_filters(0)
	ch._set_filter_left(0.0)
	ch.exposure = 0.0
	_place(Vector3(14.5, -3.9, -17))
	_check(ch.press_fan(1) == "wrong" and ch.fan_sequence().is_empty(), "yanlış sıra (F1 önce): sistem sıfırlanır")
	_check(absf(ch.exposure - 0.25) < 0.01 and not ch._dead, "yanlış girişte ani gaz (+0.25) ama ölümcül değil; toparlanılır")
	_check(ch.press_fan(2) == "ok" and ch.press_fan(3) == "wrong", "F2 doğru, F3 yanlış → sıfırlanır")
	_check(ch.exposure <= 0.9 and not ch._dead, "tekrarlayan hata ölümcül olmaz (üst sınır 0.9)")
	ch.exposure = 0.0
	_check(ch.press_fan(2) == "ok" and ch.press_fan(1) == "ok" and ch.press_fan(3) == "ok_done", "doğru sıra F2 → F1 → F3 tamamlanır (tekrar deneme sonrası)")
	_check(gm.has_flag("ch5_fans") and qm.is_completed("ch5_fans"), "görev tamamlandı")
	_check(ch.density_of("b_pump") == 0.0 and ch.density_of("b_ctrl") == 0.0 and ch.density_of("b_pipe") > 0.0, "fanlar pompa ve kontrol odasını temizler; boru hâlâ hafif gazlı")

	print("Sayıcı kovalamacası: ilk deneme (ölüm)")
	gm.checkpoint_pos = [14.5, -3.9, -17.0, 0.0]   # fan tamamlanma kontrol noktası
	sv.save_game()
	_place(Vector3(3, -3.9, -8))
	await _frames(4)
	gm.enter_area("b_pump", "Pompa")
	_check(ch.chase_active and sc.sayici != null and sc.sayici.state == SY.State.CHASE, "pompa odasına girince Sayıcı merdivenden inip kovalar")
	var died := [0]
	sc.player_died.connect(func(): died[0] += 1)
	var f := 0
	while died[0] == 0 and f < 2400:
		await physics_frame
		f += 1
	_check(died[0] == 1, "durağan oyuncu yakalanır (%.1f sn)" % (f / 60.0))
	await _frames(240)
	_check(pl.global_position.distance_to(Vector3(14.5, -3.9, -17.0)) < 0.6, "ölünce fan kontrol noktasına dönülür")
	_check(gm.has_flag("ch5_fans") and not ch.chase_active and sc.sayici == null, "fanlar çözülmüş kalır; kovalamaca sıfırlanır")

	print("Kovalamaca: ikinci deneme (buhar perdesi + saklanma)")
	_place(Vector3(3, -3.9, -8))
	await _frames(4)
	gm.enter_area("b_pump", "Pompa", true)
	_check(ch.chase_active and sc.sayici != null, "kovalamaca yeniden başlar (tekrarlanabilir)")
	var sy: Node = sc.sayici
	sy.hide_check_chance = 0.0
	_spot("Buhar vanasını aç").interact(pl)
	_check(ch.steam_on and ch._steam_body.collision_layer == 16, "vana: buhar perdesi görüşü keser, hareketi engellemez")
	# görüş testi (Sayıcı perdenin doğu tarafında, oyuncu batısında)
	var save_pos: Vector3 = sy.global_position
	var save_state: int = sy.state
	sy.global_position = Vector3(10, -3.95, -8)
	sy.rotation.y = PI / 2.0
	_place(Vector3(3, -3.9, -8))
	await _frames(3)
	_check(not sy.can_see_player(), "buhar perdesi açıkken Sayıcı oyuncuyu göremez")
	ch._steam(false)
	await _frames(3)
	_check(sy.can_see_player(), "(karşılaştırma) perde yokken görür")
	ch._steam(true)
	sy.global_position = save_pos
	sy._set_state(save_state)
	# saklanma rotası: pompa dolabı
	var lock: Node = null
	for h in get_nodes_in_group("hide_spots"):
		if h.global_position.distance_to(Vector3(-3.5, -4.0, -11.4)) < 0.6:
			lock = h
	_check(lock != null, "pompa odasında saklanma dolabı var")
	await _walk([Vector3(-3.5, -3.9, -10.0)], 5.5)
	lock.interact(pl)
	_check(pl.hidden, "oyuncu dolaba saklandı (görülmeden)")
	var g := 0
	while ch.chase_active and g < 3600:
		await physics_frame
		g += 1
	_check(not ch.chase_active and gm.has_flag("ch5_chase_done"), "Sayıcı aramayı bırakınca kovalamaca biter (%.1f sn)" % (g / 60.0))
	await _frames(200)
	_check(sc.sayici == null, "Sayıcı geri çekildi")
	lock.exit_spot()

	print("Mühür panosu, Yusuf onayı, interkom")
	var panel: Node = _spot("Mühür panosu")
	# koşullar
	var keep_card: bool = inv.has_item("yusuf_card")
	inv._items.erase("yusuf_card")
	_check(ch.use_panel() == "no_card", "Yusuf'un kartı olmadan panel çalışmaz")
	inv.add_item("yusuf_card")
	gm.flags.erase("ch5_chase_done")
	_check(ch.use_panel() == "no_chase", "Sayıcı'dan kurtulmadan panel çalışmaz")
	gm.set_flag("ch5_chase_done")
	var fired := []
	hd.event_fired.connect(func(id): fired.append(id))
	hd._fired.clear()
	gm.enter_area("b_ctrl", "Kontrol")
	_check(fired.has("ev_intercom"), "kontrol odasına girince interkom kadın sesi olayı")
	_check(panel.get_prompt() == "Mühür panosu", "pano etkileşimi var")
	panel.interact(pl)
	_check(gm.has_flag("ch5_done") and qm.is_completed("ch5_seal") and qm.is_completed("ch4_basement"), "Yusuf'un kartıyla onay: görevler tamamlandı")
	_check(ch.approval_lines.size() == 3 and "Yusuf" in String(ch.approval_lines[1]) and "kadın sesi" in String(ch.approval_lines[2]), "elektronik onay + interkom kadın sesi satırları")
	_check(gm.current_chapter == 6, "Bölüm 6'ya geçiş")
	_check(ch.use_panel() == "done", "tekrar kullanılabilir, bozulmaz")

	print("Kayıt")
	gm.flags.clear()
	gm.current_chapter = 1
	qm.clear()
	inv._items.clear()
	_check(sv.load_game(), "kayıt yüklenir")
	_check(gm.current_chapter == 6 and gm.has_flag("ch5_done") and gm.has_flag("ch5_fans"), "Bölüm 6 geçişi ve bölüm bayrakları korunur")
	_check(inv.has_item("gas_meter"), "gaz ölçer korunur")

	print("Tam rota denemesi 1")
	await _load()
	var r1 := await _route_attempt()
	_check(r1["fans"] and not r1["collapsed"] and r1["exposure"] < 1.0, "1. deneme: gaz ölçer + filtrelerle rota tamamlanır (zehirlenme %.2f, kalan filtre %d)" % [r1["exposure"], r1["filters_left"]])
	_check(r1["deaths"] == 0, "1. denemede ölüm yok")

	print("Tam rota denemesi 2 (yeni deneme, aynı dağıtım)")
	await _load()
	var r2 := await _route_attempt()
	_check(r2["fans"] and not r2["collapsed"] and r2["exposure"] < 1.0, "2. deneme: rota yine tamamlanır (zehirlenme %.2f, kalan filtre %d)" % [r2["exposure"], r2["filters_left"]])

	print("Filtre tükenince: anlaşılır sonuç, softlock yok")
	await _load()
	await _enter_basement()
	ch.take_from_locker()
	_check(ch.filters() == 3, "(hazırlık) 3 filtre ile kontrol noktası")
	sv.save_game()
	ch._set_filters(0)
	ch._set_filter_left(0.0)
	gm.flags["ch5_locker"] = 0
	_check(ch.take_from_locker() == 0 and "boş" in String(subs.back()), "yedek dolap boşken net mesaj: kutuları ara")
	_place(Vector3(11, -3.9, -8))
	await _frames(4)
	var col := [false]
	ch.collapsed.connect(func(): col[0] = true)
	var h2 := 0
	while not col[0] and h2 < 3000:
		await physics_frame
		h2 += 1
	_check(col[0], "filtresiz gazda kalınca zehirlenip bayılınca bildirim (%.0f sn)" % (h2 / 60.0))
	await _frames(240)
	_check(not ch._dead and ch.exposure == 0.0, "bayılma sonrası oyun devam eder (donma yok)")
	_check(pl.controls_enabled and pl.global_position.distance_to(Vector3(18, -3.9, -6)) < 1.0, "kontrol noktasına dönüldü, kontroller açık")
	_check(ch.filters() == 3 and ch.locker_stock() == 2, "kontrol noktası kaynakları geri yükler: 3 filtre, dolapta 2 (softlock yok)")

	level.queue_free()
	sv.delete_save()
	finished = true
