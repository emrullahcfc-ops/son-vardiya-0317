extends Node
## Korku olayı motoru (Aşama 6): alana bağlı olaylar, tek seferlik, bekleme süresi (cooldown),
## bölüm koşulu ve yoğunluk (intensity). Olay etkilerini HorrorEffects uygular; bu sınıf sadece karar verir.
## Olaylar üst üste binmez; kayıttan sonra tekrar etmez.

signal event_fired(event_id: String)

const GLOBAL_COOLDOWN := 20.0  # saniye

# area: oyuncu bu alana girince denenir. min_chapter: en erken bölüm. boost: yoğunluk artışı.
const EVENTS := {
	"ev_flicker": {"area": "g_lineB", "min_chapter": 1, "boost": 0.20},
	"ev_announce": {"area": "g_lineA", "min_chapter": 1, "boost": 0.30},
	"ev_door_slam": {"area": "g_maint", "min_chapter": 1, "boost": 0.25},
	"ev_silhouette": {"area": "b_tunnel", "min_chapter": 1, "boost": 0.40},
}

var cooldown: float = GLOBAL_COOLDOWN
var intensity: float = 0.0  # 0..1; ortam sesi ve olay sıklığı buna bağlanır

var _fired: Array[String] = []
var _last_time: float = -9999.0
var _clock: float = 0.0


func _ready() -> void:
	GameManager.area_entered.connect(_on_area)


func _process(delta: float) -> void:
	_clock += delta
	var base := clampf(0.05 * GameManager.current_chapter, 0.0, 0.5)
	intensity = maxf(base, intensity - 0.02 * delta)


func _on_area(area_id: String, _name: String, _counted: bool) -> void:
	for id in EVENTS:
		if EVENTS[id]["area"] == area_id:
			if fire(id, EVENTS[id]["min_chapter"]):
				return


func can_fire(event_id: String, min_chapter: int = 1) -> bool:
	if _fired.has(event_id):
		return false
	if GameManager.current_chapter < min_chapter:
		return false
	if _clock - _last_time < cooldown:
		return false
	return true


func fire(event_id: String, min_chapter: int = 1) -> bool:
	if not can_fire(event_id, min_chapter):
		return false
	_fired.append(event_id)
	_last_time = _clock
	intensity = clampf(intensity + float(EVENTS.get(event_id, {}).get("boost", 0.1)), 0.0, 1.0)
	event_fired.emit(event_id)
	return true


## Test modu: koşulları yok sayıp olayı oynatır (tek seferlik kaydı tutmaz).
func force_fire(event_id: String) -> void:
	if EVENTS.has(event_id):
		event_fired.emit(event_id)


func has_fired(event_id: String) -> bool:
	return _fired.has(event_id)


func to_save_data() -> Dictionary:
	return {"fired": _fired.duplicate()}


func from_save_data(d: Dictionary) -> void:
	_fired.clear()
	for id in d.get("fired", []):
		_fired.append(String(id))
	_last_time = _clock  # yüklemeden hemen sonra olay patlamasın
	intensity = 0.0
