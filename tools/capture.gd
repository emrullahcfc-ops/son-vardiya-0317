extends Node
## Gerçek oyun içi ekran görüntüsü alır: godot --path . res://tools/capture.tscn
# [dosya, oda, durus_x, durus_z, bakis_x, bakis_z, (olay)]  — dünya koordinatları (metre)
const SHOTS := [
	["c6_01_beton_2026", "g_load", 9.0, 12.0, 13.4, 12.0, "ch6_state"],
	["c6_02_depo_2004_terminal", "g_load", 9.0, 12.0, 14.9, 12.0, "ch6_2004"],
	["c6_03_koridor_iscileri", "g_load", 9.0, 12.0, 14.9, 12.0, "ch6_corridor"],
]
func _ready() -> void:
	var level: Node = load("res://scenes/world/factory.tscn").instantiate()
	add_child(level)
	for _i in 5: await get_tree().physics_frame
	for s in SHOTS:
		level.teleport_to_room(s[1])
		var y: float = level.player.global_position.y
		level.player.global_position = Vector3(s[2], y, s[3])
		level.player.rotation = Vector3(0, atan2(-(s[4] - s[2]), -(s[5] - s[3])), 0)
		if s.size() > 6 and s[6] == "ch1_photo":
			GameManager.set_flag("ch1_power_on")
			level.find_children("*", "Chapter1", false, false)[0].photo_board()
		elif s.size() > 6 and (s[6] == "ch6_state" or s[6] == "ch6_2004" or s[6] == "ch6_corridor"):
			GameManager.set_chapter(6)
			for f in ["ch4_done", "ch5_done"]:
				GameManager.set_flag(f)
			var c8: Node = level.find_children("*", "Chapter6", false, false)[0]
			c8.chase_wait = false
			level.time_layers.instant = true
			if s[6] == "ch6_2004":
				level.time_layers.switch_to("2004")
			elif s[6] == "ch6_corridor":
				InventoryManager.add_item("breaker_handle")
				c8.use_breaker_panel()
		elif s.size() > 6 and s[6] == "time_2004":
			level.time_layers.instant = true
			level.time_layers.switch_to("2004")
		elif s.size() > 6 and (s[6] == "ch2_mimic" or s[6] == "ch2_mimic_near"):
			GameManager.set_chapter(2)
			var c3: Node = level.find_children("*", "Chapter2", false, false)[0]
			c3.chase_enabled = false
			if c3.mimic == null:
				c3.start_chase()
			if s[6] == "ch2_mimic_near":
				c3.mimic.global_position = Vector3(2.0, 0.05, -9.0)
		elif s.size() > 6 and s[6] == "ch2_shutter":
			var c4: Node = level.find_children("*", "Chapter2", false, false)[0]
			c4.shutter.set_state_instant(true)
		elif s.size() > 6 and (s[6] == "sayici" or s[6] == "sayici_near"):
			GameManager.set_chapter(5)
			GameManager.set_flag("ch4_done")
			GameManager.debug_ai = true
			var sc: Node = level.find_children("*", "SayiciController", false, false)[0]
			if sc.sayici == null:
				sc.spawn()
			var sy: Node = sc.sayici
			sy.route.clear()
			sy.global_position = Vector3(0, 0.05, -1.5) if s[6] == "sayici" else Vector3(0, 0.05, 0.5)
			sy.rotation.y = PI
			sy.suspicion = 0.5
		elif s.size() > 6 and s[6] == "hide":
			for h in get_tree().get_nodes_in_group("hide_spots"):
				if h.global_position.distance_to(Vector3(-13.3, 0, 15.3)) < 0.5:
					h.interact(level.player)
		elif s.size() > 6 and (s[6] == "ch5_start" or s[6] == "ch5_gas" or s[6] == "ch5_steam"):
			GameManager.set_chapter(5)
			GameManager.set_flag("ch4_done")
			GameManager.set_flag("ch5_started")
			var c7: Node = level.find_children("*", "Chapter5", false, false)[0]
			c7._wait = false
			InventoryManager.add_item("gas_meter")
			c7._set_filters(2)
			if s[6] == "ch5_gas":
				c7._set_filter_left(18.0)
				c7.exposure = 0.0
			if s[6] == "ch5_steam":
				c7._steam(true)
		elif s.size() > 6 and s[6] == "ch4_ui":
			GameManager.set_flag("ch3_done")
			GameManager.set_chapter(4)
			var c6: Node = level.find_children("*", "Chapter4", false, false)[0]
			c6._wait = false
			if c6.ui == null:
				c6.open_monitor()
			c6.ui.select_camera(s[7])
			c6.ui.play(s[8])
		elif s.size() > 6 and s[6] == "ch3_soup":
			var c5: Node = level.find_children("*", "Chapter3", false, false)[0]
			c5.soup()
		elif s.size() > 6 and s[6] == "ch2_run":
			GameManager.set_chapter(2)
			var c2: Node = level.find_children("*", "Chapter2", false, false)[0]
			c2._wait = false
			for l in ["B", "C", "A"]:
				c2.press_line(l)
		elif s.size() > 6:
			HorrorDirector.force_fire(s[6])
		for _i in 20: await get_tree().process_frame
		if s.size() > 6 and s[6] == "ch4_ui":
			for _j in 25: await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png("res://docs/img/%s.png" % s[0])
	get_tree().quit()
