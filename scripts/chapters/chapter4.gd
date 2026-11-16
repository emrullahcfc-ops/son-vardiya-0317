class_name Chapter4
extends ChapterBase
## Bölüm 4: Kamera Kayıtları. Kamera odasındaki monitörden 6 kamera izlenir; klipler önceden kaydedilmiş gibi
## sahnelenir. Oyuncu üç kritik görüntüyü (03.14 → 03.16 → 03.17) doğru sırada işaretler. Canlı kamerada
## (K5) arkada işçi silueti + anons korkusu. Delil tamamlanınca Selim–Yusuf ses kaydı ve bodruma yönlendiren görev.

const Y := 4.0

var _wait := true               # klip/kayıt süreleri gerçek zamanlı (testte false)
var current_clip := ""
var played_lines: Array = []    # oynatılan altyazı satırları (test için)
var tape_lines: Array = []
var actors: Array = []
var scare_node: Node3D
var ui: CctvUI
var _prev_controls := true

signal clip_started(clip_id: String)
signal evidence_completed


func _ready() -> void:
	_build_props()
	GameManager.chapter_changed.connect(func(c): if c >= 4: _begin())
	GameManager.area_entered.connect(_on_area)
	if GameManager.current_chapter >= 4:
		_begin()


func _begin() -> void:
	if not GameManager.has_flag("ch4_evidence"):
		QuestManager.start_quest("ch4_mark_evidence")


func _on_area(id: String, _n: String, _c: bool) -> void:
	if id == "u_cam" and GameManager.has_flag("ch3_done") and not GameManager.has_flag("ch4_hint"):
		GameManager.set_flag("ch4_hint")
		AudioManager.say("Kamera odası. Monitörden kayıtları izle ve olayları zaman sırasına diz.", 5.0)


# ------------------------------------------------------------------ monitör
func monitors_on() -> bool:
	return GameManager.has_flag("ch3_done")


func open_monitor() -> bool:
	if not monitors_on():
		AudioManager.say("Monitörler kapalı. Önce personel katındaki işi bitir.", 3.0)
		return false
	if ui != null:
		return true
	var p := factory.get("player") as CharacterBody3D
	_prev_controls = p.controls_enabled if p else true
	if p:
		p.controls_enabled = false
	ui = CctvUI.new()
	ui.chapter = self
	ui.closed.connect(close_monitor)
	factory.add_child(ui)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	return true


func close_monitor() -> void:
	stop_clip()
	live_view_left()
	if ui:
		ui.queue_free()
		ui = null
	var p := factory.get("player") as CharacterBody3D
	if p:
		p.controls_enabled = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# ------------------------------------------------------------------ klip oynatma
func play_clip(clip_id: String) -> bool:
	var clip := CctvData.get_clip(clip_id)
	if clip.is_empty():
		return false
	stop_clip()
	current_clip = clip_id
	GameManager.set_flag("ch4_seen_" + clip_id)
	var specs: Array = clip["actors"].duplicate()
	if clip_id == "c_0317":
		for i in 11:
			specs.append({"name": "İşçi %d" % (i + 1), "from": Vector3(-1.5 + (i % 3) * 1.5, 0, 15.0 - (i / 3) * 1.0), "to": Vector3(-1.5 + (i % 3) * 1.5 * 0.2, 0, 9.0), "start": 1.0 + i * 0.5, "dur": 4.0})
	for a in specs:
		_spawn_actor(a, clip_id)
	if clip.has("sfx"):
		AudioManager.play_sfx(String(clip["sfx"]))
	for l in clip["lines"]:
		_schedule_line(clip_id, float(l[0]), String(l[1]))
	if _wait:
		get_tree().create_timer(float(clip["dur"])).timeout.connect(func(): if current_clip == clip_id: stop_clip())
	clip_started.emit(clip_id)
	return true


func _schedule_line(clip_id: String, t: float, text: String) -> void:
	if _wait and t > 0.0:
		get_tree().create_timer(t).timeout.connect(func(): if current_clip == clip_id: _show_line(text))
	else:
		_show_line(text)


func _show_line(text: String) -> void:
	played_lines.append(text)
	AudioManager.say(text, 4.0)


func stop_clip() -> void:
	current_clip = ""
	for a in actors:
		if is_instance_valid(a):
			if a.get_parent():
				a.get_parent().remove_child(a)  # hemen kaldır (kuyrukta bekleyip kameraya görünmesin)
			a.queue_free()
	actors.clear()


func _spawn_actor(spec: Dictionary, clip_id: String) -> void:
	var m := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.28
	cap.height = 1.7
	m.mesh = cap
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.75, 0.78, 0.72)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.material_override = mat
	m.name = "CctvActor_" + String(spec["name"])
	factory.add_child(m)
	m.global_position = (spec["from"] as Vector3) + Vector3(0, 0.85, 0)
	m.visible = not _wait or float(spec["start"]) <= 0.0
	actors.append(m)
	var to: Vector3 = (spec["to"] as Vector3) + Vector3(0, 0.85, 0)
	if _wait:
		var tw := create_tween()
		tw.tween_interval(float(spec["start"]))
		tw.tween_callback(func(): if is_instance_valid(m): m.visible = true)
		tw.tween_property(m, "global_position", to, float(spec["dur"]))
	else:
		m.global_position = to


# ------------------------------------------------------------------ işaretleme
func marks() -> Array:
	var v: Variant = GameManager.flags.get("ch4_marks", [])
	return v if v is Array else []


func has_seen(clip_id: String) -> bool:
	return GameManager.has_flag("ch4_seen_" + clip_id)


## Sonuç: "not_seen", "decoy", "wrong_order", "ok", "ok_done", "already".
## Yanlış sırada işaretler sıfırlanır ve tekrar denenir (kilitlenme yok).
func mark_clip(clip_id: String) -> String:
	if GameManager.has_flag("ch4_evidence"):
		return "already"
	var clip := CctvData.get_clip(clip_id)
	if clip.is_empty() or not has_seen(clip_id):
		AudioManager.say("Önce bu görüntüyü izlemelisin.", 2.5)
		return "not_seen"
	if not clip["critical"]:
		AudioManager.say("Bu görüntü olayla ilgisiz. Zaman çizelgesine bak.", 3.0)
		return "decoy"
	var m := marks().duplicate()
	if m.has(clip_id):
		AudioManager.say("Bu görüntüyü zaten işaretledin.", 2.0)
		return "already"
	if clip_id != CctvData.ORDER[m.size()]:
		GameManager.flags["ch4_marks"] = []
		AudioManager.play_sfx("error")
		AudioManager.say("Sıra tutmuyor. İşaretler sıfırlandı; olayları saat sırasına diz.", 4.0)
		return "wrong_order"
	m.append(clip_id)
	GameManager.flags["ch4_marks"] = m
	AudioManager.play_sfx("beep")
	if m.size() == CctvData.ORDER.size():
		_evidence_done()
		return "ok_done"
	AudioManager.say("İşaretlendi (%d/3): %s" % [m.size(), clip["time"]], 3.0)
	return "ok"


func _evidence_done() -> void:
	GameManager.set_flag("ch4_evidence")
	_complete("ch4_mark_evidence")
	InventoryManager.add_item("usb_drive")
	AudioManager.say("Üç kayıt sırayla işaretlendi ve USB belleğe kopyalandı.", 4.0)
	evidence_completed.emit()
	play_tape()


## Selim–Yusuf ses kaydı + bodruma yönlendiren görev güncellemesi + Bölüm 5.
func play_tape() -> void:
	GameManager.set_flag("ch4_tape")
	GameManager.set_flag("ch4_done")
	tape_lines.clear()
	for l in CctvData.TAPE:
		tape_lines.append(l)
	QuestManager.start_quest("ch4_basement")
	GameManager.set_chapter(5)
	_checkpoint()
	AudioManager.play_sfx("click")
	for i in tape_lines.size():
		if _wait:
			await get_tree().create_timer(4.2 if i > 0 else 1.5).timeout
			if not is_inside_tree():
				return
		AudioManager.say(tape_lines[i], 4.0)
	if _wait:
		await get_tree().create_timer(4.2).timeout
	AudioManager.say("Kayıt bitti. Mühür panosu bodrumdaki kontrol odasında.", 5.0)


# ------------------------------------------------------------------ canlı kamera korkusu
## K5 (kamera odası) canlı izlenirken, en az bir kritik görüntü işaretlendiyse: sandalyenin arkasında
## işçi silueti + anons. Yalnızca bir kez; ekran kapanınca silinir.
func live_view_entered(cam_id: String) -> bool:
	if cam_id != "k5" or marks().size() < 1 or GameManager.has_flag("ch4_scare"):
		return false
	GameManager.set_flag("ch4_scare")
	scare_node = MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.3
	cap.height = 1.8
	(scare_node as MeshInstance3D).mesh = cap
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.02, 0.02, 0.02)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	(scare_node as MeshInstance3D).material_override = mat
	factory.add_child(scare_node)
	scare_node.global_position = Vector3(13.0, Y + 0.9, 2.0)  # sandalyenin (14.2, 2.0) hemen arkası
	AudioManager.play_sfx("whisper", scare_node.global_position)
	AudioManager.play_sfx("chime")
	AudioManager.say("[Anons] Sayım için on iki kişi bekleniyor. Eksik: bir.", 5.0)
	return true


func live_view_left() -> void:
	if scare_node and is_instance_valid(scare_node):
		scare_node.queue_free()
		scare_node = null
		AudioManager.say("Arkana bakıyorsun. Kimse yok.", 3.0)


# ------------------------------------------------------------------ sahne
func _build_props() -> void:
	# Kamera odası (x 6..16, z -4..8, üst kat): masa, monitör, sandalye
	_box(factory, Vector3(15.3, Y + 0.45, 2.0), Vector3(0.9, 0.9, 3.0), Color(0.3, 0.27, 0.22))
	_spot(factory, Vector3(15.0, Y + 1.25, 2.0), Vector3(0.1, 0.55, 0.9), Color(0.1, 0.2, 0.15), func(): return "Kamera monitörü", func(_p): open_monitor())
	_box(factory, Vector3(14.2, Y + 0.45, 2.0), Vector3(0.5, 0.9, 0.5), Color(0.2, 0.2, 0.22))
	_doc(Vector3(15.4, Y + 0.93, 0.6), "Olay çizelgesi", "Kritik saatler: 03.14, 03.16, 03.17. Kayıtları saat sırasına göre işaretle.")
