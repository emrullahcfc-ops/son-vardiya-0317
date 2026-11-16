class_name CallbackInteractable
extends Interactable
## Bölüm betiklerinin kullandığı genel etkileşim noktası: ipucu ve eylem Callable ile verilir.

var prompt_fn: Callable
var action_fn: Callable


func get_prompt() -> String:
	if prompt_fn.is_valid():
		return String(prompt_fn.call())
	return prompt_text


func _do_interact(player: Node) -> bool:
	if action_fn.is_valid():
		action_fn.call(player)
	return true
