class_name CardReader
extends Interactable
## Kart okuyucu: kartı okutunca zaman durumu kontrollü biçimde değişir (2026 ⇄ 2004).
## Enerji bayrağı yoksa çalışmaz; kart yoksa çalışmaz; geçiş sürerken/bekleme süresinde tekrar basılamaz.

@export var required_item: String = "yusuf_card"
@export var enabled_flag: String = "ch5_done"

var layers: TimeLayers


func get_prompt() -> String:
	if not GameManager.has_flag(enabled_flag):
		return "Kart okuyucu (enerjisiz)"
	var target := "2004" if GameManager.time_state == "2026" else "2026"
	return "Kartı okut: %s'e geç" % target


func _do_interact(_player: Node) -> bool:
	if not GameManager.has_flag(enabled_flag):
		AudioManager.say("Kart okuyucu enerjisiz.", 2.5)
		AudioManager.play_sfx("error")
		return false
	if not InventoryManager.has_item(required_item):
		AudioManager.say("Okuyucu bir personel kartı istiyor.", 2.5)
		AudioManager.play_sfx("error")
		return false
	if layers == null or not layers.can_switch():
		AudioManager.say("Okuyucu meşgul. Biraz bekle.", 2.0)
		return false
	var target := "2004" if GameManager.time_state == "2026" else "2026"
	AudioManager.play_sfx("beep")
	AudioManager.say("Kart okundu. Zaman kayıyor: %s" % target, 3.0)
	layers.switch_to(target)
	return true
