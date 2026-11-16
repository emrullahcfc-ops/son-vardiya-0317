extends Node
## JSON kayıt/yükleme. Bozuk veya eksik kayıtta güvenli geri dönüş yapar.

signal save_corrupted

const SAVE_PATH := "user://savegame.json"
const BACKUP_PATH := "user://savegame.bak.json"
const VERSION := 1


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> bool:
	var data := {
		"version": VERSION,
		"game": GameManager.to_save_data(),
		"inventory": InventoryManager.to_save_data(),
		"quests": QuestManager.to_save_data(),
		"horror": HorrorDirector.to_save_data(),
	}
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.copy_absolute(SAVE_PATH, BACKUP_PATH)
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Kayıt dosyası yazılamadı.")
		return false
	f.store_string(JSON.stringify(data))
	return true


func load_game() -> bool:
	if _try_load(SAVE_PATH):
		return true
	save_corrupted.emit()
	return _try_load(BACKUP_PATH)


func _try_load(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return false  # bozuk dosya: sessizce başarısız say, yedeğe düşülür
	var parsed: Variant = json.data
	if not (parsed is Dictionary):
		return false
	if int(parsed.get("version", 0)) != VERSION:
		return false
	GameManager.from_save_data(parsed.get("game", {}))
	InventoryManager.from_save_data(parsed.get("inventory", {}))
	QuestManager.from_save_data(parsed.get("quests", {}))
	HorrorDirector.from_save_data(parsed.get("horror", {}))
	return true


func delete_save() -> void:
	for p in [SAVE_PATH, BACKUP_PATH]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)
