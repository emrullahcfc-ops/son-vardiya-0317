extends Node
## Gerçek oyun içi ekran görüntüsü alır: godot --path . res://tools/capture.tscn
# [dosya, oda, durus_x, durus_z, bakis_x, bakis_z, (olay)]  — dünya koordinatları (metre)
const SHOTS := [
	["b1_01_arac_yagmur", "g_out", -2.0, 22.5, 4.0, 20.5],
	["b1_02_giris_masa_pano", "g_entry", 0.0, 9.3, 1.0, 15.0],
	["b1_03_tus_takimi", "g_entry", 1.4, 11.5, 1.4, 8.28],
	["b1_04_guvenlik", "g_guard", -10.0, 9.5, -10.5, 14.8],
	["b1_05_pano_12_siluet", "g_entry", -3.5, 11.5, -3.5, 15.7, "ch1_photo"],
	["b1_06_sigorta_panosu", "g_guard", -10.0, 12.0, -13.7, 12.0],
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
		elif s.size() > 6:
			HorrorDirector.force_fire(s[6])
		for _i in 20: await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png("res://docs/img/%s.png" % s[0])
	get_tree().quit()
