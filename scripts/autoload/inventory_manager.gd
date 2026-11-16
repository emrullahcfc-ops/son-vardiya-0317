extends Node
## Benzersiz ID'li eşya envanteri. Kritik eşyalar bırakılamaz / kaybolamaz.

signal item_added(item_id: String)
signal item_removed(item_id: String)

# Eşya tanımları: id -> {name, critical, desc}
const ITEMS := {
	"key_security_booth": {"name": "Güvenlik kulübesi anahtarı", "critical": true, "desc": "Güvenlik kulübesinin kapısını açar."},
	"floor_key": {"name": "Kat anahtarı", "critical": true, "desc": "Personel katının kapısını açar."},
	"worker_id_ayse": {"name": "Ayşe'nin kimliği", "critical": true, "desc": "11 işçiden biri."},
	"multimeter": {"name": "Ölçü aleti", "critical": true, "desc": "Gerilim ölçer."},
	"usb_drive": {"name": "USB bellek", "critical": true, "desc": "Delilleri kopyalamak için."},
}

var _items: Array[String] = []


func add_item(item_id: String) -> bool:
	if not ITEMS.has(item_id):
		push_warning("Bilinmeyen eşya: %s" % item_id)
		return false
	if _items.has(item_id):
		return false  # çift ekleme yok
	_items.append(item_id)
	item_added.emit(item_id)
	return true


func has_item(item_id: String) -> bool:
	return _items.has(item_id)


func remove_item(item_id: String) -> bool:
	if not _items.has(item_id):
		return false
	if ITEMS[item_id].get("critical", false):
		# Kritik eşya yalnızca 'consume_item' ile görev gereği harcanır.
		return false
	_items.erase(item_id)
	item_removed.emit(item_id)
	return true


func consume_item(item_id: String) -> bool:
	if not _items.has(item_id):
		return false
	_items.erase(item_id)
	item_removed.emit(item_id)
	return true


func get_items() -> Array[String]:
	return _items.duplicate()


func clear() -> void:
	_items.clear()


func to_save_data() -> Dictionary:
	return {"items": _items.duplicate()}


func from_save_data(d: Dictionary) -> void:
	_items.clear()
	for id in d.get("items", []):
		if ITEMS.has(id):
			_items.append(String(id))
