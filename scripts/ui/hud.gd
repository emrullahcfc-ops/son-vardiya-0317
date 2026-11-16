extends CanvasLayer
## Nişangâh, etkileşim ipucu, altyazı, görev ve FPS göstergesi.

var _prompt: Label
var _subtitle: Label
var _quest: Label
var _fps: Label
var _area: Label
var _stam: ColorRect
var _debug: Label
var _time: Label
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

	_area = _make_label(root, Control.PRESET_TOP_WIDE, 18)
	_area.position.y = 10
	_quest.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_quest.grow_horizontal = Control.GROW_DIRECTION_END
	_quest.position = Vector2(16, 48)
	_stam = ColorRect.new()
	_stam.color = Color(0.85, 0.85, 0.8, 0.7)
	root.add_child(_stam)
	_stam.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)  # kenara göre ofsetler
	_stam.offset_left = 20
	_stam.offset_right = 180
	_stam.offset_top = -30
	_stam.offset_bottom = -24
	_time = _make_label(root, Control.PRESET_TOP_RIGHT, 16)
	_time.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_time.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_time.offset_left = -200
	_time.offset_right = -14
	_time.offset_top = 30
	_time.offset_bottom = 54
	_debug = _make_label(root, Control.PRESET_BOTTOM_RIGHT, 14)
	_debug.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_debug.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_debug.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_debug.offset_right = -20
	_debug.offset_left = -20
	_debug.offset_bottom = -100
	_debug.offset_top = -100
	GameManager.area_entered.connect(_on_area)
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
	l.set_anchors_and_offsets_preset(preset)
	l.grow_horizontal = Control.GROW_DIRECTION_BOTH
	return l


func _process(_d: float) -> void:
	_fps.text = "%d FPS" % Engine.get_frames_per_second()
	_time.text = ("ZAMAN: " + GameManager.time_state) if GameManager.time_state != "2026" else ""
	var dbg := ""
	if GameManager.debug_ai:
		for e in get_tree().get_nodes_in_group("enemies"):
			if e.has_method("debug_text"):
				dbg += e.debug_text() + "
"
	_debug.text = dbg
	if _player and "stamina" in _player:
		_stam.offset_right = 20.0 + 160.0 * _player.stamina
		_stam.color = Color(0.9, 0.4, 0.3, 0.8) if _player.exhausted else Color(0.85, 0.85, 0.8, 0.7)
	var t: Node = _player.current_target if _player else null
	_prompt.text = ("[E] " + t.get_prompt()) if (t and t.has_method("get_prompt")) else ""
	_subtitle.add_theme_font_size_override("font_size", int(20 * float(GameManager.settings.get("subtitle_size", 1.0))))


func _on_area(_id: String, area_name: String, _counted: bool) -> void:
	_area.text = "%s  (%d/%d alan)" % [area_name, GameManager.visited_areas.size(), FactoryLayout.count_areas()]


func _on_subtitle(text: String, duration: float) -> void:
	_subtitle.text = text
	_sub_timer = get_tree().create_timer(duration)
	var mine := _sub_timer
	mine.timeout.connect(func(): if _sub_timer == mine: _subtitle.text = "")


func _refresh_quest() -> void:
	# Ekran dolmasın: yalnızca en yeni 4 aktif görev (eskiler bitmemiş kalsa bile).
	var lines: Array[String] = []
	var act := QuestManager.active_quests()
	for i in range(maxi(0, act.size() - 4), act.size()):
		lines.append("▸ " + QuestManager.QUESTS[act[i]]["title"])
	if act.size() > 4:
		lines.append("  (+%d eski görev)" % (act.size() - 4))
	_quest.text = "\n".join(lines)
