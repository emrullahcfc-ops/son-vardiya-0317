extends SceneTree
## Aşama 7 testleri: godot --headless --path . --script tests/run_chapter1_tests.gd
## Bölüm 1'i baştan sona oynar: kilitler, görevler, ölçüm, kod, fotoğraf olayı, Bölüm 2 geçişi, kayıt.

var failures: Array[String] = []
var finished := false
var gm: Node
var sv: Node
var inv: Node
var qm: Node


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
		print("TÜM BÖLÜM 1 TESTLERİ GEÇTİ")
		quit(0)
	else:
		print("BAŞARISIZ: ", failures)
		quit(1)


func _reset() -> void:
	gm.flags.clear()
	gm.visited_areas.clear()
	gm.current_chapter = 1
	qm.clear()
	inv._items.clear()
	root.get_node("HorrorDirector")._fired.clear()
	sv.delete_save()


func _prop(level: Node, type_name: String, prompt_prefix := "") -> Node:
	for c in level.get_children():
		if type_name == "Pickup" and "item_id" in c and c.item_id == prompt_prefix:
			return c
		if type_name == "Keypad" and c.has_method("try_code"):
			return c
		if type_name == "Spot" and "prompt_fn" in c and c.get_prompt().begins_with(prompt_prefix):
			return c
	return null


func _door(level: Node, id: String) -> Node:
	for d in level.doors:
		if d.door_id == id:
			return d
	return null


func _run() -> void:
	_reset()
	var level: Node = load("res://scenes/world/factory.tscn").instantiate()
	root.add_child(level)
	await physics_frame
	await physics_frame
	var pl: Node = level.player
	var ch: Node = level.find_children("*", "Chapter1", false, false)[0]
	ch.ring_time = 0.0
	var hd: Node = root.get_node("HorrorDirector")
	hd.cooldown = 0.0

	print("Başlangıç")
	_check(qm.is_active("ch1_enter_factory"), "görev: fabrikaya gir aktif")
	_check(gm.has_flag("ch1_intro"), "giriş telefon görüşmesi başlatıldı")
	var d_guard: Node = _door(level, "d02")
	var d_staff: Node = _door(level, "d04")
	_check(d_guard != null and d_staff != null, "kulübe ve personel kapısı var")
	_check(d_guard.get_prompt() == "Kilitli" and d_staff.get_prompt() == "Kilitli", "iki kapı da başta kilitli")
	d_guard.interact(pl)
	d_staff.interact(pl)
	_check(not d_guard.is_open and not d_staff.is_open, "kilitli kapılar açılmaz")

	print("Giriş")
	level.teleport_to_room("g_entry")
	await physics_frame
	await physics_frame
	_check(qm.is_completed("ch1_enter_factory") and qm.is_active("ch1_booth_key"), "girince görev ilerler: anahtarı bul")
	var kp: Node = _prop(level, "Keypad")
	_check(not kp.try_code("0317") and not gm.has_flag("ch1_staff_unlocked"), "enerji yokken kod çalışmaz")
	ch.photo_board()
	_check(not gm.has_flag("ch1_photo12"), "fotoğraf olayı enerji yokken tetiklenmez")

	print("Güvenlik")
	var key: Node = _prop(level, "Pickup", "key_security_booth")
	key.interact(pl)
	_check(inv.has_item("key_security_booth"), "kulübe anahtarı alındı")
	_check(qm.is_completed("ch1_booth_key") and qm.is_active("ch1_power_staff_door") and qm.is_active("ch1_find_door_code"), "görevler: enerji ve kod aktif")
	d_guard.interact(pl)
	_check(d_guard.is_open, "anahtarla kulübe kapısı açılır")
	var panel: Node = _prop(level, "Spot", "Sigorta")
	panel.interact(pl)
	_check(not gm.has_flag("ch1_measured") and not gm.has_flag("ch1_power_on"), "ölçü aleti yokken pano ölçmez")
	_prop(level, "Pickup", "multimeter").interact(pl)
	panel.interact(pl)
	_check(gm.has_flag("ch1_measured") and not gm.has_flag("ch1_power_on"), "ilk etkileşim: voltaj ölçümü (0 V), enerji hâlâ kapalı")
	panel.interact(pl)
	_check(gm.has_flag("ch1_power_on") and qm.is_completed("ch1_power_staff_door"), "ikinci etkileşim: şalter açılır, görev biter")
	panel.interact(pl)
	_check(gm.has_flag("ch1_power_on"), "pano tekrar kullanılabilir, bozulmaz")

	print("Kod ve fotoğraf")
	_check(not kp.try_code("1234") and not gm.has_flag("ch1_staff_unlocked"), "yanlış kod reddedilir")
	_check(not kp.try_code("0000"), "tekrar deneme serbest (kilitlenme yok)")
	d_staff.interact(pl)
	_check(not d_staff.is_open, "kod girilmeden personel kapısı açılmaz")
	ch.photo_board()
	_check(gm.has_flag("ch1_photo12") and ch._twelfth.visible, "enerji açıkken pano: 12. siluet belirir")
	_check(kp.try_code("0317") and gm.has_flag("ch1_staff_unlocked") and qm.is_completed("ch1_find_door_code"), "doğru kod: kilit açılır, görev biter")
	d_staff.interact(pl)
	_check(d_staff.is_open, "personel kapısı açılır")

	print("Bölüm 2 geçişi")
	_check(gm.current_chapter == 1, "geçişten önce Bölüm 1")
	level.teleport_to_room("g_lineB")
	await physics_frame
	await physics_frame
	_check(gm.current_chapter == 2 and gm.has_flag("ch1_done"), "üretim hattına girince Bölüm 2 başlar")
	_check(FileAccess.file_exists("user://savegame.json"), "geçişte kontrol noktası kaydı yazıldı")
	level.teleport_to_room("g_entry")
	await physics_frame
	level.teleport_to_room("g_lineB")
	await physics_frame
	_check(gm.current_chapter == 2, "geçiş tekrar tetiklenmez")
	level.queue_free()
	await process_frame

	print("Kayıt")
	gm.flags.clear()
	gm.current_chapter = 1
	qm.clear()
	inv._items.clear()
	_check(sv.load_game(), "kayıt yüklenir")
	_check(gm.current_chapter == 2, "Bölüm 2 geçişi kayıtla korunur")
	_check(gm.has_flag("ch1_staff_unlocked") and gm.has_flag("ch1_photo12"), "bölüm bayrakları korunur")
	_check(inv.has_item("key_security_booth") and inv.has_item("multimeter"), "eşyalar korunur")
	_check(qm.is_completed("ch1_find_door_code") and qm.is_completed("ch1_power_staff_door"), "görevler korunur")
	var again: Node = load("res://scenes/world/factory.tscn").instantiate()
	root.add_child(again)
	await physics_frame
	_check(_prop(again, "Pickup", "key_security_booth") == null and _prop(again, "Pickup", "multimeter") == null, "alınan eşyalar yüklemeden sonra tekrar çıkmaz")
	_check(_door(again, "d04").get_prompt() != "Kilitli", "kod çözülmüş kapı yüklemeden sonra kilitli kalmaz (%s)" % _door(again, "d04").get_prompt())
	_check(_door(again, "d02").get_prompt() != "Kilitli", "kulübe kapısı yüklemeden sonra kilitli kalmaz")
	_check(again.find_children("*", "Chapter1", false, false).size() == 1, "Bölüm 1 betiği yüklemede tek kopya")
	again.queue_free()
	sv.delete_save()
	finished = true
