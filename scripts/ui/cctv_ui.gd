class_name CctvUI
extends CanvasLayer
## Kamera monitörü arayüzü: 6 kamera seçilir, canlı görüntü ya da kayıtlı klip izlenir, kritik klipler işaretlenir.
## Görüntü: ana dünyayı gören bir SubViewport + Camera3D (yalnızca seçili kamera çizilir: performans).

signal closed

var chapter: Chapter4
var cam_id := ""
var clip_id := ""

var _sub: SubViewport
var _cam: Camera3D
var _title: Label
var _stamp: Label
var _status: Label
var _marks: Label
var _clip_row: HBoxContainer
var _mark_btn: Button
var _play_time := 0.0
var _cam_buttons: Dictionary = {}


func _ready() -> void:
	layer = 30
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.03, 0.03, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 20)
	margin.add_child(hb)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(230, 0)
	hb.add_child(left)
	var head := Label.new()
	head.text = "GÜVENLİK KAMERALARI"
	left.add_child(head)
	for c in CctvData.CAMERAS:
		var b := Button.new()
		b.text = String(c["name"])
		b.pressed.connect(select_camera.bind(String(c["id"])))
		left.add_child(b)
		_cam_buttons[c["id"]] = b
	var close := Button.new()
	close.text = "Kapat (ESC)"
	close.pressed.connect(func(): closed.emit())
	left.add_child(close)

	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(center)
	_title = Label.new()
	center.add_child(_title)
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.custom_minimum_size = Vector2(800, 450)
	svc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.add_child(svc)
	_sub = SubViewport.new()
	_sub.size = Vector2i(800, 450)
	_sub.world_3d = chapter.factory.get_world_3d()
	_sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	svc.add_child(_sub)
	_cam = Camera3D.new()
	_cam.fov = 75.0
	_sub.add_child(_cam)
	var tint := ColorRect.new()  # kamera yeşili
	tint.color = Color(0.05, 0.3, 0.12, 0.16)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	svc.add_child(tint)
	_stamp = Label.new()
	_stamp.position = Vector2(12, 8)
	svc.add_child(_stamp)
	_clip_row = HBoxContainer.new()
	center.add_child(_clip_row)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	center.add_child(_status)
	var row := HBoxContainer.new()
	center.add_child(row)
	_mark_btn = Button.new()
	_mark_btn.text = "Delil olarak işaretle"
	_mark_btn.pressed.connect(mark_current)
	row.add_child(_mark_btn)
	_marks = Label.new()
	row.add_child(_marks)
	select_camera("k1")
	_refresh_marks()


func select_camera(id: String) -> void:
	chapter.stop_clip()
	chapter.live_view_left()
	cam_id = id
	clip_id = ""
	var c := CctvData.get_camera(id)
	_cam.look_at_from_position(c["pos"], c["look"])
	_title.text = "%s   ● CANLI" % c["name"]
	for ch in _clip_row.get_children():
		ch.queue_free()
	var live := Button.new()
	live.text = "CANLI"
	live.pressed.connect(func(): select_camera(id))
	_clip_row.add_child(live)
	for cl in CctvData.clips_for(id):
		var b := Button.new()
		b.text = "Kayıt " + String(cl["time"])
		b.pressed.connect(play.bind(String(cl["id"])))
		_clip_row.add_child(b)
	_status.text = "Bir kayıt seç ya da canlı görüntüyü izle."
	_play_time = 0.0
	chapter.live_view_entered(id)


func play(id: String) -> void:
	clip_id = id
	var cl := CctvData.get_clip(id)
	_play_time = 0.0
	_title.text = "%s   ▶ KAYIT %s — %s" % [CctvData.get_camera(cl["cam"])["name"], cl["time"], cl["title"]]
	chapter.play_clip(id)
	_status.text = "Oynatılıyor: %s. Önemli görünüyorsa işaretle." % cl["title"]


func mark_current() -> String:
	if clip_id == "":
		_status.text = "Önce bir kayıt izle."
		return "none"
	var r := chapter.mark_clip(clip_id)
	var msgs := {
		"not_seen": "Önce bu kaydı izle.",
		"decoy": "Bu kayıt olayla ilgisiz görünüyor.",
		"wrong_order": "Sıra tutmuyor: işaretler sıfırlandı. Saat sırasına göre tekrar dene.",
		"ok": "İşaretlendi.",
		"ok_done": "Üç kayıt sırayla işaretlendi. USB'ye kopyalandı; ses kaydı çalıyor.",
		"already": "Bu kayıt zaten işaretli ya da delil tamamlandı.",
	}
	_status.text = String(msgs.get(r, r))
	_refresh_marks()
	return r


func _refresh_marks() -> void:
	var parts: Array = []
	for id in chapter.marks():
		parts.append(String(CctvData.get_clip(id)["time"]))
	_marks.text = "   İşaretli: " + (" → ".join(parts) if not parts.is_empty() else "—")


func _process(delta: float) -> void:
	if clip_id != "":
		_play_time += delta
		var cl := CctvData.get_clip(clip_id)
		_stamp.text = "%s.%02d  REC" % [cl["time"], int(_play_time) % 60]
	else:
		_stamp.text = "CANLI"


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		closed.emit()
		get_viewport().set_input_as_handled()
