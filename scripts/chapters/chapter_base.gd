class_name ChapterBase
extends Node
## Bölüm betikleri için ortak yardımcılar: kutu/etkileşim noktası/eşya/belge üretimi, görev tamamlama.

var factory: Node3D
var _overlay: ColorRect


## Kontrol noktası: oyuncunun konumu + kayıt.
func _checkpoint() -> void:
	var p := factory.get("player") as Node3D if factory else null
	if p:
		GameManager.set_checkpoint(p.global_position, p.rotation.y)
	SaveManager.save_game()


func _complete(quest_id: String) -> void:
	if not QuestManager.is_active(quest_id) and not QuestManager.is_completed(quest_id):
		QuestManager.start_quest(quest_id)
	QuestManager.complete_quest(quest_id)


func _mat(c: Color, unshaded := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


func _box(parent: Node, pos: Vector3, size: Vector3, c: Color, rot_y := 0.0) -> StaticBody3D:
	var b := StaticBody3D.new()
	b.collision_layer = 1
	b.position = pos
	b.rotation.y = rot_y
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(c)
	b.add_child(mi)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	b.add_child(cs)
	parent.add_child(b)
	return b


func _spot(parent: Node, pos: Vector3, size: Vector3, c: Color, prompt: Callable, action: Callable) -> CallbackInteractable:
	var it := CallbackInteractable.new()
	it.position = pos
	it.prompt_fn = prompt
	it.action_fn = action
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(c)
	it.add_child(mi)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size + Vector3(0.15, 0.15, 0.15)
	cs.shape = bs
	it.add_child(cs)
	parent.add_child(it)
	return it


func _pickup(pos: Vector3, item: String, pid: String) -> void:
	var p := Pickup.new()
	p.item_id = item
	p.pickup_id = pid
	p.position = pos
	factory.add_child(p)


func _doc(pos: Vector3, title: String, body: String, flag := "") -> void:
	var d := Document.new()
	d.title = title
	d.body = body
	d.flag_on_read = flag
	d.position = pos
	factory.add_child(d)


## Ekranı karart / aç (ölüm geçişi).
func _fade(alpha: float, time: float) -> void:
	if _overlay == null:
		var layer := CanvasLayer.new()
		layer.layer = 50
		_overlay = ColorRect.new()
		_overlay.color = Color(0, 0, 0, 0)
		_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(_overlay)
		add_child(layer)
		_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	create_tween().tween_property(_overlay, "color:a", alpha, time)


## Saklanma dolabı (HideSpot). exit_dir: dolaptan çıkış konumu (dolaba göre).
func _hide_locker(pos: Vector3, exit_dir: Vector3) -> HideSpot:
	var h := HideSpot.new()
	h.position = pos
	h.exit_offset = exit_dir
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.7, 2.0, 0.7)
	mi.mesh = bm
	mi.material_override = _mat(Color(0.25, 0.3, 0.27))
	mi.position.y = 1.0
	h.add_child(mi)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(0.8, 2.0, 0.8)
	cs.shape = bs
	cs.position.y = 1.0
	h.add_child(cs)
	h.collision_layer = 5  # dünya + etkileşim (oyuncu içeri giremesin; saklanma ışınlama ile)
	factory.add_child(h)
	return h
