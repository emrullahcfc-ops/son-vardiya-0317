extends Node
## Gerçek oyun içi ekran görüntüsü alır: godot --path . res://tools/capture.tscn
# [dosya, oda, durus_x, durus_z, bakis_x, bakis_z, (olay)]  — dünya koordinatları (metre)
const SHOTS := [
	["b2_01_hat_b_makine", "g_lineB", -3.0, 0.0, 2.5, 4.0],
	["b2_02_cizelge", "g_lineB", -3.0, 0.5, -3.0, -3.7],
	["b2_03_hat_a_dilekce", "g_lineA", -9.0, 1.5, -13.2, -2.2],
	["b2_04_makineler_calisiyor", "g_lineB", -3.0, 0.0, 2.5, 4.0, "ch2_run"],
	["b2_05_bakim_dolap", "g_maint", 0.0, -7.0, -5.3, -8.0],
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
