extends SceneTree
## Aşama 9 testleri: godot --headless --fixed-fps 60 --path . --script tests/run_enemy_tests.gd
## Yol ağı, görüş, Taklitçi (duvardan geçmez, ışınlanmaz), yakalanma/ölüm/kontrol noktası,
## kepenkle kaçış ve tekrarlanabilirlik. (--fixed-fps: simülasyon hızlı ve deterministik koşar.)

var failures: Array[String] = []
var finished := false
var gm: Node
var sv: Node
var qm: Node
var inv: Node
var level: Node
var ch: Node
var pl: CharacterBody3D


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
	qm = root.get_node("QuestManager")
	inv = root.get_node("InventoryManager")
	await process_frame
	await _run()
	print("")
	if not finished:
		failures.append("test sonuna ulaşılamadı (çalışma hatası)")
	if failures.is_empty():
		print("TÜM DÜŞMAN TESTLERİ GEÇTİ")
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
	gm.current_chapter = 2
	qm.clear()
	inv._items.clear()
	root.get_node("HorrorDirector")._fired.clear()
	sv.delete_save()
	# Anahtarı almış gibi: bölüm 2 bitti, kontrol noktası dolap başında
	gm.set_flag("ch1_done")
	gm.set_flag("ch2_machines_on")
	gm.set_flag("ch2_cabinet_open")
	gm.set_flag("ch2_done")
	gm.set_flag("pickup_ch2_floor_key")
	inv.add_item("floor_key")
	gm.set_checkpoint(Vector3(-5.3, 0.1, -8.0), 0.0)
	sv.save_game()


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _step_toward(from: Vector3, to: Vector3, step: float) -> Vector3:
	var d := Vector2(to.x - from.x, to.z - from.z)
	if d.length() <= step:
		return Vector3(to.x, from.y, to.z)
	var n := d.normalized() * step
	return Vector3(from.x + n.x, from.y, from.z + n.y)


func _place_player(p: Vector3) -> void:
	pl.global_position = p
	pl.velocity = Vector3.ZERO


func _overlaps_wall(m: Node3D) -> bool:
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.5
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = cap
	q.transform = Transform3D(Basis(), m.global_position + Vector3(0, 0.95, 0))
	q.collision_mask = 1
	return not level.get_world_3d().direct_space_state.intersect_shape(q, 1).is_empty()


func _run() -> void:
	_fresh_state()
	level = load("res://scenes/world/factory.tscn").instantiate()
	root.add_child(level)
	pl = level.player
	ch = level.find_children("*", "Chapter2", false, false)[0]
	ch.chase_enabled = false
	ch._wait = false
	await _frames(60)  # yol ağı sunucuya işlenir

	print("Yol ağı")
	var map: RID = level.get_world_3d().navigation_map
	var p1: PackedVector3Array = NavigationServer3D.map_get_path(map, Vector3(5, 0, -11), Vector3(-11, 0, 2), true)
	_check(p1.size() > 2 and p1[p1.size() - 1].distance_to(Vector3(-11, 0.2, 2)) < 1.0, "bakım odasından A Hattı'na yol var (%d nokta)" % p1.size())
	var through_door := false
	var through_gap := false
	for v in p1:
		if absf(v.x) < 0.7 and absf(v.z + 4.0) < 0.5:
			through_door = true
		if absf(v.x + 6.0) < 0.7 and absf(v.z - 2.0) < 0.8:
			through_gap = true
	_check(through_door, "yol bakım kapısı açıklığından geçer")
	_check(through_gap, "yol B↔A geçidinden geçer (kepenk yeri)")
	var up: PackedVector3Array = NavigationServer3D.map_get_path(map, Vector3(0, 0, 2), Vector3(-18, 4, 10), true)
	_check(up.size() > 2 and up[up.size() - 1].y > 3.5, "üst kata yol var (merdiven)")
	var down: PackedVector3Array = NavigationServer3D.map_get_path(map, Vector3(0, 0, 2), Vector3(11, -4, -8), true)
	_check(down.size() > 2 and down[down.size() - 1].y < -3.5, "bodruma yol var")

	print("Görüş")
	var m: Mimic = Mimic.new()
	level.add_child(m)
	m.player = pl
	m.global_position = Vector3(0, 0.05, 5)
	m.rotation.y = 0.0  # -z'ye bakar
	_place_player(Vector3(0, 0.1, -2))
	await _frames(3)
	_check(m.can_see_player(), "açık alanda, önünde: görür")
	_place_player(Vector3(0, 0.1, 7.0))
	await _frames(2)
	_check(not m.can_see_player(), "arkasındayken görüş konisi dışında: görmez")
	_place_player(Vector3(-10, 0.1, 12))
	await _frames(2)
	_check(not m.can_see_player(), "duvar arkasında: görmez")
	_place_player(Vector3(0, 0.1, -2))
	m.global_position = Vector3(0, 0.05, 5 - 30)
	await _frames(2)
	_check(not m.can_see_player(), "menzil dışında: görmez")
	m.queue_free()
	await _frames(2)

	print("Kovalamaca senaryosu: durağan oyuncu yakalanır (ölüm + kontrol noktası)")
	ch.dormant_timeout = 3.0
	_place_player(Vector3(-5.3, 0.1, -8.0))
	var died := [0]
	var cb := func(): died[0] += 1
	ch.player_died.connect(cb)
	ch.start_chase()
	_check(ch.chase_active and ch.mimic != null, "senaryo başladı, Taklitçi bakım odasında")
	_check(ch.mimic.state == Mimic.State.DORMANT, "Taklitçi başta uyuyor (oyuncuya hazırlık süresi var)")
	var mm: Mimic = ch.mimic
	var prev := mm.global_position
	var max_step := 0.0
	var wall_hits := 0
	var f := 0
	while died[0] == 0 and f < 1500:
		await physics_frame
		f += 1
		if is_instance_valid(mm):
			var step := mm.global_position.distance_to(prev)
			max_step = maxf(max_step, step)
			prev = mm.global_position
			if f % 3 == 0 and _overlaps_wall(mm):
				wall_hits += 1
	_check(died[0] == 1, "oyuncu durağansa Taklitçi yetişir ve yakalar (%.1f sn)" % (f / 60.0))
	_check(f / 60.0 > ch.dormant_timeout + 1.0, "uyanma süresi + yaklaşma süresi tanındı (%.1f sn > %.1f)" % [f / 60.0, ch.dormant_timeout + 1.0])
	_check(max_step < 0.12, "ışınlanma yok: kare başına en fazla %.3f m" % max_step)
	_check(wall_hits == 0, "duvardan geçmez (örtüşme: %d)" % wall_hits)
	await _frames(150)  # ölüm solması + yeniden doğma
	var cp := Vector3(-5.3, 0.1, -8.0)
	_check(pl.global_position.distance_to(cp) < 0.5, "ölümden sonra kontrol noktasına dönüldü")
	_check(pl.controls_enabled, "kontroller geri açıldı")
	_check(inv.has_item("floor_key") and gm.has_flag("ch2_done"), "kayıt durumu geri yüklendi (anahtar kaybolmadı)")
	await _frames(150)
	_check(ch.chase_active and ch.mimic != null, "kovalamaca kontrol noktasından yeniden başladı")

	print("Kepenkle kaçış (koşan oyuncu)")
	# Oyuncu en baştan: sprint ile B hattı kepenk koluna koşar
	_place_player(cp)
	var route: Array = [Vector3(-1.5, 0.1, -6.0), Vector3(0.0, 0.1, -3.2), Vector3(-5.0, 0.1, 1.8), Vector3(-7.0, 0.1, 3.0)]
	var succeeded := [false]
	var sb := func(): succeeded[0] = true
	ch.chase_succeeded.connect(sb)
	mm = ch.mimic
	var min_dist := 999.0
	var pulled := false
	var shutter_when_pulled := 0.0
	for wp in route:
		while _flat(pl.global_position, wp) > 0.05:
			pl.global_position = _step_toward(pl.global_position, wp, 5.5 / 60.0)
			await physics_frame
			if is_instance_valid(mm):
				min_dist = minf(min_dist, pl.global_position.distance_to(mm.global_position))
				if mm.state != Mimic.State.DORMANT and _overlaps_wall(mm):
					wall_hits += 1
	var gap_at_lever := pl.global_position.distance_to(mm.global_position)
	ch.pull_lever()
	pulled = ch.shutter.is_down
	await _frames(150)  # kepenk iner + yol ağı yeniden hesaplanır
	_check(pulled and ch.shutter.is_down, "kepenk kolu kepengi indirir")
	_check(gap_at_lever > 6.0, "koşan oyuncu kola ulaştığında Taklitçi ≥ 6 m geride (%.1f m)" % gap_at_lever)
	_check(died[0] == 1, "kaçış sırasında yakalanmadı")
	# Taklitçi kepenkten geçemez: yol yeniden hesaplanır, kepenk çarpışması aktif
	var through := NavigationServer3D.map_get_path(map, Vector3(0, 0, 2), Vector3(-11, 0, 2), true)
	var direct := false
	for v in through:
		if absf(v.x + 6.1) < 0.4 and absf(v.z - 2.0) < 0.6:
			direct = true
	_check(not direct, "kepenk inince yol ağı geçidi kapalı sayar (başka yoldan dolaşır)")
	for d in level.doors:
		if d.door_id == "d10":
			d.force_open()  # oyuncu kat anahtarıyla kapıyı açmış olur
	await _frames(45)
	for wp in [Vector3(-12.0, 0.1, 1.0), Vector3(-15.0, 0.1, -1.0), Vector3(-18.0, 0.1, -1.0)]:
		var guard := 0
		while _flat(pl.global_position, wp) > 0.05 and guard < 600:
			pl.global_position = _step_toward(pl.global_position, wp, 5.5 / 60.0)
			await physics_frame
			guard += 1
	await _frames(30)
	_check(succeeded[0] and gm.has_flag("ch2_chase_done"), "kepenk inikken merdiven alanına ulaşınca kaçış tamamlanır")
	_check(qm.is_completed("ch2_escape"), "kaçış görevi tamamlandı")
	_check(wall_hits == 0, "kaçış boyunca duvardan geçmedi")
	await _frames(200)
	_check(ch.mimic == null or not is_instance_valid(ch.mimic) or ch.mimic.state == Mimic.State.RETREAT, "Taklitçi geri çekildi")

	print("Arama davranışı (görüşü kaybedince)")
	level.queue_free()
	await _frames(3)
	_fresh_state()
	level = load("res://scenes/world/factory.tscn").instantiate()
	root.add_child(level)
	pl = level.player
	ch = level.find_children("*", "Chapter2", false, false)[0]
	ch.chase_enabled = false
	ch.dormant_timeout = 1.0
	await _frames(60)
	_place_player(Vector3(-5.3, 0.1, -8.0))
	ch.start_chase()
	var gave := [false]
	ch.mimic.gave_up.connect(func(): gave[0] = true)
	var seen_search := false
	await _frames(70)  # uyanır
	var last_pos := pl.global_position
	_place_player(Vector3(11, -3.9, -8))  # bodrum: görüş yok
	var f2 := 0
	while not gave[0] and f2 < 1800:
		await physics_frame
		f2 += 1
		if is_instance_valid(ch.mimic) and ch.mimic.state == Mimic.State.SEARCH:
			seen_search = true
	_check(seen_search, "görüş kaybolunca ARAMA durumuna geçer")
	_check(gave[0], "son bilinen konumda arayıp vazgeçer (%.1f sn)" % (f2 / 60.0))
	_check(ch.mimic.global_position.distance_to(last_pos) < 2.0, "son bilinen konuma gitti (%.1f m)" % ch.mimic.global_position.distance_to(last_pos))
	_check(not ch.chase_active and gm.has_flag("ch2_chase_done"), "vazgeçince kaçış tamamlanmış sayılır")
	level.queue_free()
	sv.delete_save()
	finished = true
