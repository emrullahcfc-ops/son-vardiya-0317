class_name Keypad
extends Interactable
## Kod tuş takımı. Enerji yoksa çalışmaz; yanlış kodda sınırsız tekrar denenir (kilitlenme yok).
## Mantık try_code() içindedir (testlenebilir); arayüz yalnızca onu çağırır.

@export var code: String = "0317"
@export var power_flag: String = "ch1_power_on"
@export var unlock_flag: String = "ch1_staff_unlocked"
@export var quest_id: String = "ch1_find_door_code"

var _layer: CanvasLayer
var _edit: LineEdit
var _msg: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # oyun duraklayınca ESC ile kapanabilsin


func get_prompt() -> String:
	if GameManager.has_flag(unlock_flag):
		return "Tuş takımı (kilit açık)"
	return "Kodu gir"


func try_code(entered: String) -> bool:
	if GameManager.has_flag(unlock_flag):
		AudioManager.say("Kilit zaten açık.", 1.5)
		return true
	if not GameManager.has_flag(power_flag):
		AudioManager.play_sfx("error")
		AudioManager.say("Panel enerjisiz. Önce elektriği aç.", 2.5)
		return false
	if entered.strip_edges() != code:
		AudioManager.play_sfx("error")
		AudioManager.say("Hatalı kod. Tekrar dene.", 2.0)
		return false
	GameManager.set_flag(unlock_flag)
	AudioManager.play_sfx("beep")
	AudioManager.say("Kod kabul edildi. Personel kapısının kilidi açıldı.", 3.0)
	if not QuestManager.is_active(quest_id):
		QuestManager.start_quest(quest_id)
	QuestManager.complete_quest(quest_id)
	return true


func _do_interact(_player: Node) -> bool:
	if GameManager.has_flag(unlock_flag) or not GameManager.has_flag(power_flag):
		try_code("")
		return false
	_open_ui()
	return true


func _open_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(280, 150)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var title := Label.new()
	title.text = "Personel kapısı — 4 haneli kod"
	box.add_child(title)
	_edit = LineEdit.new()
	_edit.max_length = 4
	_edit.placeholder_text = "____"
	_edit.text_submitted.connect(_submit)
	box.add_child(_edit)
	_msg = Label.new()
	box.add_child(_msg)
	var row := HBoxContainer.new()
	var ok := Button.new()
	ok.text = "Gir"
	ok.pressed.connect(func(): _submit(_edit.text))
	var cancel := Button.new()
	cancel.text = "Kapat (ESC)"
	cancel.pressed.connect(_close_ui)
	row.add_child(ok)
	row.add_child(cancel)
	box.add_child(row)
	_layer.add_child(panel)
	get_tree().root.add_child(_layer)
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_edit.grab_focus()


func _submit(text: String) -> void:
	if try_code(text):
		_close_ui()
	else:
		_msg.text = "Hatalı kod."
		_edit.text = ""


func _unhandled_input(event: InputEvent) -> void:
	if _layer and event.is_action_pressed("pause"):
		_close_ui()
		get_viewport().set_input_as_handled()


func _close_ui() -> void:
	if _layer:
		_layer.queue_free()
		_layer = null
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
