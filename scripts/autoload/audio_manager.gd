extends Node
## Ses yönetimi: ana ses seviyesi ve altyazı olayları.
## Gerçek ses dosyaları sonradan eklenir; şimdilik altyazı her zaman gösterilir.

signal subtitle(text: String, duration: float)


func _ready() -> void:
	GameManager.settings_changed.connect(_apply_volume)
	_apply_volume()


func _apply_volume() -> void:
	var v: float = clampf(float(GameManager.settings.get("master_volume", 1.0)), 0.0, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(v, 0.0001)))


func say(text: String, duration: float = 3.0) -> void:
	if GameManager.settings.get("subtitles", true):
		subtitle.emit(text, duration)
