class_name Interactable
extends StaticBody3D
## Tüm etkileşimli nesnelerin tabanı. Ekranda ipucu ve tekrar etkileşim durumu sağlar.

@export var prompt_text: String = "Etkileşim"
@export var one_shot: bool = false

var used := false
var time_state_required := ""   # boş: her zaman; "2004"/"2026": yalnızca o zaman durumunda kullanılabilir


func _init() -> void:
	collision_layer = 4  # interactable


func get_prompt() -> String:
	return prompt_text


func interact(player: Node) -> void:
	if time_state_required != "" and GameManager.time_state != time_state_required:
		return
	if one_shot and used:
		return
	if _do_interact(player):
		used = true


## Alt sınıflar ezer. Başarılıysa true döner.
func _do_interact(_player: Node) -> bool:
	return true
