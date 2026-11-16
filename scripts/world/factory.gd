extends Node3D
## Aşama 5: Fabrika bloklaması. FactoryLayout verisinden 3 katlı kaba haritayı üretir:
## duvarlar, zemin/tavan, kapılar, merdiven rampaları, oda ışıkları, alan tetikleri.
## Test modunda F2/F3 ile alanlar arasında ışınlanma vardır.

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const HUD_SCRIPT := preload("res://scripts/ui/hud.gd")

@export var test_mode: bool = true

var player: CharacterBody3D
var doors: Array = []
var _mats: Dictionary = {}
var _tp_index := -1
var _ev_index := -1


func _ready() -> void:
	_build_environment()
	for r in FactoryLayout.ROOMS:
		_build_room(r)
	for rp in FactoryLayout.RAMPS:
		_build_ramp(rp)
	_build_doors()
	_spawn_player()
	var fx := HorrorEffects.new()
	fx.factory = self
	add_child(fx)
	var ch1 := Chapter1.new()
	ch1.factory = self
	add_child(ch1)
	var ch4 := Chapter4.new()
	ch4.factory = self
	add_child(ch4)
	var ch3 := Chapter3.new()
	ch3.factory = self
	add_child(ch3)
	var ch2 := Chapter2.new()
	ch2.factory = self
	add_child(ch2)
	_build_navigation()
	AudioManager.start_layer("hum", -30.0)
	AudioManager.start_layer("wind", -34.0)
	QuestManager.start_quest("ch1_enter_factory")


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	match event.keycode:
		KEY_F5:
			if player:
				GameManager.set_checkpoint(player.global_position, player.rotation.y)
			SaveManager.save_game()
			AudioManager.say("Kaydedildi.", 1.5)
		KEY_F9:
			if SaveManager.load_game():
				get_tree().reload_current_scene()
		KEY_F2:
			if test_mode:
				teleport_step(1)
		KEY_F3:
			if test_mode:
				teleport_step(-1)
		KEY_F4:
			if test_mode:  # korku olaylarını sırayla oynat (cooldown yok sayılır)
				var ids: Array = HorrorDirector.EVENTS.keys()
				_ev_index = (_ev_index + 1) % ids.size()
				HorrorDirector.force_fire(ids[_ev_index])


## Kontrol noktasına dön (ölümden sonra): kaydı yükle, oyuncuyu kayıtlı konuma koy.
func respawn_player() -> void:
	SaveManager.load_game()
	if GameManager.checkpoint_pos.size() == 4 and player:
		var cp: Array = GameManager.checkpoint_pos
		player.global_position = Vector3(cp[0], cp[1], cp[2])
		player.rotation.y = float(cp[3])
		player.velocity = Vector3.ZERO
		player.controls_enabled = true


# ---------------------------------------------------------------- yol ağı (NavigationMesh)
var nav_region: NavigationRegion3D


func _build_navigation() -> void:
	_tag_nav_geometry(self)
	nav_region = NavigationRegion3D.new()
	var nm := NavigationMesh.new()
	nm.cell_size = 0.125
	nm.cell_height = 0.125
	nm.agent_radius = 0.375
	nm.agent_height = 1.75
	nm.agent_max_climb = 0.25
	nm.agent_max_slope = 40.0
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nm.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_EXPLICIT
	nm.geometry_source_group_name = &"nav_geo"
	nm.geometry_collision_mask = 1
	NavigationServer3D.map_set_cell_size(get_world_3d().navigation_map, 0.125)
	NavigationServer3D.map_set_cell_height(get_world_3d().navigation_map, 0.125)
	nav_region.navigation_mesh = nm
	add_child(nav_region)
	nav_region.bake_navigation_mesh(false)
	_push_nav()
	nav_region.bake_finished.connect(_push_nav)


## Bake sonucunu sunucuya iletir (kaynağı yeniden atamak güncellemeyi tetikler).
func _push_nav() -> void:
	var m := nav_region.navigation_mesh
	nav_region.navigation_mesh = null
	nav_region.navigation_mesh = m


## Kapılar yola dahil edilmez (düşman kapıyı açar); diğer sabit gövdeler yol ağını keser.
func _tag_nav_geometry(n: Node) -> void:
	for c in n.get_children():
		if c is StaticBody3D and not (c is Door) and not c.is_in_group("player"):
			c.add_to_group("nav_geo")
		_tag_nav_geometry(c)


func rebake_navigation() -> void:
	if nav_region:
		_tag_nav_geometry(self)
		# Eşzamanlı: iş parçacıklı bake sonucu güvenilir uygulanmıyor. ~0,3 sn; kepenk darbesiyle örtüşür.
		nav_region.bake_navigation_mesh(false)
		_push_nav()


func teleport_step(dir: int) -> void:
	var list := FactoryLayout.counted_rooms()
	_tp_index = posmod(_tp_index + dir, list.size())
	teleport_to_room(list[_tp_index]["id"])


func teleport_to_room(room_id: String) -> void:
	var r := FactoryLayout.room(room_id)
	if r.is_empty() or player == null:
		return
	var c := FactoryLayout.room_center(r)
	player.global_position = c + Vector3(0, 0.15, 0)
	player.velocity = Vector3.ZERO


# ---------------------------------------------------------------- ortam
func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.01, 0.012, 0.02)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.3, 0.33, 0.4)
	env.ambient_light_energy = 0.8
	env.fog_enabled = true
	env.fog_light_color = Color(0.06, 0.07, 0.09)
	env.fog_density = 0.015
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	player.add_to_group("player")
	add_child(player)
	var start := FactoryLayout.room(FactoryLayout.START_ROOM)
	player.global_position = FactoryLayout.room_center(start) + Vector3(0, 0.15, 2.0)
	if GameManager.checkpoint_pos.size() == 4:
		var cp: Array = GameManager.checkpoint_pos
		player.global_position = Vector3(cp[0], cp[1], cp[2])
		player.rotation.y = float(cp[3])
	var hud := CanvasLayer.new()
	hud.set_script(HUD_SCRIPT)
	add_child(hud)
	hud.bind_player(player)


# ---------------------------------------------------------------- geometri
func _mat(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = 0.9
		_mats[key] = m
	return _mats[key]


func _solid(mn: Vector3, mx: Vector3, color: Color) -> void:
	var size := mx - mn
	if size.x <= 0.001 or size.y <= 0.001 or size.z <= 0.001:
		return
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.position = (mn + mx) * 0.5
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	body.add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(color)
	body.add_child(mi)
	var occ := OccluderInstance3D.new()
	var bo := BoxOccluder3D.new()
	bo.size = size
	occ.occluder = bo
	body.add_child(occ)
	add_child(body)


func _floor_color(f: String) -> Color:
	match f:
		"B": return Color(0.2, 0.22, 0.22)
		"U": return Color(0.3, 0.29, 0.27)
		_: return Color(0.27, 0.27, 0.25)


func _build_room(room: Dictionary) -> void:
	var f: String = room["f"]
	var y0 := FactoryLayout.floor_y(f)
	var b: Array = room["r"]
	var col := _floor_color(f)
	for s in room.get("slabs", [b]):
		_solid(Vector3(s[0], y0 - 0.3, s[1]), Vector3(s[2], y0, s[3]), col.darkened(0.3))
	for c in room.get("ceils", [b]):
		_solid(Vector3(c[0], y0 + 3.7, c[1]), Vector3(c[2], y0 + 4.0, c[3]), col.darkened(0.4))
	var skip: Array = room.get("no_walls", [])
	for side in ["w", "e", "s", "n"]:
		if not skip.has(side):
			_build_wall(room, side, col)
	_add_light(room)
	_add_area(room)


func _gaps_for(f: String, axis: String, c: float, lo: float, hi: float) -> Array:
	var gaps: Array = []
	for d in FactoryLayout.DOORS:
		if d["f"] == f and d["axis"] == axis and is_equal_approx(float(d["c"]), c):
			var p := float(d["p"])
			if p > lo and p < hi:
				var hw := float(d.get("w", FactoryLayout.DOOR_W)) * 0.5 + 0.05
				gaps.append([p - hw, p + hw])
	gaps.sort_custom(func(a, b): return a[0] < b[0])
	return gaps


func _build_wall(room: Dictionary, side: String, col: Color) -> void:
	var f: String = room["f"]
	var y0 := FactoryLayout.floor_y(f)
	var b: Array = room["r"]
	var t := FactoryLayout.WALL_T
	var wc := col.lightened(0.05)
	# Duvarın uzandığı eksen: x-duvarları (w/e) z boyunca, z-duvarları (s/n) x boyunca uzanır.
	var along_z := side == "w" or side == "e"
	var lo: float = b[1] if along_z else b[0]
	var hi: float = b[3] if along_z else b[2]
	var plane: float
	var n0: float
	var n1: float
	match side:
		"w": plane = b[0]; n0 = b[0]; n1 = b[0] + t
		"e": plane = b[2]; n0 = b[2] - t; n1 = b[2]
		"s": plane = b[1]; n0 = b[1]; n1 = b[1] + t
		_: plane = b[3]; n0 = b[3] - t; n1 = b[3]
	var gaps := _gaps_for(f, "x" if along_z else "z", plane, lo, hi)
	var cursor := lo
	for g in gaps:
		_wall_piece(along_z, n0, n1, cursor, g[0], y0, y0 + 4.0, wc)
		_wall_piece(along_z, n0, n1, g[0], g[1], y0 + FactoryLayout.DOOR_H + 0.1, y0 + 4.0, wc)  # lento
		cursor = g[1]
	_wall_piece(along_z, n0, n1, cursor, hi, y0, y0 + 4.0, wc)


func _wall_piece(along_z: bool, n0: float, n1: float, a: float, b: float, ya: float, yb: float, col: Color) -> void:
	if b - a <= 0.001:
		return
	if along_z:
		_solid(Vector3(n0, ya, a), Vector3(n1, yb, b), col)
	else:
		_solid(Vector3(a, ya, n0), Vector3(b, yb, n1), col)


func _build_ramp(rp: Dictionary) -> void:
	var width: float = rp["x1"] - rp["x0"]
	var dz: float = rp["z1"] - rp["z0"]
	var dy: float = rp["y1"] - rp["y0"]
	var length := sqrt(dz * dz + dy * dy)
	var ang := atan2(dy, dz)
	var mid := Vector3((rp["x0"] + rp["x1"]) * 0.5, (rp["y0"] + rp["y1"]) * 0.5, (rp["z0"] + rp["z1"]) * 0.5)
	var normal := Vector3(0, cos(ang), -sin(ang))
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.position = mid - normal * 0.15
	body.rotation.x = -ang
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(width, 0.3, length)
	cs.shape = bs
	body.add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = bs.size
	mi.mesh = bm
	mi.material_override = _mat(Color(0.22, 0.2, 0.18))
	body.add_child(mi)
	add_child(body)


func _build_doors() -> void:
	var i := 0
	for d in FactoryLayout.DOORS:
		i += 1
		if d.get("open", false):
			continue
		var w: float = d.get("w", FactoryLayout.DOOR_W)
		var door := Door.new()
		door.door_id = "d%02d" % i
		door.size = Vector3(w, FactoryLayout.DOOR_H, 0.1)
		door.required_item = d.get("req_item", "")
		door.required_flag = d.get("req_flag", "")
		door.locked_hint = d.get("hint", "Kilitli.")
		var y0 := FactoryLayout.floor_y(d["f"])
		var c: float = d["c"]
		var p: float = d["p"]
		if d["axis"] == "z":
			door.position = Vector3(p - w * 0.5, y0, c)
		else:
			door.position = Vector3(c, y0, p + w * 0.5)
			door.rotation.y = PI * 0.5
		add_child(door)
		doors.append(door)


func _add_light(room: Dictionary) -> void:
	var b: Array = room["r"]
	var c := FactoryLayout.room_center(room)
	var l := OmniLight3D.new()
	l.position = c + Vector3(0, 2.9, 0)
	l.omni_range = maxf(b[2] - b[0], b[3] - b[1]) * 0.85
	l.light_energy = 2.2
	l.light_color = Color(0.85, 0.9, 1.0) if room["f"] != "B" else Color(0.7, 0.85, 0.75)
	l.add_to_group("room_light")
	l.set_meta("room_id", room["id"])
	l.set_meta("base_energy", l.light_energy)
	add_child(l)


func _add_area(room: Dictionary) -> void:
	var b: Array = room["r"]
	var c := FactoryLayout.room_center(room)
	var a := Area3D.new()
	a.collision_layer = 0
	a.collision_mask = 2
	a.position = c + Vector3(0, 1.8, 0)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(b[2] - b[0] - 0.6, 3.4, b[3] - b[1] - 0.6)
	cs.shape = bs
	a.add_child(cs)
	var rid: String = room["id"]
	var rname: String = room["name"]
	var counted: bool = room.get("count", true)
	a.body_entered.connect(func(body: Node3D):
		if body.is_in_group("player"):
			GameManager.enter_area(rid, rname, counted))
	add_child(a)
