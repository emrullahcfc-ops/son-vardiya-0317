extends SceneTree
## Aşama 8 testleri: godot --headless --path . --script tests/run_chapter2_tests.gd
## Üretim hattı bulmacaları: faz sırası, yanlış girişte sıfırlama/tekrar, belgeden kod çıkarma, final, kat anahtarı, kayıt.

var failures: Array[String] = []
var finished := false
var gm: Node
var sv: Node
var inv: Node
var qm: Node
var au: Node
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
	au.subtitle.connect(func(t, _d): subs.append(t))
	await process_frame
	await _run()
	print("")
	if not finished:
		failures.append("test sonuna ulaşılamadı (çalışma hatası)")
	if failures.is_empty():
		print("TÜM BÖLÜM 2 TESTLERİ GEÇTİ")
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


func _spot(level: Node, prefix: String) -> Node:
	for c in level.get_children():
		if "prompt_fn" in c and c.get_prompt().begins_with(prefix):
			return c
	return null


func _doc(level: Node, title: String) -> Node:
	for c in level.get_children():
		if "title" in c and "body" in c and c.title == title:
			return c
	return null


func _door(level: Node, id: String) -> Node:
	for d in level.doors:
		if d.door_id == id:
			return d
	return null


func _cabinet(level: Node) -> Node:
	for c in level.get_children():
		if c.has_method("try_code") and c.code == "317":
			return c
	return null


func _pickup(level: Node, item: String) -> Node:
	for c in level.get_children():
		if "item_id" in c and c.item_id == item:
			return c
	return null


func _run() -> void:
	_reset()
	var level: Node = load("res://scenes/world/factory.tscn").instantiate()
	root.add_child(level)
	await physics_frame
	await physics_frame
	var pl: Node = level.player
	var ch: Node = level.find_children("*", "Chapter2", false, false)[0]
	ch._wait = false
	gm.set_flag("ch1_done")
	gm.set_chapter(2)

	print("Başlangıç")
	_check(qm.is_active("ch2_start_lines") and qm.is_active("ch2_cabinet_code"), "Bölüm 2 görevleri başladı")
	var d_maint: Node = _door(level, "d09")
	var d_stair: Node = _door(level, "d10")
	_check(d_maint.get_prompt() == "Kilitli", "bakım kapısı başta kilitli")
	_check(d_stair.get_prompt() == "Kilitli", "merdiven kapısı kat anahtarı ister")
	d_maint.interact(pl)
	_check(not d_maint.is_open, "kilitli bakım kapısı açılmaz")

	print("Faz sırası")
	var btn := {}
	for l in ["A", "B", "C"]:
		btn[l] = _spot(level, "Başlat: Hat %d" % (["A", "B", "C"].find(l) + 1))
		_check(btn[l] != null, "%s hattı başlat düğmesi var" % l)
	btn["A"].interact(pl)
	_check(ch.lines_started().is_empty(), "yanlış sıra (A önce): sıfırlanır")
	_check(subs.back().begins_with("Faz uyumsuz"), "hata mesajı: çizelgeye yönlendirir")
	btn["B"].interact(pl)
	btn["A"].interact(pl)
	_check(ch.lines_started().is_empty(), "B sonra A: yanlış sıra sıfırlanır")
	btn["B"].interact(pl)
	_check(ch.lines_started() == ["B"], "B doğru başlar")
	btn["B"].interact(pl)
	_check(ch.lines_started() == ["B"], "çalışan hat tekrar basılınca bozulmaz")
	btn["C"].interact(pl)
	_check(ch.lines_started() == ["B", "C"], "C doğru başlar")
	_check(not gm.has_flag("ch2_machines_on"), "iki hat: final henüz yok")
	btn["A"].interact(pl)
	_check(gm.has_flag("ch2_machines_on") and qm.is_completed("ch2_start_lines"), "B-C-A: üç hat çalışır, görev biter")
	_check(au.has_layer("machine"), "final: makine sesi çalıyor")
	_check(d_maint.get_prompt() != "Kilitli", "final: bakım kapısı kilidi düştü")
	d_maint.interact(pl)
	_check(d_maint.is_open, "bakım kapısı açılır")

	print("Belgeyle kod çıkarma (tahmin yok)")
	var sched: Node = _spot(level, "Oku: Vardiya çizelgesi")
	subs.clear()
	sched.interact(pl)
	_check(subs.size() == 1 and "2. hat, 3. hat, 1. hat" in String(subs[0]), "çizelge faz sırasını verir")
	var pet: Node = _doc(level, "Dilekçe")
	var form: Node = _doc(level, "Bakım iptal formu")
	_check(pet != null and form != null, "dilekçe ve bakım iptal formu var")
	var rx := RegEx.new()
	rx.compile("([A-C]), ([A-C]), ([A-C]) sırasıyla")
	var m := rx.search(pet.body)
	_check(m != null, "dilekçe duruş sırasını verir")
	var last: String = m.get_string(3)
	_check("hat sayısı" in form.body and "en son duran" in form.body, "form kuralı: hat sayısı + son duran hattın sayacı")
	subs.clear()
	var hat_no := ["A", "B", "C"].find(last) + 1
	_spot(level, "İncele: Hat %d" % hat_no).interact(pl)
	var rx2 := RegEx.new()
	rx2.compile("donmuş: (\\d+)")
	var m2 := rx2.search(String(subs[0]))
	var plates := 0
	for c in level.get_children():
		if "prompt_fn" in c and c.get_prompt().begins_with("İncele: Hat"):
			plates += 1
	var derived := "%d%s" % [plates, m2.get_string(1)]
	_check(derived == "317", "belgelerden çıkarılan kod 317 (%s)" % derived)

	print("Dolap ve kat anahtarı")
	var cab: Node = _cabinet(level)
	_check(not cab.try_code("123") and not gm.has_flag("ch2_cabinet_open"), "yanlış kod reddedilir")
	_check(not cab.try_code("000"), "tekrar deneme serbest")
	_check(_pickup(level, "floor_key") == null, "kod girilmeden anahtar görünmez")
	_check(cab.try_code(derived), "belgeden çıkan kod dolabı açar")
	_check(qm.is_completed("ch2_cabinet_code"), "dolap görevi biter")
	var key: Node = _pickup(level, "floor_key")
	_check(key != null, "dolap açılınca kat anahtarı belirir")
	key.interact(pl)
	_check(inv.has_item("floor_key") and gm.has_flag("ch2_done") and qm.is_completed("ch2_floor_key"), "anahtar alınınca bölüm biter")
	_check(FileAccess.file_exists("user://savegame.json"), "kontrol noktası kaydı yazıldı")
	_check(d_stair.get_prompt() != "Kilitli", "kat anahtarı merdiven kapısını açar")
	d_stair.interact(pl)
	_check(d_stair.is_open, "merdiven kapısı açılır")
	level.queue_free()
	await process_frame

	print("Kayıt")
	gm.flags.clear()
	qm.clear()
	inv._items.clear()
	_check(sv.load_game(), "kayıt yüklenir")
	_check(gm.has_flag("ch2_machines_on") and gm.has_flag("ch2_cabinet_open") and gm.has_flag("ch2_done"), "Bölüm 2 bayrakları korunur")
	_check(inv.has_item("floor_key"), "kat anahtarı korunur")
	var again: Node = load("res://scenes/world/factory.tscn").instantiate()
	root.add_child(again)
	await physics_frame
	_check(_pickup(again, "floor_key") == null, "alınan anahtar tekrar çıkmaz")
	_check(_door(again, "d09").get_prompt() != "Kilitli", "bakım kapısı yüklemeden sonra açık kalır")
	_check(au.has_layer("machine"), "makine sesi yüklemeden sonra sürer")
	again.queue_free()
	sv.delete_save()
	finished = true
