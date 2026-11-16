extends SceneTree
## Aşama 5 testleri: godot --headless --path . --script tests/run_factory_tests.gd
## 1) veri tutarlılığı  2) kapı geçiş testi (kapsül)  3) rampada yürüme (fizik)  4) alan ziyareti

var failures: Array[String] = []


func _check(cond: bool, name: String) -> void:
	print("  ", "PASS" if cond else "FAIL", "  ", name)
	if not cond:
		failures.append(name)


var gm: Node
var sv: Node


func _initialize() -> void:
	# Autoload'lar --script modunda derleme zamanında görünmez; düğümleri elle bağla.
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
	await process_frame
	await _run()
	print("")
	if failures.is_empty():
		print("TÜM FABRİKA TESTLERİ GEÇTİ")
		quit(0)
	else:
		print("BAŞARISIZ: ", failures)
		quit(1)


func _run() -> void:
	print("Veri")
	var counted := FactoryLayout.count_areas()
	_check(counted == 19, "19 ana alan tanımlı (bulunan: %d)" % counted)
	var ids := {}
	for r in FactoryLayout.ROOMS:
		ids[r["id"]] = true
	_check(ids.size() == FactoryLayout.ROOMS.size(), "oda kimlikleri benzersiz")
	var by_floor := {"B": 0, "G": 0, "U": 0}
	for r in FactoryLayout.counted_rooms():
		by_floor[r["f"]] += 1
	_check(by_floor["G"] == 7 and by_floor["U"] == 6 and by_floor["B"] == 6, "kat dağılımı 7/6/6 (zemin/üst/bodrum): %s" % str(by_floor))
	var reach := FactoryLayout.reachable()
	var missing: Array[String] = []
	for r in FactoryLayout.counted_rooms():
		if not reach.has(r["id"]):
			missing.append(r["id"])
	_check(missing.is_empty(), "19 alanın hepsine kapı grafiğiyle erişilir %s" % str(missing))
	for rp in FactoryLayout.RAMPS:
		var s := absf(FactoryLayout.ramp_slope_deg(rp))
		_check(s < 35.0, "rampa %s eğimi yürünebilir (%.1f°)" % [rp["id"], s])
	var bad_refs := 0
	for d in FactoryLayout.DOORS:
		if not ids.has(d["a"]) or not ids.has(d["b"]):
			bad_refs += 1
	_check(bad_refs == 0, "tüm kapılar geçerli odalara bağlı")

	print("Sahne")
	var scene: PackedScene = load("res://scenes/world/factory.tscn")
	var level := scene.instantiate()
	root.add_child(level)
	await physics_frame
	await physics_frame
	_check(level.player != null, "oyuncu oluşturuldu")
	var door_count := FactoryLayout.DOORS.filter(func(d): return not d.get("open", false)).size()
	_check(level.doors.size() == door_count, "kapı düğümleri oluştu (%d)" % level.doors.size())

	print("Kapı geçişi (kapsül %.1f m yarıçap)" % 0.3)
	for d in level.doors:
		d._set_open_instant(true)
	await physics_frame
	var space: PhysicsDirectSpaceState3D = level.get_world_3d().direct_space_state
	var blocked: Array[String] = []
	for d in FactoryLayout.DOORS:
		# rampa tabanındaki geçiş rampa testinde denenir
		if String(d["a"]) == "b_stairD" or String(d["b"]) == "b_stairD":
			continue
		var y0 := FactoryLayout.floor_y(d["f"]) + 0.1
		var c: float = d["c"]
		var p: float = d["p"]
		var from: Vector3
		var to: Vector3
		if d["axis"] == "z":
			from = Vector3(p, y0, c - 1.2)
			to = Vector3(p, y0, c + 1.2)
		else:
			from = Vector3(c - 1.2, y0, p)
			to = Vector3(c + 1.2, y0, p)
		var cap := CapsuleShape3D.new()
		cap.radius = 0.3
		cap.height = 1.7
		var q := PhysicsShapeQueryParameters3D.new()
		q.shape = cap
		q.transform = Transform3D(Basis(), from + Vector3(0, 0.85, 0))
		q.motion = to - from
		q.collision_mask = 1
		var res: Array = space.cast_motion(q)
		if res.is_empty() or res[0] < 0.999:
			blocked.append("%s↔%s" % [d["a"], d["b"]])
	_check(blocked.is_empty(), "tüm kapı açıklıklarından kapsül geçer %s" % str(blocked))

	print("Rampa yürüyüşü")
	var pl: CharacterBody3D = level.player
	# Yukarı: zemin → üst kat
	await _walk(pl, Vector3(-18, 0.15, -2.5), PI, 700)
	_check(pl.global_position.y > 3.8 and pl.global_position.z > 7.5, "yukarı merdiven: üst kata çıkılır (y=%.2f z=%.2f)" % [pl.global_position.y, pl.global_position.z])
	# Aşağı: zemin → bodrum
	await _walk(pl, Vector3(18, 0.15, 9), 0.0, 900)
	_check(pl.global_position.y < -3.7 and pl.global_position.z < -4.0, "bodrum merdiveni: bodruma inilir (y=%.2f z=%.2f)" % [pl.global_position.y, pl.global_position.z])
	# Geri çık
	await _walk(pl, Vector3(18, -3.85, -8), PI, 900)
	_check(pl.global_position.y > -0.3 and pl.global_position.z > 3.5, "bodrumdan zemine geri çıkılır (y=%.2f z=%.2f)" % [pl.global_position.y, pl.global_position.z])

	print("Alan ziyareti ve kayıt")
	gm.visited_areas.clear()
	for r in FactoryLayout.counted_rooms():
		level.teleport_to_room(r["id"])
		for _i in 6:
			await physics_frame
	_check(gm.visited_areas.size() == 19, "test modunda 19 alana girildi (%d)" % gm.visited_areas.size())
	_check(sv.save_game(), "ziyaretler kaydedilir")
	gm.visited_areas.clear()
	_check(sv.load_game() and gm.visited_areas.size() == 19, "kayıt sonrası ziyaretler korunur")
	sv.delete_save()

	Input.action_release("move_forward")
	level.queue_free()


func _walk(pl: CharacterBody3D, start: Vector3, yaw: float, frames: int) -> void:
	pl.global_position = start
	pl.velocity = Vector3.ZERO
	pl.rotation = Vector3(0, yaw, 0)
	await physics_frame
	Input.action_press("move_forward")
	for _i in frames:
		await physics_frame
	Input.action_release("move_forward")
	for _i in 10:
		await physics_frame
