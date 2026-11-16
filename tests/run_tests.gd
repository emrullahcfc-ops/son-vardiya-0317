extends SceneTree
## Başsız (headless) test: godot --headless --path . --script tests/run_tests.gd
## Autoload'lar --script modunda otomatik yüklenmez; kök sahneye elle ekliyoruz.

var failures: Array[String] = []
var finished := false


func _check(cond: bool, name: String) -> void:
	if cond:
		print("  PASS  ", name)
	else:
		print("  FAIL  ", name)
		failures.append(name)


func _initialize() -> void:
	# Autoload düğümlerini elle kur
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
	await process_frame
	_run()
	if not finished:
		failures.append("test sonuna ulaşılamadı (çalışma hatası)")
	print("")
	if failures.is_empty():
		print("TÜM TESTLER GEÇTİ")
		quit(0)
	else:
		print("BAŞARISIZ: ", failures)
		quit(1)


func _run() -> void:
	print("Envanter / görev / kayıt")
	var inv := root.get_node("InventoryManager")
	var quest := root.get_node("QuestManager")
	var gm := root.get_node("GameManager")
	var save := root.get_node("SaveManager")
	var hd := root.get_node("HorrorDirector")

	inv.clear()
	quest.clear()
	save.delete_save()

	_check(inv.add_item("floor_key"), "eşya eklenir")
	_check(not inv.add_item("floor_key"), "aynı eşya iki kez eklenmez")
	_check(not inv.add_item("yok_boyle_esya"), "bilinmeyen eşya reddedilir")
	_check(not inv.remove_item("floor_key"), "kritik eşya bırakılamaz")

	_check(quest.start_quest("ch1_enter_factory"), "görev başlar")
	_check(quest.complete_quest("ch1_enter_factory"), "görev tamamlanır")
	_check(not quest.complete_quest("ch1_enter_factory"), "görev iki kez tamamlanamaz")
	_check(not quest.start_quest("ch1_enter_factory"), "biten görev yeniden başlamaz")

	quest.start_quest("ch1_find_door_code")
	gm.set_flag("read_security_note")
	gm.current_chapter = 2
	_check(save.save_game(), "kayıt yazılır")
	inv.clear()
	quest.clear()
	gm.flags = {}
	gm.current_chapter = 1
	_check(save.load_game(), "kayıt yüklenir")
	_check(inv.has_item("floor_key"), "yükleme sonrası eşya korunur")
	_check(quest.is_completed("ch1_enter_factory"), "yükleme sonrası biten görev korunur")
	_check(quest.is_active("ch1_find_door_code"), "yükleme sonrası aktif görev korunur")
	_check(gm.has_flag("read_security_note") and gm.current_chapter == 2, "bayrak ve bölüm korunur")

	# Bozuk kayıt -> yedeğe düş (yedek, ikinci kayıtla oluşur)
	_check(save.save_game(), "ikinci kayıt (yedek oluşturur)")
	var f := FileAccess.open("user://savegame.json", FileAccess.WRITE)
	f.store_string("{bozuk json")
	f.close()
	_check(save.load_game(), "bozuk kayıtta yedekten yüklenir")
	save.delete_save()
	_check(not save.load_game(), "kayıt yoksa false döner, çökmez")

	print("Korku yönetmeni")
	hd._last_time = -9999.0  # yükleme gecikmesini sıfırla
	_check(hd.fire("test_flash", 1), "olay bir kez tetiklenir")
	_check(not hd.fire("test_flash", 1), "aynı olay tekrarlanmaz")
	_check(not hd.fire("baska_olay", 1), "bekleme süresinde ikinci olay engellenir")
	_check(not hd.can_fire("ileri_bolum", 5), "bölüm koşulu sağlanmazsa tetiklenmez")

	print("Sahne yükleme")
	var lvl: PackedScene = load("res://scenes/world/test_level.tscn")
	_check(lvl != null, "test sahnesi yüklenir")
	var inst := lvl.instantiate()
	root.add_child(inst)
	_check(inst.get_child_count() > 5, "sahne düğümleri oluştu")
	inst.queue_free()
	finished = true
