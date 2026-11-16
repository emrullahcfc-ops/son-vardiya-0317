class_name Chapter8
extends ChapterBase
## Bölüm 8: Son Sayım (final kaçışı). Rota: Mühürlü Alan → bodrum → üretim hatları → giriş holü/güvenlik kulübesi → turnike.
## Sayıcı final devriyesinde (daha hızlı, noktalarda 4 sn bekler: güvenli pencereler; dolaplar ve radyolar yardım eder).
## Kararlar: (1) güvenlik bilgisayarında ENERJİ: delilleri USB'ye kopyala (25 sn, terminalde kal) ya da elektriği hemen kes;
## (2) giriş holündeki personel defterinde: imzala / kapat / rapor bırak; (3) turnikede Sayıcı'nın sayımı: kabul / reddet.
## Tüm seçim ve delil bayrakları FinalInput.build() ile final çözümleyiciye aktarılır (Aşama 18).

const Y := 0.0
const TERMINAL_POS := Vector3(-9.1, 0.95, 14.9)
const LEDGER_POS := Vector3(4.2, 0.95, 14.8)
const TURNSTILE_POS := Vector3(-1.8, 1.1, 13.3)
const COPY_SECONDS := 25.0
const COPY_RANGE := 6.0
const DIM_FACTOR := 0.25

var _wait := true
var copying := false
var copy_progress := 0.0
var _choice_ui: ChoiceUI
var _hud: Label
var _sc: SayiciController

signal energy_decided(choice: String)
signal ledger_decided(choice: String)
signal finished(input: Dictionary)


func _ready() -> void:
	_build_props()
	_build_hud()
	GameManager.chapter_changed.connect(func(c): if c >= 8: _begin())
	if GameManager.current_chapter >= 8 and not GameManager.has_flag("ch8_done"):
		_begin()
	_restore()


func _controller() -> SayiciController:
	if _sc == null:
		var f := factory.find_children("*", "SayiciController", false, false)
		if not f.is_empty():
			_sc = f[0]
			_sc.player_died.connect(_on_died)
	return _sc


func _begin() -> void:
	if GameManager.has_flag("ch8_started"):
		return
	GameManager.set_flag("ch8_started")
	QuestManager.start_quest("ch8_escape")
	QuestManager.start_quest("ch8_energy")
	QuestManager.start_quest("ch8_ledger")
	QuestManager.start_quest("ch8_exit")
	AudioManager.say("Son sayım başladı. Çık: bodrum, üretim, güvenlik kulübesi, turnike. Sayıcı devriyede.", 6.0)


func _restore() -> void:
	if String(GameManager.flags.get("ch8_energy", "")) == "cut":
		_dim_lights()


# ------------------------------------------------------------------ karar 1: enerji
func energy_choice() -> String:
	return String(GameManager.flags.get("ch8_energy", ""))


## Güvenlik bilgisayarı: kopyala ya da elektriği kes. Karar bir kez verilir.
func use_terminal() -> String:
	if energy_choice() != "":
		AudioManager.say("Karar verildi: %s." % ("delillerin USB kopyası alındı" if energy_choice() == "backup" else "elektrik kesildi"), 3.0)
		return "decided"
	if copying:
		AudioManager.say("Kopyalama sürüyor: terminalin yakınında kal. (%d%%)" % int(copy_progress / COPY_SECONDS * 100.0), 2.5)
		return "copying"
	if _choice_ui != null:
		return "open"
	_choice_ui = ChoiceUI.new()
	_choice_ui.prompt = "Güvenlik bilgisayarı: Delillerin tamamı bu sistemde. Ne yapacaksın?"
	_choice_ui.options = ["Delilleri USB'ye kopyala (25 sn, terminalde kal — Sayıcı sesi duyar)", "Elektriği hemen kes (Sayıcı susar; ama yedek alınmaz)"]
	_choice_ui.chosen.connect(func(i): decide_energy("backup" if i == 0 else "cut"))
	factory.add_child(_choice_ui)
	return "ask"


func decide_energy(choice: String) -> String:
	if _choice_ui:
		_choice_ui.close()
		_choice_ui = null
	if energy_choice() != "" or copying:
		return "already"
	if choice == "backup":
		return start_backup()
	if choice == "cut":
		return cut_power()
	return "invalid"


func start_backup() -> String:
	if not InventoryManager.has_item("usb_drive"):
		AudioManager.say("USB bellek yok: kopyalayamazsın. Elektriği kesmeyi seç.", 4.0)
		return "no_usb"
	copying = true
	copy_progress = 0.0
	_checkpoint()   # yakalanırsan buraya dönersin, kopyalama baştan başlar
	AudioManager.say("Kopyalama başladı. Terminalin yakınında kal. Sayıcı bu sesi duydu...", 5.0)
	GameManager.make_noise(TERMINAL_POS, 14.0, "terminal")
	var sc := _controller()
	if sc:
		var far := Vector3(11, 0.05, 0)
		var sy := sc.spawn_at(far, SayiciController.ROUTE.duplicate())
		sy.patrol_speed = 2.0
		sy.waypoint_pause = 4.0
		sy.last_known = TERMINAL_POS
		sy.suspicion = 0.6
		sy._set_state(Sayici.State.SEARCH)
	return "copying"


func cut_power() -> String:
	GameManager.flags["ch8_energy"] = "cut"
	_dim_lights()
	var sc := _controller()
	if sc and sc.sayici and is_instance_valid(sc.sayici):
		sc.sayici.enabled = false
		sc.sayici.queue_free()
		sc.sayici = null
	AudioManager.play_sfx("door_slam")
	AudioManager.say("Elektrik kesildi. Işıklar söndü, Sayıcı sustu. Delillerin yedeği alınmadı.", 5.0)
	_complete("ch8_energy")
	energy_decided.emit("cut")
	_checkpoint()
	return "cut"


func _dim_lights() -> void:
	for l in get_tree().get_nodes_in_group("room_light"):
		l.light_energy = float(l.get_meta("base_energy", l.light_energy)) * DIM_FACTOR


func _process(delta: float) -> void:
	if factory == null or factory.player == null:
		return
	if copying:
		var d: float = factory.player.global_position.distance_to(Vector3(TERMINAL_POS.x, factory.player.global_position.y, TERMINAL_POS.z))
		if d <= COPY_RANGE:
			copy_progress += delta
			if copy_progress >= COPY_SECONDS:
				_backup_done()
	_update_hud()


func _backup_done() -> void:
	copying = false
	GameManager.flags["ch8_energy"] = "backup"
	GameManager.set_flag("ch8_backup")
	_complete("ch8_energy")
	AudioManager.play_sfx("beep")
	AudioManager.say("Kopyalama tamam: deliller USB'de. Şimdi çık!", 4.0)
	energy_decided.emit("backup")
	_checkpoint()


# ------------------------------------------------------------------ karar 2: personel defteri
func ledger_choice() -> String:
	return String(GameManager.flags.get("ch8_ledger", ""))


func use_ledger() -> String:
	if energy_choice() == "":
		AudioManager.say("Defter kilitli: önce güvenlik kulübesindeki sistemi çöz (kopyala ya da elektriği kes).", 4.0)
		return "no_energy"
	if ledger_choice() != "":
		AudioManager.say("Defterdeki kararın yazıldı.", 2.0)
		return "decided"
	if _choice_ui != null:
		return "open"
	_choice_ui = ChoiceUI.new()
	_choice_ui.prompt = "Personel defteri: Vardiya kaydı açık. On ikinci satır boş."
	_choice_ui.options = ["İmzala: vardiya defterini onayla", "Kapat: fabrikayı mühürle, tutanak tut", "Rapor bırak: delilleriyle rapor yaz"]
	_choice_ui.chosen.connect(func(i): decide_ledger(["sign", "close", "report"][i]))
	factory.add_child(_choice_ui)
	return "ask"


func decide_ledger(choice: String) -> String:
	if _choice_ui:
		_choice_ui.close()
		_choice_ui = null
	if energy_choice() == "":
		return "no_energy"
	if ledger_choice() != "":
		return "already"
	if not ["sign", "close", "report"].has(choice):
		return "invalid"
	GameManager.flags["ch8_ledger"] = choice
	_complete("ch8_ledger")
	var msgs := {
		"sign": "Defteri imzaladın. On ikinci satıra adın yazıldı.",
		"close": "Fabrikayı mühürledin. Tutanağa 'kapatıldı' yazdın.",
		"report": "Raporu bıraktın%s." % (" — deliller USB'de, rapor eksiksiz" if energy_choice() == "backup" else " — yedek olmadığı için rapor eksik kaldı"),
	}
	AudioManager.say(msgs[choice], 5.0)
	ledger_decided.emit(choice)
	_checkpoint()
	return choice


# ------------------------------------------------------------------ turnike ve son sayım
func use_turnstile() -> String:
	if GameManager.has_flag("ch8_done"):
		AudioManager.say("Çıktın.", 1.5)
		return "done"
	if energy_choice() == "" or ledger_choice() == "":
		AudioManager.say("Turnike kilitli: güvenlik kulübesindeki karar ve personel defteri tamamlanmalı.", 4.0)
		return "locked"
	if _choice_ui != null:
		return "open"
	AudioManager.play_sfx("chime")
	AudioManager.say("Sayıcı turnikenin ardında beliriyor: 'On bir... on iki: Murat Demir.'", 5.0)
	_choice_ui = ChoiceUI.new()
	_choice_ui.prompt = "Sayıcı: On bir isim yazılı, on ikincisi senin. Sayım tamam mı?"
	_choice_ui.options = ["Sayımı kabul et", "Yanlış sayım! Reddediyorum: ben on ikinci değilim"]
	_choice_ui.chosen.connect(func(i): decide_count("accept" if i == 0 else "reject"))
	factory.add_child(_choice_ui)
	return "ask"


func decide_count(choice: String) -> String:
	if _choice_ui:
		_choice_ui.close()
		_choice_ui = null
	if energy_choice() == "" or ledger_choice() == "":
		return "locked"
	if GameManager.has_flag("ch8_done"):
		return "already"
	if choice != "accept" and choice != "reject":
		return "invalid"
	GameManager.flags["ch8_count"] = choice
	finish()
	return choice


func finish() -> void:
	GameManager.set_flag("ch8_done")
	_complete("ch8_exit")
	_complete("ch8_escape")
	var input := FinalInput.build()
	GameManager.flags["final_input"] = input
	GameManager.set_flag("ending_pending")
	var sc := _controller()
	if sc and sc.sayici and is_instance_valid(sc.sayici):
		sc.sayici.enabled = false
	AudioManager.play_sfx("door_slam")
	AudioManager.say("Turnikeden geçtin. Dışarıda gün ağarıyor... (son çözümlenecek)", 5.0)
	_checkpoint()
	finished.emit(input)


func _on_died() -> void:
	copying = false
	copy_progress = 0.0
	if _choice_ui:
		_choice_ui.close()
		_choice_ui = null


# ------------------------------------------------------------------ arayüz ve sahne
func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 13
	_hud = Label.new()
	_hud.add_theme_font_size_override("font_size", 18)
	_hud.add_theme_color_override("font_outline_color", Color.BLACK)
	_hud.add_theme_constant_override("outline_size", 5)
	_hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(_hud)
	add_child(layer)
	_hud.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_hud.offset_top = -210
	_hud.offset_bottom = -170


func hud_text() -> String:
	if copying:
		var near: bool = factory.player != null and factory.player.global_position.distance_to(Vector3(TERMINAL_POS.x, factory.player.global_position.y, TERMINAL_POS.z)) <= COPY_RANGE
		return "KOPYALANIYOR %%%d%s" % [int(copy_progress / COPY_SECONDS * 100.0), "" if near else "  — duraklatıldı: terminale yaklaş!"]
	return ""


func _update_hud() -> void:
	_hud.text = hud_text()


func _build_props() -> void:
	# Güvenlik bilgisayarı (kulübe masası)
	_spot(factory, TERMINAL_POS, Vector3(0.3, 0.25, 0.2), Color(0.1, 0.25, 0.2), func(): return "Güvenlik bilgisayarı", func(_p): use_terminal())
	# Personel defteri (giriş holü masası)
	_spot(factory, LEDGER_POS, Vector3(0.35, 0.06, 0.25), Color(0.4, 0.15, 0.12), func(): return "Personel defteri", func(_p): use_ledger())
	# Turnike
	_spot(factory, TURNSTILE_POS, Vector3(0.3, 0.3, 0.9), Color(0.5, 0.5, 0.55), func(): return "Turnike", func(_p): use_turnstile())
