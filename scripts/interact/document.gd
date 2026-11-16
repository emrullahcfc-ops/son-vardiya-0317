class_name Document
extends Interactable
## Okunabilir belge. Tekrar okunabilir; altyazı sistemi üzerinden metni gösterir.

@export var title: String = "Belge"
@export_multiline var body: String = ""
@export var flag_on_read: String = ""

const READ_TIME := 6.0


func _ready() -> void:
	var m := MeshInstance3D.new()
	var q := BoxMesh.new()
	q.size = Vector3(0.21, 0.01, 0.3)
	m.mesh = q
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.83, 0.75)
	m.material_override = mat
	add_child(m)
	var s := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(0.3, 0.15, 0.4)
	s.shape = bs
	add_child(s)


func get_prompt() -> String:
	return "Oku: %s" % title


func _do_interact(_player: Node) -> bool:
	AudioManager.say("%s — %s" % [title, body], READ_TIME)
	if flag_on_read != "":
		GameManager.set_flag(flag_on_read)
	return true
