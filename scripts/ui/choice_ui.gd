class_name ChoiceUI
extends CanvasLayer
## İki seçenekli diyalog penceresi (ör. Yusuf'un telefonu). Oyun duraklar; seçim bir kez yapılır.

signal chosen(index: int)

var prompt := ""
var options: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 45
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.8)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(720, 0)
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.add_theme_constant_override("separation", 14)
	add_child(box)
	var l := Label.new()
	l.text = prompt
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(720, 0)
	l.add_theme_font_size_override("font_size", 22)
	box.add_child(l)
	for i in options.size():
		var b := Button.new()
		b.text = String(options[i])
		b.custom_minimum_size = Vector2(720, 48)
		b.pressed.connect(func(): chosen.emit(i))
		box.add_child(b)
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	queue_free()
