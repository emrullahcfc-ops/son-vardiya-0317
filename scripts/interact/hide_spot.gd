class_name HideSpot
extends Interactable
## Saklanma noktası (dolap). Görülürken saklanılamaz. İçeride oyuncu görünmez ve ses çıkarmaz;
## E ile çıkılır. Sayıcı aramada yakındaysa dolabı kontrol edebilir.

var occupied := false
var inside_offset := Vector3(0, 0, 0.0)   # oyuncunun içerideki konumu (dolap merkezine göre)
var exit_offset := Vector3(0, 0, 1.0)     # çıkış konumu
var _player: Node
var _layer: CanvasLayer
var _enter_frame := -1


func _ready() -> void:
	add_to_group("hide_spots")


func get_prompt() -> String:
	return "Dolaptan çık" if occupied else "Saklan"


func _do_interact(player: Node) -> bool:
	if occupied:
		exit_spot()
		return true
	return enter_spot(player)


## Hiçbir düşman oyuncuyu o an görüyorsa saklanılamaz (adil kural).
func can_hide() -> bool:
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.has_method("can_see_player") and e.enabled and e.can_see_player():
			return false
	return true


func enter_spot(player: Node) -> bool:
	if occupied:
		return false
	if not can_hide():
		AudioManager.say("Görülürken saklanamazsın.", 2.5)
		return false
	_player = player
	occupied = true
	_enter_frame = Engine.get_process_frames()
	player.hidden = true
	player.controls_enabled = false
	player.global_position = global_transform * inside_offset
	player.velocity = Vector3.ZERO
	var col := player.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col:
		col.disabled = true
	_slit(true)
	AudioManager.say("Dolabın içindesin. Çıkmak için E.", 2.5)
	return true


func exit_spot() -> void:
	if not occupied or _player == null:
		return
	occupied = false
	var col := _player.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col:
		col.disabled = false
	_player.global_position = global_transform * exit_offset
	_player.hidden = false
	_player.controls_enabled = true
	_slit(false)
	_player = null


func _unhandled_input(event: InputEvent) -> void:
	if occupied and event.is_action_pressed("interact") and Engine.get_process_frames() != _enter_frame:
		exit_spot()
		get_viewport().set_input_as_handled()


## Dolap içi görünüm: üst/alt siyah bant, ortada ince aralık.
func _slit(on: bool) -> void:
	if _layer:
		_layer.queue_free()
		_layer = null
	if not on:
		return
	_layer = CanvasLayer.new()
	_layer.layer = 40
	for anchor in [[0.0, 0.46], [0.54, 1.0]]:
		var r := ColorRect.new()
		r.color = Color(0, 0, 0, 1)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.anchor_left = 0.0
		r.anchor_right = 1.0
		r.anchor_top = anchor[0]
		r.anchor_bottom = anchor[1]
		_layer.add_child(r)
	add_child(_layer)
