extends Node
## Gerçek oyun içi ekran görüntüsü alır: godot --path . res://tools/capture.tscn
# [dosya, oda, durus_x, durus_z, bakis_x, bakis_z, (olay)]  — dünya koordinatları (metre)
const SHOTS := [
	["b4_01_kamera_odasi", "u_cam", 8.5, 2.0, 15.0, 2.0],
	["b4_02_monitor_b_hatti_0314", "u_cam", 8.5, 2.0, 15.0, 2.0, "ch4_ui", "k3", "c_0314"],
	["b4_03_monitor_giris_0317", "u_cam", 8.5, 2.0, 15.0, 2.0, "ch4_ui", "k1", "c_0317"],
	["b4_04_monitor_pompa_0316", "u_cam", 8.5, 2.0, 15.0, 2.0, "ch4_ui", "k6", "c_0316"],
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
