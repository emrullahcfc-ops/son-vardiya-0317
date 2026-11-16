extends Node
## Görev durumu: active / completed. Bir görev iki kez tamamlanamaz.

signal quest_started(quest_id: String)
signal quest_completed(quest_id: String)

const QUESTS := {
	"ch1_enter_factory": {"title": "Fabrikaya gir", "main": true},
	"ch1_booth_key": {"title": "Güvenlik kulübesinin anahtarını bul", "main": true},
	"ch1_power_staff_door": {"title": "Personel kapısının enerjisini aç", "main": true},
	"ch1_find_door_code": {"title": "Kapı kodunu bul", "main": false},
	"ch2_start_lines": {"title": "Üç hattı sırayla çalıştır", "main": true},
	"ch2_cabinet_code": {"title": "Bakım dolabının kodunu bul", "main": true},
	"ch2_floor_key": {"title": "Kat anahtarını al", "main": true},
}

var _active: Array[String] = []
var _completed: Array[String] = []


func start_quest(quest_id: String) -> bool:
	if not QUESTS.has(quest_id) or _active.has(quest_id) or _completed.has(quest_id):
		return false
	_active.append(quest_id)
	quest_started.emit(quest_id)
	return true


func complete_quest(quest_id: String) -> bool:
	if _completed.has(quest_id) or not _active.has(quest_id):
		return false
	_active.erase(quest_id)
	_completed.append(quest_id)
	quest_completed.emit(quest_id)
	return true


func is_active(quest_id: String) -> bool:
	return _active.has(quest_id)


func is_completed(quest_id: String) -> bool:
	return _completed.has(quest_id)


func clear() -> void:
	_active.clear()
	_completed.clear()


func to_save_data() -> Dictionary:
	return {"active": _active.duplicate(), "completed": _completed.duplicate()}


func from_save_data(d: Dictionary) -> void:
	_active.clear()
	_completed.clear()
	for id in d.get("active", []):
		if QUESTS.has(id):
			_active.append(String(id))
	for id in d.get("completed", []):
		if QUESTS.has(id):
			_completed.append(String(id))
