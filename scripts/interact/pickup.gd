class_name Pickup
extends Interactable
## Alınabilir eşya. Alındığında envantere gider ve bayrakla kayda geçer (kaybolmaz, tekrar çıkmaz).

@export var item_id: String = ""
@export var pickup_id: String = ""   # sahnede tekil kimlik


func _ready() -> void:
	one_shot = true
	if pickup_id != "" and GameManager.has_flag("pickup_" + pickup_id):
		queue_free()  # daha önce alınmış
		return
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.18, 0.06, 0.08)
	m.mesh = b
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.75, 0.2)
	m.material_override = mat
	add_child(m)
	var s := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(0.3, 0.2, 0.2)
	s.shape = bs
	add_child(s)


func get_prompt() -> String:
	var n: String = InventoryManager.ITEMS.get(item_id, {}).get("name", item_id)
	return "Al: %s" % n


func _do_interact(_player: Node) -> bool:
	if InventoryManager.add_item(item_id):
		if pickup_id != "":
			GameManager.set_flag("pickup_" + pickup_id)
		AudioManager.say("Aldın: %s" % InventoryManager.ITEMS[item_id]["name"], 2.0)
		queue_free()
		return true
	return false
