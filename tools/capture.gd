extends Node
## Gerçek oyun içi ekran görüntüsü alır: godot --path . res://tools/capture.tscn
# [dosya, oda, durus_x, durus_z, bakis_x, bakis_z, (olay)]  — dünya koordinatları (metre)
const SHOTS := [
	["b3_01_soyunma_dolaplari", "u_dress", -11.0, 10.5, -11.0, 15.2],
	["b3_02_yemekhane_corba", "u_cant", 0.0, 9.5, 0.0, 12.5, "ch3_soup"],
	["b3_03_revir_dolap", "u_infirm", 9.0, 11.0, 15.5, 12.5],
	["b3_04_arsiv_dosyalar", "u_arch", -9.0, 3.0, -13.0, 0.0],
	["b3_05_buro_yusuf_karti", "u_office", 0.0, 6.5, 0.6, 3.0],
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
		get_viewport().get_texture().get_image().save_png("res://docs/img/%s.png" % s[0])
	get_tree().quit()
