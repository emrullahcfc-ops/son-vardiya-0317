extends Node
## Gerçek oyun içi ekran görüntüsü alır: godot --path . res://tools/capture.tscn
# [dosya, oda, durus_dx, durus_dz, bakis_dx, bakis_dz]  (oda merkezine göre)
const SHOTS := [
	["01_dis_alan", "g_out", 0.0, 3.0, 0.0, -4.0],
	["02_giris_holu", "g_entry", 4.0, 2.5, -6.0, 0.0],
	["03_b_hatti", "g_lineB", 4.0, 4.0, 0.0, -6.0],
	["04_yemekhane", "u_cant", -4.0, 2.5, 6.0, 0.0],
	["05_boru_odasi", "b_pipe", 3.5, 2.5, -5.0, 0.0],
	["06_muhurlu_alan", "b_sealed", 3.5, 4.5, 5.0, 0.0],
	["07_siluet_olayi", "b_tunnel", 0.0, 4.5, 0.0, -6.0, "ev_silhouette"],
]
func _ready() -> void:
	var level: Node = load("res://scenes/world/factory.tscn").instantiate()
	add_child(level)
	for _i in 5: await get_tree().physics_frame
	for s in SHOTS:
		level.teleport_to_room(s[1])
		level.player.global_position += Vector3(s[2], 0, s[3])
		level.player.rotation = Vector3(0, atan2(-(s[4] - s[2]), -(s[5] - s[3])), 0)
		if s.size() > 6:
			HorrorDirector.force_fire(s[6])
		for _i in 20: await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png("res://docs/img/%s.png" % s[0])
	get_tree().quit()
