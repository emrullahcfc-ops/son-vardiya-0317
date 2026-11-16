extends CanvasLayer
## Nişangâh, etkileşim ipucu, altyazı, görev ve FPS göstergesi.

var _prompt: Label
var _subtitle: Label
var _quest: Label
var _fps: Label
var _sub_timer: SceneTreeTimer
var _player: Node


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var cross := Label.new()
	cross.text = "·"
	cross.add_theme_font_size_override("font_size", 28)
	cross.set_anchors_preset(Control.PRESET_CENTER)
	cross.grow_horizontal = Control.GROW_DIRECTION_BOTH
	cross.grow_vertical = Control.GROW_DIRECTION_BOTH
	root.add_child(cross)

	_prompt = _make_label(root, Control.PRESET_CENTER_BOTTOM, 22)
	_prompt.position.y -= 160
	_subtitle = _make_label(root, Control.PRESET_CENTER_BOTTOM, 20)
	_subtitle.position.y -= 80
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle.custom_minimum_size.x = 900
	_quest = _make_label(root, Control.PRESET_TOP_LEFT, 16)
	_quest.position = Vector2(16, 16)
	_fps = _make_label(root, Control.PRESET_TOP_RIGHT, 14)
	_fps.position = Vector2(-90, 8)

	AudioManager.subtitle.connect(_on_subtitle)
	QuestManager.quest_started.connect(func(_i): _refresh_quest())
	QuestManager.quest_completed.connect(func(_i): _refresh_quest())
	_refresh_quest()


func bind_player(p: Node) -> void:
	_player = p


func _make_label(parent: Control, preset: int, size: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(l)
	l.set_anchors_preset(preset)
	l.grow_horizontal = Control.GROW_DIRECTION_BOTH
	return l


func _process(_d: float) -> void:
	_fps.text = "%d FPS" % Engine.get_frames_per_second()
	var t: Node = _player.current_target if _player else null
	_prompt.text = ("[E] " + t.get_prompt()) if (t and t.has_method("get_prompt")) else ""
	_subtitle.add_theme_font_size_override("font_size", int(20 * float(GameManager.settings.get("subtitle_size", 1.0))))


func _on_subtitle(text: String, duration: float) -> void:
	_subtitle.text = text
	_sub_timer = get_tree().create_timer(duration)
	var mine := _sub_timer
	mine.timeout.connect(func(): if _sub_timer == mine: _subtitle.text = "")


func _refresh_quest() -> void:
	var lines: Array[String] = []
	for id in QuestManager.QUESTS:
		if QuestManager.is_active(id):
			lines.append("▸ " + QuestManager.QUESTS[id]["title"])
	_quest.text = "\n".join(lines)
