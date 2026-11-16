extends Node3D
## Aşama 1-4 test sahnesi: zemin, duvarlar, rampa, kapı, anahtar, belge.
## Gerçek fabrika bölümleri bu iskeletin üzerine inşa edilir.

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const HUD_SCRIPT := preload("res://scripts/ui/hud.gd")

var player: CharacterBody3D


func _ready() -> void:
	_build_environment()
	_build_room()
	_spawn_props()
	player = PLAYER_SCENE.instantiate()
	add_child(player)
	player.global_position = Vector3(0, 0.1, 3)
	var hud := CanvasLayer.new()
	hud.set_script(HUD_SCRIPT)
	add_child(hud)
	hud.bind_player(player)
	QuestManager.start_quest("ch1_enter_factory")
	QuestManager.start_quest("ch1_find_door_code")


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F5:
			SaveManager.save_game()
			AudioManager.say("Kaydedildi.", 1.5)
		elif event.keycode == KEY_F9:
			if SaveManager.load_game():
				get_tree().reload_current_scene()


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.01, 0.012, 0.02)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.25, 0.28, 0.35)
	env.ambient_light_energy = 0.6
	env.fog_enabled = true
	env.fog_light_color = Color(0.05, 0.06, 0.08)
	env.fog_density = 0.04
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0, 2.6, 0)
	lamp.omni_range = 9.0
	lamp.light_energy = 1.2
	lamp.shadow_enabled = true
	add_child(lamp)


func _box(pos: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.position = pos
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	body.add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mi.material_override = mat
	body.add_child(mi)
	add_child(body)


func _build_room() -> void:
	var wall := Color(0.32, 0.33, 0.3)
	_box(Vector3(0, -0.1, 0), Vector3(14, 0.2, 14), Color(0.18, 0.18, 0.17))     # zemin
	_box(Vector3(0, 3.05, 0), Vector3(14, 0.2, 14), Color(0.2, 0.2, 0.2))         # tavan
	_box(Vector3(0, 1.5, -7), Vector3(14, 3, 0.2), wall)
	_box(Vector3(0, 1.5, 7), Vector3(14, 3, 0.2), wall)
	_box(Vector3(-7, 1.5, 0), Vector3(0.2, 3, 14), wall)
	_box(Vector3(7, 1.5, 0), Vector3(0.2, 3, 14), wall)
	# iç duvar + kapı boşluğu (x: -0.5..0.5)
	_box(Vector3(-3.75, 1.5, -2), Vector3(6.5, 3, 0.2), wall)
	_box(Vector3(3.75, 1.5, -2), Vector3(6.5, 3, 0.2), wall)
	_box(Vector3(0, 2.55, -2), Vector3(1.0, 0.9, 0.2), wall)
	# alçak engel (çömelme testi) ve basamak
	_box(Vector3(4, 0.9, 3), Vector3(2.5, 0.2, 2.5), Color(0.25, 0.2, 0.15))
	_box(Vector3(4, 0.05, 3), Vector3(2.5, 0.1, 2.5), Color(0.25, 0.2, 0.15))
	_box(Vector3(-4, 0.15, 3), Vector3(2, 0.3, 1.5), Color(0.3, 0.3, 0.3))


func _spawn_props() -> void:
	var key := Pickup.new()
	key.item_id = "floor_key"
	key.pickup_id = "test_floor_key"
	key.position = Vector3(-4, 0.8, 3)
	add_child(key)

	var door := Door.new()
	door.door_id = "test_staff_door"
	door.required_item = "floor_key"
	door.size = Vector3(1.0, 2.1, 0.1)
	door.position = Vector3(-0.5, 0, -2)
	add_child(door)

	var doc := Document.new()
	doc.title = "Güvenlik notu"
	doc.body = "Personel kapısı için kat anahtarı kulübede. Kod: 317."
	doc.flag_on_read = "read_security_note"
	doc.position = Vector3(2.5, 1.0, 5.8)
	add_child(doc)
