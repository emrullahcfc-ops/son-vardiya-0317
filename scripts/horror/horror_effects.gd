class_name HorrorEffects
extends Node
## Korku olaylarının görsel/işitsel etkileri (Aşama 6). HorrorDirector.event_fired'ı dinler.
## Işık titremesi, anons, kapı çarpması, siluet. Flaş azaltma ayarına uyar.

var factory: Node3D


func _ready() -> void:
	HorrorDirector.event_fired.connect(_on_event)


func _process(_d: float) -> void:
	AudioManager.set_layer_db("hum", lerpf(-30.0, -14.0, HorrorDirector.intensity))


## Titreme düzeni: [enerji_çarpanı, süre] çiftleri. flash_reduction açıkken hızlı yanıp sönme YOK:
## tüm adımlar >= 0.3 sn ve en fazla %50 değişir.
static func flicker_pattern(reduced: bool) -> Array:
	if reduced:
		return [[0.6, 0.4], [0.5, 0.4], [0.7, 0.4], [1.0, 0.4]]
	return [[0.1, 0.06], [1.0, 0.05], [0.0, 0.08], [1.0, 0.04], [0.05, 0.10], [1.0, 0.20]]


func _on_event(id: String) -> void:
	match id:
		"ev_flicker":
			_flicker(String(HorrorDirector.EVENTS[id]["area"]))
		"ev_announce":
			AudioManager.play_sfx("chime")
			AudioManager.say("[Anons] 03.17 vardiya değişimi. Herkes yerine.", 5.0)
		"ev_door_slam":
			_door_slam()
		"ev_silhouette":
			_silhouette(String(HorrorDirector.EVENTS[id]["area"]))
		"ev_cant_woman":
			_silhouette(String(HorrorDirector.EVENTS[id]["area"]))
			AudioManager.say("Pencerenin önünde bir kadın duruyordu. Gözünü kırpınca yok oldu.", 4.0)


func _player() -> Node3D:
	return get_tree().get_first_node_in_group("player") as Node3D


func _flicker(room_id: String) -> void:
	var reduced: bool = GameManager.settings.get("flash_reduction", true)
	for l in get_tree().get_nodes_in_group("room_light"):
		if l.get_meta("room_id", "") != room_id:
			continue
		var base: float = l.get_meta("base_energy", l.light_energy)
		AudioManager.play_sfx("buzz", l.global_position, -6.0)
		var tw := create_tween()
		for step in flicker_pattern(reduced):
			tw.tween_property(l, "light_energy", base * float(step[0]), float(step[1]))
		tw.tween_property(l, "light_energy", base, 0.1)


func _door_slam() -> void:
	var p := _player()
	if p == null or factory == null or factory.doors.is_empty():
		return
	var best: Node3D = factory.doors[0]
	for d in factory.doors:
		if d.global_position.distance_to(p.global_position) < best.global_position.distance_to(p.global_position):
			best = d
	AudioManager.play_sfx("door_slam", best.global_position)
	AudioManager.say("Arkanda bir kapı çarptı.", 2.5)


func _silhouette(room_id: String) -> void:
	var p := _player()
	var r := FactoryLayout.room(room_id)
	if p == null or r.is_empty():
		return
	var b: Array = r["r"]
	var y := FactoryLayout.floor_y(r["f"])
	# Oyuncudan en uzak köşeye yakın nokta
	var corners := [Vector3(b[0] + 1, y, b[1] + 1), Vector3(b[2] - 1, y, b[1] + 1), Vector3(b[0] + 1, y, b[3] - 1), Vector3(b[2] - 1, y, b[3] - 1)]
	var far: Vector3 = corners[0]
	for c in corners:
		if c.distance_to(p.global_position) > far.distance_to(p.global_position):
			far = c
	var m := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.3
	cap.height = 1.8
	m.mesh = cap
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0, 0, 0, 1)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.material_override = mat
	get_parent().add_child(m)
	m.global_position = far + Vector3(0, 0.9, 0)
	AudioManager.play_sfx("whisper", m.global_position)
	AudioManager.play_sfx("thump", m.global_position, -4.0)
	var tw := create_tween()  # yavaş solma: ani flaş yok
	tw.tween_interval(1.2)
	tw.tween_property(mat, "albedo_color:a", 0.0, 1.0)
	tw.tween_callback(m.queue_free)
