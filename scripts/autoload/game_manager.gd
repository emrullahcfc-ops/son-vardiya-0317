extends Node
## Oyun durumu, bölüm bilgisi ve kullanıcı ayarları.

signal chapter_changed(chapter_id: int)
signal settings_changed

const SETTINGS_PATH := "user://settings.json"

var current_chapter: int = 1
var flags: Dictionary = {}  # tekil durum bayrakları: id -> bool/değer
var settings: Dictionary = {
	"mouse_sensitivity": 0.0025,
	"fov": 75.0,
	"subtitles": true,
	"subtitle_size": 1.0,
	"flash_reduction": true,
	"master_volume": 1.0,
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


func to_save_data() -> Dictionary:
	return {"chapter": current_chapter, "flags": flags}


func from_save_data(d: Dictionary) -> void:
	current_chapter = int(d.get("chapter", 1))
	flags = d.get("flags", {})
