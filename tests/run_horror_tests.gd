extends SceneTree
## Aşama 6 testleri: godot --headless --path . --script tests/run_horror_tests.gd
## Ses sentezi, ortam katmanları, korku olayı motoru, flaş azaltma, olayların sahnede çalışması.

var failures: Array[String] = []
var gm: Node
var au: Node
var hd: Node
var sv: Node
var finished := false


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
	au = root.get_node("AudioManager")
	hd = root.get_node("HorrorDirector")
	sv = root.get_node("SaveManager")
	await process_frame
	await _run()
	print("")
	if not finished:
		failures.append("test sonuna ulaşılamadı (çalışma hatası)")
	if failures.is_empty():
		print("TÜM KORKU/SES TESTLERİ GEÇTİ")
		quit(0)
	else:
		print("BAŞARISIZ: ", failures)
		quit(1)


func _run() -> void:
	print("Ses")
	for s in ["door_slam", "chime", "buzz", "thump", "whisper", "hum", "wind"]:
		var w: AudioStreamWAV = au.get_sound(s)
		_check(w != null and w.data.size() > 1000, "ses sentezlendi: %s (%d bayt)" % [s, w.data.size() if w else 0])
	_check(au.get_sound("yok_boyle_ses") == null, "bilinmeyen ses null döner")
	_check(au.get_sound("hum").loop_mode == AudioStreamWAV.LOOP_FORWARD, "ortam sesi döngülü")
	_check(AudioServer.get_bus_index("SFX") != -1 and AudioServer.get_bus_index("Ambient") != -1, "SFX ve Ambient kanalları var")
	au.start_layer("hum", -30.0)
	_check(au.has_layer("hum"), "ortam katmanı başladı")
	au.start_layer("hum", -30.0)
	_check(au._layers.size() == 1, "aynı katman iki kez başlamaz")
	au.stop_layer("hum")
	_check(not au.has_layer("hum"), "ortam katmanı durdu")
	_check(au.play_sfx("chime") != null, "2D efekt çalındı")
	_check(au.play_sfx("thump", Vector3(1, 1, 1)) != null, "3D efekt çalındı")
	gm.settings["sfx_volume"] = 0.0
	au._apply_volume()
	_check(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")) < -60.0, "SFX ses ayarı kanala uygulanır")
	gm.settings["sfx_volume"] = 1.0
	au._apply_volume()

	print("Flaş azaltma")
	var red: Array = _fx_script().flicker_pattern(true)
	var norm: Array = _fx_script().flicker_pattern(false)
	var slow := true
	var prev := 1.0
	var max_jump := 0.0
	for st in red:
		if float(st[1]) < 0.3:
			slow = false
		max_jump = maxf(max_jump, absf(float(st[0]) - prev))
		prev = float(st[0])
	_check(slow, "azaltılmış titreme: her adım >= 0.3 sn")
	_check(max_jump <= 0.5, "azaltılmış titreme: ani değişim <= %%50 (%.2f)" % max_jump)
	var fast := 0
	for st in norm:
		if float(st[1]) < 0.2:
			fast += 1
	_check(fast >= 3, "normal titreme hızlı adımlar içerir (%d)" % fast)

	print("Korku olayı motoru")
	hd.cooldown = 0.0
	hd._fired.clear()
	_check(hd.can_fire("ev_flicker", 1), "başta olay tetiklenebilir")
	_check(not hd.can_fire("ev_flicker", 5), "bölüm koşulu: 5. bölüm olayı 1. bölümde çalışmaz")
	var got: Array = []
	hd.event_fired.connect(func(id): got.append(id))
	gm.enter_area("g_lineB", "B Hattı")
	_check(got == ["ev_flicker"], "alana girince bağlı olay tetiklenir %s" % str(got))
	_check(hd.intensity > 0.15, "olay yoğunluğu artırır (%.2f)" % hd.intensity)
	gm.enter_area("g_lineA", "A Hattı")
	gm.enter_area("g_lineB", "B Hattı")
	_check(got.count("ev_flicker") == 1, "tek seferlik: aynı olay tekrar etmez")
	hd.cooldown = 20.0
	hd._last_time = hd._clock
	gm.enter_area("g_maint", "Bakım")
	_check(not got.has("ev_door_slam"), "bekleme süresinde olay tetiklenmez")
	hd.cooldown = 0.0
	gm.visited_areas.clear()
	gm.enter_area("g_maint", "Bakım")
	_check(got.has("ev_door_slam"), "bekleme bitince tetiklenir")
	var before: int = hd._fired.size()
	hd.force_fire("ev_announce")
	_check(hd._fired.size() == before and got.has("ev_announce"), "test modunda zorla çalıştırma kaydı bozmaz")
	var saved: Dictionary = hd.to_save_data()
	hd._fired.clear()
	hd.from_save_data(saved)
	_check(hd.has_fired("ev_flicker") and hd.has_fired("ev_door_slam"), "kayıttan sonra olaylar korunur")
	hd.intensity = 0.9
	hd._process(10.0)
	_check(hd.intensity < 0.9 and hd.intensity >= 0.05, "yoğunluk zamanla düşer ama tabanın altına inmez (%.2f)" % hd.intensity)

	print("Sahnede olaylar")
	hd._fired.clear()
	var level: Node = load("res://scenes/world/factory.tscn").instantiate()
	root.add_child(level)
	await physics_frame
	await physics_frame
	var fx := level.find_children("*", "HorrorEffects", false, false)
	_check(fx.size() == 1, "HorrorEffects sahnede")
	_check(au.has_layer("hum") and au.has_layer("wind"), "ortam katmanları sahnede başladı")
	var lights := get_nodes_in_group("room_light")
	_check(lights.size() >= 19, "oda ışıkları grupta (%d)" % lights.size())
	var subs: Array = []
	au.subtitle.connect(func(t, _d): subs.append(t))
	hd.force_fire("ev_announce")
	_check(subs.size() == 1 and String(subs[0]).begins_with("[Anons]"), "anons altyazısı gösterilir")
	gm.settings["subtitles"] = false
	subs.clear()
	hd.force_fire("ev_announce")
	_check(subs.is_empty(), "altyazı kapalıyken gösterilmez")
	gm.settings["subtitles"] = true
	subs.clear()
	hd.force_fire("ev_door_slam")
	_check(subs.size() == 1, "kapı çarpma altyazısı")
	var cap_before: int = _count_capsules(level)
	level.teleport_to_room("b_tunnel")
	await physics_frame
	hd.force_fire("ev_silhouette")
	_check(_count_capsules(level) == cap_before + 1, "siluet oluştu")
	var target_light: Light3D = null
	for l in lights:
		if l.get_meta("room_id") == "g_lineB":
			target_light = l
	var base: float = target_light.get_meta("base_energy")
	hd.force_fire("ev_flicker")
	await create_timer(0.7).timeout
	_check(absf(target_light.light_energy - base) > 0.05, "ışık titremesi enerjiyi değiştirir")
	await create_timer(2.5).timeout
	_check(absf(target_light.light_energy - base) < 0.01, "titreme sonunda ışık eski haline döner")
	_check(_count_capsules(level) == cap_before, "siluet kendini siler")
	level.queue_free()
	sv.delete_save()
	finished = true


func _fx_script() -> GDScript:
	return load("res://scripts/horror/horror_effects.gd")


func _count_capsules(level: Node) -> int:
	var n := 0
	for c in level.get_children():
		if c is MeshInstance3D and c.mesh is CapsuleMesh:
			n += 1
	return n
