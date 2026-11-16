class_name Door
extends Interactable
## Açılır / kilitli kapı. Anahtar gerektirebilir. Kapı hareketi çarpışma ile oyuncuyu sıkıştırmaz:
## oyuncu kapı hacmindeyse kapı kapanmaz.

@export var door_id: String = ""
@export var required_item: String = ""   # boşsa kilitsiz
@export var consume_key: bool = false
@export var required_flag: String = ""   # bayrak yoksa kilitli (ör. enerji + kod)
@export var locked_hint: String = "Kilitli."
@export var only_in_state: String = ""   # "2004"/"2026": yalnızca o zaman durumunda kullanılabilir
@export var open_angle: float = 100.0
@export var size: Vector3 = Vector3(1.0, 2.1, 0.1)

var is_open := false
var _base_y := 0.0   # kapalı konumdaki dönüş (duvar yönüne göre)
var _tween: Tween
var _mesh: MeshInstance3D
var _shape: CollisionShape3D


func _ready() -> void:
	add_to_group("doors")
	_base_y = rotation.y
	var box := BoxMesh.new()
	box.size = size
	_mesh = MeshInstance3D.new()
	_mesh.mesh = box
	_mesh.position = Vector3(size.x * 0.5, size.y * 0.5, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.22, 0.2)
	_mesh.material_override = mat
	add_child(_mesh)
	_shape = CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	_shape.shape = bs
	_shape.position = _mesh.position
	add_child(_shape)
	collision_layer = 5  # world + interactable
	if door_id != "" and GameManager.has_flag("door_open_" + door_id):
		_set_open_instant(true)


func get_prompt() -> String:
	if is_open:
		return "Kapıyı kapat"
	if _is_locked():
		return "Kilitli"
	return "Kapıyı aç"


func _do_interact(player: Node) -> bool:
	if _tween and _tween.is_running():
		return false
	if is_open:
		return _close(player)
	if required_item != "" and not InventoryManager.has_item(required_item):
		var name: String = InventoryManager.ITEMS.get(required_item, {}).get("name", "bir anahtar")
		AudioManager.say("Kilitli. %s gerekiyor." % name, 2.5)
		return false
	if only_in_state != "" and GameManager.time_state != only_in_state:
		AudioManager.say("Bu kapı şu anki zamanda kullanılamıyor.", 3.0)
		return false
	if required_flag != "" and not GameManager.has_flag(required_flag):
		AudioManager.say(locked_hint, 3.0)
		return false
	if required_item != "" and consume_key:
		InventoryManager.consume_item(required_item)
	_open()
	return true


## Düşman gibi sistemler kilidi yok sayıp kapıyı açar.
func force_open() -> void:
	if is_open:
		return
	_open(false)  # düşmanın açışı gürültü sayılmaz (kendi sesini duymasın)


func _is_locked() -> bool:
	if only_in_state != "" and GameManager.time_state != only_in_state:
		return true
	if required_item != "" and not InventoryManager.has_item(required_item):
		return true
	return required_flag != "" and not GameManager.has_flag(required_flag)


func _open(noisy := true) -> void:
	if noisy:
		GameManager.make_noise(global_position, 6.0, "door")  # oyuncu açınca düşman duyabilir
	is_open = true
	if door_id != "":
		GameManager.set_flag("door_open_" + door_id)
	_animate(_base_y - deg_to_rad(open_angle))


func _close(player: Node) -> bool:
	# Oyuncu kapının yolundaysa kapatma: sıkışmayı önler.
	if player is Node3D and _player_in_swing(player as Node3D):
		AudioManager.say("Yolunda biri var.", 1.5)
		return false
	is_open = false
	if door_id != "":
		GameManager.flags.erase("door_open_" + door_id)
	_animate(_base_y)
	return true


func _player_in_swing(p: Node3D) -> bool:
	# Kapalı konumun yerel çerçevesinde, kapının süpürdüğü kareye bak.
	var closed := Transform3D(Basis(Vector3.UP, _base_y), global_position)
	var local := closed.affine_inverse() * p.global_position
	return local.x > -0.2 and local.x < size.x + 0.2 and absf(local.z) < size.x + 0.2


func _animate(target_y: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "rotation:y", target_y, 0.6).set_trans(Tween.TRANS_SINE)


func _set_open_instant(open: bool) -> void:
	is_open = open
	rotation.y = (_base_y - deg_to_rad(open_angle)) if open else _base_y
