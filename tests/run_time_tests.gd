extends SceneTree
## Aşama 14 testleri: godot --headless --fixed-fps 60 --path . --script tests/run_time_tests.gd
## İki zaman durumu: katmanlar (ışık/ortam, kapı, eşya, NPC, engel), kontrollü geçiş (kart okuyucu), güvenli konum,
## geçişte kayıt kilidi, kaydet-yükle tutarlılığı.

var failures: Array[String] = []
var finished := false
var gm: Node
var sv: Node
var inv: Node
var qm: Node
var hd: Node
var level: Node
var pl: CharacterBody3D
var tl: Node


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
	hd = root.get_node("HorrorDirector")
	await process_frame
	await _run()
	print("")
	if not finished:
		failures.append("test sonuna ulaşılamadı (çalışma hatası)")
	if failures.is_empty():
		print("TÜM ZAMAN DURUMU TESTLERİ GEÇTİ")
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
	sv.delete_save()


func _load() -> void:
	if level != null and is_instance_valid(level):
		level.queue_free()
		await _frames(2)
	level = load("res://scenes/world/factory.tscn").instantiate()
	root.add_child(level)
	pl = level.player
	tl = level.time_layers
	tl.instant = true
	level.find_children("*", "Chapter2", false, false)[0].chase_enabled = false
	await _frames(40)


func _place(p: Vector3) -> void:
	pl.global_position = p
	pl.velocity = Vector3.ZERO


func _start_switch(state: String) -> void:
	await tl.switch_to(state)


func _rubble() -> Node:
	return level.get_node("Rubble2026")


func _reader() -> Node:
	for c in level.get_children():
		if c.has_method("get_prompt") and "required_item" in c and c.required_item == "yusuf_card":
			return c
	return null


func _run() -> void:
	_fresh()
	await _load()

	print("Durum yönetimi")
	_check(gm.time_state == "2026", "varsayılan zaman durumu 2026")
	_check(not gm.set_time_state("1999") and gm.time_state == "2026", "geçersiz durum reddedilir")
	var changed := []
	gm.time_state_changed.connect(func(s): changed.append(s))
	_check(gm.set_time_state("2004") and changed == ["2004"], "geçerli durum değişir ve sinyal verir")
	gm.set_time_state("2004")
	_check(changed.size() == 1, "aynı duruma geçiş sinyal tekrarlamaz")
	gm.set_time_state("2026")

	print("Ortak geometri, ayrı katmanlar")
	var walls_before := 0
	for c in level.get_children():
		if c is StaticBody3D and not ("door_id" in c) and c.collision_layer == 1 and not c.has_meta("time_state"):
			walls_before += 1
	tl.apply("2004")
	var walls_after := 0
	for c in level.get_children():
		if c is StaticBody3D and not ("door_id" in c) and c.collision_layer == 1 and not c.has_meta("time_state"):
			walls_after += 1
	_check(walls_before == walls_after and walls_before > 50, "duvar/zemin/tavan geometrisi iki durumda aynı (%d gövde)" % walls_before)
	_check(not _rubble().visible and _rubble().collision_layer == 0, "2004: 2026'ya özel moloz yok (görünmez, çarpışmasız)")
	var npcs := get_nodes_in_group("time_2004")
	var npc_ok := npcs.size() >= 3
	for n in npcs:
		if not n.visible:
			npc_ok = false
	_check(npc_ok, "2004: işçi siluetleri görünür (%d)" % npcs.size())
	tl.apply("2026")
	_check(_rubble().visible and _rubble().collision_layer == 1, "2026: moloz görünür ve çarpışır")
	var npc_hidden := true
	for n in get_nodes_in_group("time_2004"):
		if n.visible:
			npc_hidden = false
	_check(npc_hidden, "2026: işçi siluetleri yok")

	print("Işık ve ortam")
	var light: Light3D = get_nodes_in_group("room_light")[0]
	var c26: Color = light.light_color
	var e26: float = light.light_energy
	var env: Environment = level.environment
	var fog26: float = env.fog_density
	tl.apply("2004")
	_check(light.light_color.r > light.light_color.b + 0.2 and light.light_energy > e26, "2004: sıcak ve daha parlak ışık")
	_check(is_equal_approx(float(light.get_meta("base_energy")), light.light_energy), "titreme olayları için taban enerji güncellenir")
	_check(env.fog_density < fog26, "2004: sis seyrek")
	tl.apply("2026")
	_check(light.light_color.is_equal_approx(c26) and is_equal_approx(light.light_energy, e26) and is_equal_approx(env.fog_density, fog26), "2026'ya dönünce ışık ve ortam birebir geri gelir")

	print("Kapı, eşya ve NPC katmanları")
	var d: Node = load("res://scripts/interact/door.gd").new()
	d.only_in_state = "2004"
	d.door_id = "t_door"
	d.position = Vector3(30, 0, 30)
	level.add_child(d)
	await _frames(2)
	_check(d.get_prompt() == "Kilitli", "2026'da 2004'e özel kapı kilitli")
	d.interact(pl)
	_check(not d.is_open, "2026'da açılmaz")
	tl.apply("2004")
	gm.set_time_state("2004")
	_check(d.get_prompt() != "Kilitli", "2004'te kapı kullanılabilir")
	d.interact(pl)
	_check(d.is_open, "2004'te açılır")
	gm.set_time_state("2026")
	tl.apply("2026")
	var pk: Node = load("res://scripts/interact/pickup.gd").new()
	pk.item_id = "usb_drive"
	pk.pickup_id = "t_usb"
	pk.position = Vector3(31, 1, 31)
	level.add_child(pk)
	tl.register(pk, "2004")
	tl.apply("2026")
	_check(not pk.visible and pk.collision_layer == 0, "2026'da 2004'e özel eşya görünmez")
	pk.interact(pl)
	_check(not inv.has_item("usb_drive"), "2026'da 2004 eşyası alınamaz")
	gm.set_time_state("2004")
	tl.apply("2004")
	_check(pk.visible and pk.collision_layer == 4, "2004'te eşya görünür ve etkileşilebilir")
	pk.interact(pl)
	_check(inv.has_item("usb_drive"), "2004'te eşya alınır")
	gm.set_time_state("2026")
	tl.apply("2026")
	inv._items.erase("usb_drive")

	print("Güvenli geçiş: oyuncu duvar içine düşmez")
	var ok_all := true
	var moved_far := 0.0
	var rb: Vector3 = _rubble().global_position
	for i in 12:
		gm.set_time_state("2004")
		tl.apply("2004")
		await _frames(3)
		# oyuncuyu molozun tam içine (2004'te boş) koy
		var inside := rb + Vector3(randf_range(-0.8, 0.8), -0.5, randf_range(-0.7, 0.7))
		_place(Vector3(inside.x, 0.0, inside.z))
		await _frames(3)
		await tl.switch_to("2026")
		await _frames(3)
		if tl.is_blocked(pl.global_position):
			ok_all = false
		moved_far = maxf(moved_far, pl.global_position.distance_to(Vector3(inside.x, 0.0, inside.z)))
		if pl.global_position.y < -0.3:
			ok_all = false
		gm.set_time_state("2004")  # sonraki tur için sıfırla
		tl.apply("2004")
		gm.time_state = "2004"
		await _frames(2)
	_check(ok_all, "12 denemede 2004→2026 geçişinde oyuncu hiç moloz içinde kalmadı, zeminin altına düşmedi")
	_check(moved_far < 4.5, "güvenli konum yakındadır (en uzak taşıma %.1f m)" % moved_far)
	gm.set_time_state("2026")
	tl.apply("2026")
	_place(Vector3(0, 0.0, 0.0))
	await _frames(3)
	_check(not tl.is_blocked(pl.global_position), "engelsiz konumdaki oyuncu yerinde kalır (taşınmaz)")

	print("Kart okuyucu")
	var rd := _reader()
	_check(rd != null, "B Hattı'nda kart okuyucu var")
	_check(rd.get_prompt().contains("enerjisiz"), "Bölüm 5 bitmeden okuyucu enerjisiz")
	rd.interact(pl)
	_check(gm.time_state == "2026", "enerjisizken zaman değişmez")
	gm.set_flag("ch5_done")
	rd.interact(pl)
	_check(gm.time_state == "2026", "kart yokken zaman değişmez")
	inv.add_item("yusuf_card")
	await _frames(240)   # önceki geçişlerin bekleme süresi dolsun (oyun saati)
	_check(rd.get_prompt().contains("2004"), "ipucu: hedef zaman gösterilir")
	rd.interact(pl)
	await _frames(5)
	_check(gm.time_state == "2004" and not tl.transitioning, "Yusuf'un kartıyla 2026 → 2004 geçişi")
	_check(pl.controls_enabled and not gm.save_blocked, "geçiş sonrası kontroller açık, kayıt kilidi kalktı")
	rd.interact(pl)
	await _frames(3)
	_check(gm.time_state == "2004", "bekleme süresinde art arda geçiş engellenir (okuyucu meşgul)")
	await _frames(240)   # bekleme süresi (3 sn) dolar
	rd.interact(pl)
	await _frames(5)
	_check(gm.time_state == "2026", "bekleme sonrası geri dönüş mümkün (2004 → 2026)")

	print("Geçiş sürerken kayıt kilidi")
	tl.instant = false
	tl.fade_time = 0.2
	await _frames(240)
	var blocked_save := [true]
	_start_switch("2004")
	await _frames(2)
	_check(tl.transitioning and gm.save_blocked, "geçiş sürerken kayıt kilitli")
	blocked_save[0] = sv.save_game()
	_check(not blocked_save[0], "geçiş sırasında kayıt alınmaz (yarım durum yazılmaz)")
	_check(not pl.controls_enabled, "geçiş sürerken oyuncu kontrolü kapalı")
	var guard := 0
	while tl.transitioning and guard < 600:
		await physics_frame
		guard += 1
	await _frames(5)
	_check(not tl.transitioning and sv.save_game(), "geçiş bitince kayıt alınır")
	tl.instant = true

	print("Kaydet-yükle tutarlılığı")
	_check(gm.time_state == "2004", "(hazırlık) 2004'teyiz")
	gm.flags["marker"] = true
	_check(sv.save_game(), "2004'te kaydedildi")
	gm.time_state = "2026"
	gm.flags.clear()
	_check(sv.load_game() and gm.time_state == "2004", "yükleme zaman durumunu geri getirir")
	_check(gm.has_flag("marker"), "bayraklar da tutarlı")
	await _load()
	_check(gm.time_state == "2004" and not _rubble().visible and _rubble().collision_layer == 0, "yeni sahne 2004 katmanlarıyla açılır (moloz yok)")
	var warm: Light3D = get_nodes_in_group("room_light")[0]
	_check(warm.light_color.r > warm.light_color.b + 0.2, "yeni sahnede ışık 2004 (sıcak)")
	var vis := true
	for n in get_nodes_in_group("time_2004"):
		if not n.visible:
			vis = false
	_check(vis, "yeni sahnede işçi siluetleri görünür")
	# 2026 kaydı
	gm.time_state = "2026"
	sv.save_game()
	gm.time_state = "2004"
	sv.load_game()
	_check(gm.time_state == "2026", "2026 kaydı da doğru yüklenir")
	await _load()
	_check(_rubble().visible and _rubble().collision_layer == 1, "2026 kaydından açılan sahnede moloz var")
	# kayıttaki konum 2004'te boş, 2026'da dolu bir yerdeyse güvenli açılış
	gm.set_checkpoint(rb + Vector3(0, -0.5, 0), 0.0)
	gm.checkpoint_pos[1] = 0.0
	gm.time_state = "2026"
	sv.save_game()
	await _load()
	await _frames(10)
	_check(not tl.is_blocked(pl.global_position), "kontrol noktası moloz içindeyse yüklemede güvenli konuma alınır")

	level.queue_free()
	sv.delete_save()
	finished = true
