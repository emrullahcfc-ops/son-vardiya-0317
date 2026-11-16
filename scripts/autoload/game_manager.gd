extends Node
## Oyun durumu, bölüm bilgisi ve kullanıcı ayarları.

signal chapter_changed(chapter_id: int)
signal settings_changed

const SETTINGS_PATH := "user://settings.json"

signal area_entered(area_id: String, area_name: String, counted: bool)

var current_chapter: int = 1
var flags: Dictionary = {}  # tekil durum bayrakları: id -> bool/değer
var visited_areas: Array[String] = []  # ziyaret edilen ana alanlar
var current_area_id: String = ""
var settings: Dictionary = {
	"mouse_sensitivity": 0.0025,
	"fov": 75.0,
	"subtitles": true,
	"subtitle_size": 1.0,
	"flash_reduction": true,
	"master_volume": 1.0,
	"sfx_volume": 1.0,
	"ambient_volume": 1.0,
}


func _ready() -> void:
	load_settings()


func set_flag(id: String, value: Variant = true) -> void:
	flags[id] = value


func has_flag(id: String) -> bool:
	return flags.get(id, false) != false


func set_chapter(chapter_id: int) -> void:
	if chapter_id == current_chapter:
		return
	current_chapter = chapter_id
	chapter_changed.emit(chapter_id)


func apply_setting(key: String, value: Variant) -> void:
	settings[key] = value
	settings_changed.emit()
	save_settings()


func save_settings() -> void:
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(settings))


func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SETTINGS_PATH))
	if parsed is Dictionary:
		for k in parsed:
			if settings.has(k):
				settings[k] = parsed[k]


func enter_area(area_id: String, area_name: String, counted: bool = true) -> void:
	current_area_id = area_id
	if counted and not visited_areas.has(area_id):
		visited_areas.append(area_id)
	area_entered.emit(area_id, area_name, counted)


func to_save_data() -> Dictionary:
	return {"chapter": current_chapter, "flags": flags, "visited": visited_areas.duplicate()}


func from_save_data(d: Dictionary) -> void:
	current_chapter = int(d.get("chapter", 1))
	flags = d.get("flags", {})
	visited_areas.clear()
	for id in d.get("visited", []):
		visited_areas.append(String(id))
