class_name TimeLayers
extends Node
## İki zaman durumu (2026 = bugün, 2004 = olay gecesi). Mekân geometrisi (duvar/zemin/tavan/rampa) İKİSİNDE DE ORTAKTIR;
## farklı olan yalnızca katmanlardır: ışık/ortam, kapı kullanılabilirliği, eşyalar, NPC siluetleri ve duruma özel engeller.
## Geçiş kontrollüdür (kart okuyucu): ekran kararır, durum değişir, oyuncu duvar içindeyse güvenli konuma taşınır,
## geçiş sürerken kayıt kapalıdır (tutarlılık). Durum kayıtla saklanır (GameManager.time_state).

signal switched(state: String)

const STATES := ["2026", "2004"]
const PLAYER_RADIUS := 0.32
const PLAYER_HEIGHT := 1.7

var factory: Node3D
var transitioning := false
var instant := false           # testte: bekleme/solma yok
var fade_time := 0.6
var cooldown := 3.0
var _entries: Array = []       # {"node": Node, "state": String}
var _last_safe := Vector3.ZERO
var _safe_t := 0.0
var _cool_until := 0.0
var _clock := 0.0           # simülasyon saati (bekleme süresi gerçek zamana değil oyun zamanına bağlı)
var _overlay: ColorRect

# 2004 ışık/ortam ayarı (sıcak, aydınlık, tozsuz); 2026 mevcut soğuk ve loş hâl
const ENV_2004 := {"ambient": Color(0.5, 0.42, 0.3), "ambient_energy": 1.0, "fog": Color(0.2, 0.15, 0.08), "fog_density": 0.008, "light": Color(1.0, 0.86, 0.55), "light_mult": 1.3}
var _env_2026: Dictionary = {}


func _ready() -> void:
	add_to_group("time_layers")
	var e := factory.get("environment") as Environment
	if e:
		_env_2026 = {"ambient": e.ambient_light_color, "ambient_energy": e.ambient_light_energy, "fog": e.fog_light_color, "fog_density": e.fog_density}
	_build_demo_props()


# ------------------------------------------------------------------ katman kaydı
## Bir düğümü yalnızca verilen zaman durumunda var say (görünür + çarpışma + etkileşim).
func register(node: Node, state: String) -> void:
	_entries.append({"node": node, "state": state})
	node.add_to_group("time_" + state)
	node.set_meta("time_state", state)
	if node is Interactable:
		(node as Interactable).time_state_required = state


func spawn_npc(npc_name: String, pos: Vector3, state: String, yaw := 0.0) -> Node3D:
	var m := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.26
	cap.height = 1.7
	m.mesh = cap
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.78, 0.6) if state == "2004" else Color(0.5, 0.52, 0.5)
	m.material_override = mat
	m.name = "TimeNpc_" + npc_name
	m.position = pos + Vector3(0, 0.85, 0)
	m.rotation.y = yaw
	factory.add_child(m)
	register(m, state)
	return m


func apply(state: String) -> void:
	_entries = _entries.filter(func(e): return is_instance_valid(e["node"]))  # silinmiş düğümleri ele
	for e in _entries:
		_set_active(e["node"], e["state"] == state)
	_apply_lights(state)
	_apply_environment(state)


func _set_active(node: Node, on: bool) -> void:
	if not is_instance_valid(node):
		return
	if node is Node3D:
		(node as Node3D).visible = on
	if node is CollisionObject3D:
		var co := node as CollisionObject3D
		if on:
			co.collision_layer = int(co.get_meta("tl_layer", co.collision_layer))
		else:
			if co.collision_layer != 0:
				co.set_meta("tl_layer", co.collision_layer)
			co.collision_layer = 0


func _apply_lights(state: String) -> void:
	for l in get_tree().get_nodes_in_group("room_light"):
		if not l.has_meta("tl_color"):
			l.set_meta("tl_color", l.light_color)
			l.set_meta("tl_energy", float(l.get_meta("base_energy", l.light_energy)))
		var c: Color = l.get_meta("tl_color")
		var e: float = l.get_meta("tl_energy")
		if state == "2004":
			c = ENV_2004["light"]
			e *= float(ENV_2004["light_mult"])
		l.light_color = c
		l.light_energy = e
		l.set_meta("base_energy", e)  # titreme olayları yeni taban değeri kullanır


func _apply_environment(state: String) -> void:
	var env := factory.get("environment") as Environment
	if env == null:
		return
	var s: Dictionary = ENV_2004 if state == "2004" else _env_2026
	if s.is_empty():
		return
	env.ambient_light_color = s["ambient"]
	env.ambient_light_energy = s["ambient_energy"]
	env.fog_light_color = s["fog"]
	env.fog_density = s["fog_density"]


# ------------------------------------------------------------------ geçiş
func can_switch() -> bool:
	return not transitioning and _clock >= _cool_until


## Kontrollü zaman geçişi. Oyuncu kontrolü kapanır, kayıt engellenir, durum değişir, oyuncu güvene alınır.
func switch_to(state: String) -> bool:
	if not STATES.has(state) or transitioning or state == GameManager.time_state:
		return false
	transitioning = true
	GameManager.save_blocked = true
	var p := factory.get("player") as CharacterBody3D
	var had_controls: bool = p.controls_enabled if p else true
	if p:
		p.controls_enabled = false
		p.velocity = Vector3.ZERO
	if not instant:
		_fade(1.0, fade_time)
		await get_tree().create_timer(fade_time).timeout
	GameManager.set_time_state(state)
	apply(state)
	await get_tree().physics_frame
	await get_tree().physics_frame
	if p:
		p.global_position = safe_position(p.global_position)
		p.velocity = Vector3.ZERO
	if not instant:
		AudioManager.play_sfx("chime")
		_fade(0.0, fade_time)
		await get_tree().create_timer(fade_time).timeout
	if p:
		p.controls_enabled = had_controls
	GameManager.save_blocked = false
	transitioning = false
	_cool_until = _clock + cooldown
	switched.emit(state)
	return true


## Oyuncu duvar/engel içindeyse (başka zamanın katmanı belirdi) güvenli konuma taşı.
func fix_player() -> void:
	var p := factory.get("player") as CharacterBody3D
	if p == null:
		return
	await get_tree().physics_frame
	await get_tree().physics_frame
	p.global_position = safe_position(p.global_position)


func is_blocked(pos: Vector3) -> bool:
	var cap := CapsuleShape3D.new()
	cap.radius = PLAYER_RADIUS
	cap.height = PLAYER_HEIGHT
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = cap
	q.transform = Transform3D(Basis(), pos + Vector3(0, PLAYER_HEIGHT * 0.5 + 0.03, 0))
	q.collision_mask = 1
	return not factory.get_world_3d().direct_space_state.intersect_shape(q, 1).is_empty()


func _has_floor(pos: Vector3, ref_y: float) -> bool:
	var q := PhysicsRayQueryParameters3D.create(pos + Vector3(0, 0.6, 0), pos + Vector3(0, -0.8, 0), 1)
	var hit := factory.get_world_3d().direct_space_state.intersect_ray(q)
	return not hit.is_empty() and absf(hit["position"].y - ref_y) < 0.6


func safe_position(pos: Vector3) -> Vector3:
	if not is_blocked(pos):
		return pos
	for r in [0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 4.0]:
		for i in 16:
			var a := TAU * float(i) / 16.0
			var c: Vector3 = pos + Vector3(cos(a), 0, sin(a)) * r
			if not is_blocked(c) and _has_floor(c, pos.y):
				return c
	if _last_safe != Vector3.ZERO and not is_blocked(_last_safe):
		return _last_safe
	var start := FactoryLayout.room(FactoryLayout.START_ROOM)
	return FactoryLayout.room_center(start) + Vector3(0, 0.15, 2.0)


func _process(delta: float) -> void:
	_clock += delta
	_safe_t += delta
	if _safe_t < 0.5:
		return
	_safe_t = 0.0
	var p := factory.get("player") as CharacterBody3D
	if p and p.is_on_floor() and not is_blocked(p.global_position):
		_last_safe = p.global_position


func _fade(alpha: float, time: float) -> void:
	if _overlay == null:
		var layer := CanvasLayer.new()
		layer.layer = 60
		_overlay = ColorRect.new()
		_overlay.color = Color(0, 0, 0, 0)
		_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(_overlay)
		add_child(layer)
		_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	create_tween().tween_property(_overlay, "color:a", alpha, time)


# ------------------------------------------------------------------ dünyadaki katman içeriği
func _build_demo_props() -> void:
	# 2026'ya özel: çökmüş tavan molozu (B Hattı). 2004'te yok, oyuncu bu alanda olabilir → güvenli konuma taşınır.
	var rubble := StaticBody3D.new()
	rubble.collision_layer = 1
	rubble.position = Vector3(-3.0, 0.5, 5.2)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(2.0, 1.0, 1.8)
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.32, 0.31, 0.29)
	mi.material_override = mat
	rubble.add_child(mi)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = bm.size
	cs.shape = bs
	rubble.add_child(cs)
	rubble.name = "Rubble2026"
	factory.add_child(rubble)
	register(rubble, "2026")
	# 2004'e özel: makine başında çalışan işçi siluetleri
	spawn_npc("hatA", Vector3(-8.5, 0, 2.3), "2004", PI)
	spawn_npc("hatB", Vector3(2.5, 0, 2.3), "2004", PI)
	spawn_npc("hatC", Vector3(13.5, 0, 2.3), "2004", PI)
	# Kart okuyucu: B Hattı kuzey duvarı. Yusuf'un kartıyla zaman durumu değişir (Bölüm 5 bitince etkin).
	var cr := CardReader.new()
	cr.position = Vector3(-3.0, 1.4, 7.7)
	cr.layers = self
	var rmi := MeshInstance3D.new()
	var rbm := BoxMesh.new()
	rbm.size = Vector3(0.25, 0.35, 0.06)
	rmi.mesh = rbm
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(0.1, 0.3, 0.4)
	rmi.material_override = rmat
	cr.add_child(rmi)
	var rcs := CollisionShape3D.new()
	var rbs := BoxShape3D.new()
	rbs.size = Vector3(0.4, 0.5, 0.2)
	rcs.shape = rbs
	cr.add_child(rcs)
	factory.add_child(cr)
