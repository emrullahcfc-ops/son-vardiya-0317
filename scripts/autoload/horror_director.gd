extends Node
## Korku olayları: tek seferlik, bekleme süresi (cooldown) ve yoğunluk kontrolü.
## Olaylar üst üste binmez; kayıttan sonra tekrar etmez.

signal event_fired(event_id: String)

const GLOBAL_COOLDOWN := 20.0  # saniye

var _fired: Array[String] = []
var _last_time: float = -9999.0
var _clock: float = 0.0


func _process(delta: float) -> void:
	_clock += delta


func can_fire(event_id: String, min_chapter: int = 1) -> bool:
	if _fired.has(event_id):
		return false
	if GameManager.current_chapter < min_chapter:
		return false
	if _clock - _last_time < GLOBAL_COOLDOWN:
		return false
	return true


func fire(event_id: String, min_chapter: int = 1) -> bool:
	if not can_fire(event_id, min_chapter):
		return false
	_fired.append(event_id)
	_last_time = _clock
	event_fired.emit(event_id)
	return true


func has_fired(event_id: String) -> bool:
	return _fired.has(event_id)


func to_save_data() -> Dictionary:
	return {"fired": _fired.duplicate()}


func from_save_data(d: Dictionary) -> void:
	_fired.clear()
	for id in d.get("fired", []):
		_fired.append(String(id))
	_last_time = _clock  # yüklemeden hemen sonra olay patlamasın
