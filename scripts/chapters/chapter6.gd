class_name Chapter6
extends ChapterBase
## Bölüm 6: 03.17 Vardiyası (zaman bozulması). Üç bulmaca + final:
##  1) 2026'da B Yükleme deposunun doğu ucu betonla örülü; 2004'te açık → kartla 2004'e geç, depoya gir.
##  2) 2004 terminalinde 041117 kodunu gör → 2026'da vardiya dolabını aç → şalter kolu.
##  3) 2004'te bakım odasındaki panoya kolu tak → zaman bozulur: 11 işçi koridoru, uzayan koridor kaçışı (Sayıcı),
##     koridor sonunda Yusuf'un telefonu (iki seçenek, kaydedilir, geçmiş değişmez), şalteri indir → 2026'ya dönüş.

const CODE := "041117"
const X0 := 60.0                  # cep koridorun başlangıç x'i (fabrika dışı)
const Z0 := -30.0
const CORRIDOR_END := 113.0       # x0'a göre
const LOOP_LEN := 36.0            # uzama: periyodik koridor (ışık aralığı 12 m ve işçi aralığı 3 m'nin katı)
const LOOP_AT := 45.0
const MAX_LOOPS := 3
const END_AT := 104.0
const CHASER_SPEED := 2.8         # yürümeden (3,0) yavaş: durmadan ilerleyen oyuncu yakalanmaz
const MAINT_RETURN := Vector3(0, 0.15, -8)

var chase_wait := true            # solma/zamanlayıcı (testte false)
var corridor_active := false
var loops := 0
var end_reached := false
var choice_made := false
var _npcs: Array[Node3D] = []
var _corridor_nodes: Array[Node] = []
var _choice_ui: ChoiceUI
var _sc: SayiciController
var _mach_layer := false

signal choice_recorded(choice: String)
signal corridor_started
signal chapter_finished


func _ready() -> void:
	_build_props()
	_build_corridor()
	GameManager.chapter_changed.connect(func(c): if c >= 6: _begin())
	GameManager.time_state_changed.connect(_on_time_state)
	if GameManager.current_chapter >= 6 and not GameManager.has_flag("ch6_done"):
		_begin()
	_restore()


func _controller() -> SayiciController:
	if _sc == null:
		var f := factory.find_children("*", "SayiciController", false, false)
		if not f.is_empty():
			_sc = f[0]
			_sc.player_died.connect(_on_died)
	return _sc


func _tl() -> TimeLayers:
	return factory.get("time_layers")


func _begin() -> void:
	if GameManager.has_flag("ch6_started"):
		return
	GameManager.set_flag("ch6_started")
	QuestManager.start_quest("ch6_alcove")
	QuestManager.start_quest("ch6_locker")
	QuestManager.start_quest("ch6_breaker")
	AudioManager.play_sfx("chime")
	AudioManager.say("[Anons] 03.17. Vardiya başladı. Zaman kayıyor... B Hattı'ndaki kart okuyucu çalışıyor.", 6.0)


func _restore() -> void:
	if GameManager.has_flag("ch6_locker_open") and not InventoryManager.has_item("breaker_handle") and not GameManager.has_flag("ch6_breaker_used"):
		_spawn_handle()


# ------------------------------------------------------------------ 2004 atmosferi
func _on_time_state(state: String) -> void:
	var ch2 := factory.find_children("*", "Chapter2", false, false)
	if not ch2.is_empty():
		for l in ["A", "B", "C"]:
			var on: bool = state == "2004" or GameManager.has_flag("ch2_line_" + l)
			ch2[0]._set_machine(l, on)   # 2004'te üç makine de çalışır
	if state == "2004" and not AudioManager.has_layer("machine"):
		AudioManager.start_layer("machine", -10.0)
		_mach_layer = true
	elif state == "2026" and _mach_layer and not GameManager.has_flag("ch5_fans"):
		AudioManager.stop_layer("machine")
		_mach_layer = false


# ------------------------------------------------------------------ bulmaca 1–2: beton, terminal, dolap
func read_terminal() -> void:
	GameManager.set_flag("ch6_code_seen")
	_complete("ch6_alcove")
	AudioManager.say("VARDİYA TERMİNALİ — Depo kapanış kayıt no: 04-11-17 → %s. Mühürleme onaylandı: Y. Demir." % CODE, 12.0)


func inspect_concrete() -> void:
	AudioManager.say("Beton duvar: Yükleme deposunun doğu ucu örülmüş. Rapor: 'Depo 2004'te kapatıldı.' Taze beton değil; yıllar önceki bir iş.", 6.0)
	if GameManager.has_flag("ch5_done"):
		AudioManager.say("Beton duvar: depo 2004'te kapatılmış. 2004'te burası açıktı — kart okuyucuyla o zamana geçebilirsin.", 6.0)


func _on_locker_open() -> void:
	_complete("ch6_locker")
	AudioManager.say("Dolap açıldı. İçinde bir şalter kolu var.", 4.0)
	_spawn_handle()


func _spawn_handle() -> void:
	var sp: CallbackInteractable = _spot(factory, Vector3(15.3, 1.0, 1.0) + Vector3(-0.5, 0.2, 0), Vector3(0.12, 0.05, 0.4), Color(0.7, 0.7, 0.75), func(): return "Al: şalter kolu", func(_p): pass)
	_register_2026(sp)
	sp.action_fn = func(_p):
		if InventoryManager.add_item("breaker_handle"):
			GameManager.set_flag("pickup_ch6_handle")
			AudioManager.say("Şalter kolunu aldın. Bakım odasındaki pano 2004'te çalışıyor.", 4.0)
			sp.queue_free()


func _register_2026(n: Node) -> void:
	var tl := _tl()
	if tl:
		tl.register(n, "2026")
		n.visible = GameManager.time_state == "2026"
		if n is CollisionObject3D and GameManager.time_state != "2026":
			(n as CollisionObject3D).set_meta("tl_layer", (n as CollisionObject3D).collision_layer)
			(n as CollisionObject3D).collision_layer = 0


func _register_2004(n: Node) -> void:
	var tl := _tl()
	if tl:
		tl.register(n, "2004")
		n.visible = GameManager.time_state == "2004"
		if n is CollisionObject3D and GameManager.time_state != "2004":
			(n as CollisionObject3D).set_meta("tl_layer", (n as CollisionObject3D).collision_layer)
			(n as CollisionObject3D).collision_layer = 0


# ------------------------------------------------------------------ bulmaca 3: şalter panosu → koridor
func use_breaker_panel() -> String:
	if GameManager.has_flag("ch6_done"):
		AudioManager.say("Pano sönük. Vardiya bitti.", 2.0)
		return "done"
	if corridor_active:
		return "active"
	if not InventoryManager.has_item("breaker_handle"):
		AudioManager.say("Panoda kol yuvası boş. Bir şalter kolu lazım (2026'daki vardiya dolabı).", 4.0)
		return "no_handle"
	GameManager.set_flag("ch6_breaker_used")
	_complete("ch6_breaker")
	QuestManager.start_quest("ch6_corridor")
	AudioManager.play_sfx("click")
	AudioManager.say("Kolu taktın. Pano kıpırdadı... zaman bozuluyor!", 4.0)
	start_corridor()
	return "ok"


func start_corridor() -> void:
	var sc := _controller()
	if sc == null or corridor_active:
		return
	corridor_active = true
	loops = 0
	end_reached = false
	_checkpoint()   # yakalanırsan buraya dönersin; kolu yeniden takarak tekrar denersin
	factory.player.controls_enabled = false
	if chase_wait:
		_fade(1.0, 0.5)
		await get_tree().create_timer(0.6).timeout
	GameManager.set_time_state("2004")
	var tl := _tl()
	tl.apply("2004")
	factory.player.global_position = Vector3(X0 + 16.0, 0.15, Z0)
	factory.player.rotation = Vector3(0, -PI / 2.0, 0)   # +x'e bakar
	factory.player.velocity = Vector3.ZERO
	factory.rebake_navigation()   # koridor yol ağına girer (ekran karanlıkken)
	var sy := sc.spawn_at(Vector3(X0 + 2.0, 0.05, Z0), [] as Array[Vector3])
	sy.chase_speed = CHASER_SPEED
	sy.last_known = factory.player.global_position
	sy.suspicion = 1.0
	sy._set_state(Sayici.State.CHASE)
	AudioManager.say("Koridor... on bir işçi iki yanda duruyor. Arkanda Sayıcı. Durma!", 5.0)
	if chase_wait:
		_fade(0.0, 0.6)
	factory.player.controls_enabled = true
	corridor_started.emit()


func _process(delta: float) -> void:
	if not corridor_active or factory == null or factory.player == null:
		return
	var p: Node3D = factory.player
	for n in _npcs:   # işçiler oyuncuya döner
		if is_instance_valid(n) and n.global_position.distance_to(p.global_position) < 4.5:
			var d := p.global_position - n.global_position
			n.rotation.y = lerp_angle(n.rotation.y, atan2(-d.x, -d.z), clampf(4.0 * delta, 0.0, 1.0))
	tick_corridor()


## Uzayan koridor: eşiği aşan oyuncu (ve Sayıcı) bir periyot geriye alınır; 3 uzamadan sonra sonuna gidilebilir.
func tick_corridor() -> void:
	var p: Node3D = factory.player
	var sc := _controller()
	if loops < MAX_LOOPS and p.global_position.x >= X0 + LOOP_AT:
		loops += 1
		p.global_position.x -= LOOP_LEN
		if sc and sc.sayici and is_instance_valid(sc.sayici):
			sc.sayici.global_position.x -= LOOP_LEN
		AudioManager.say("Koridor uzuyor... (%d/%d)" % [loops, MAX_LOOPS], 2.5)
		AudioManager.play_sfx("whisper", p.global_position)
	elif loops >= MAX_LOOPS and not end_reached and p.global_position.x >= X0 + END_AT:
		arrive_end()


func arrive_end() -> void:
	end_reached = true
	var sc := _controller()
	if sc and sc.sayici and is_instance_valid(sc.sayici):
		sc.sayici.enabled = false   # zaman durur
		sc.sayici.velocity = Vector3.ZERO
	AudioManager.play_sfx("phone")
	AudioManager.say("Telefon çalıyor. Koridorun sonunda, masanın üstünde.", 4.0)
	ask_yusuf()


## Yusuf telefon diyaloğu: iki seçenek, bir kez; yalnızca kendi bayraklarını yazar (geçmiş değişmez).
func ask_yusuf() -> void:
	if choice_made or _choice_ui != null:
		return
	_choice_ui = ChoiceUI.new()
	_choice_ui.prompt = "Yusuf (telefon): Murat? Oğlum... O gece kapıyı ben mühürledim. On bir kişi içerideydi. Beni duyuyor musun?"
	_choice_ui.options = ["Baba, hepsini anlatacağım. Herkes gerçeği bilecek.", "Seni anlıyorum baba. Bunu kimseye söylemeyeceğim."]
	_choice_ui.chosen.connect(func(i): choose("expose" if i == 0 else "protect"))
	factory.add_child(_choice_ui)


func choose(choice: String) -> String:
	if choice_made:
		AudioManager.say("Bu cevabı zaten verdin. Geçmiş değişmez.", 3.0)
		return "already"
	if choice != "expose" and choice != "protect":
		return "invalid"
	choice_made = true
	GameManager.flags["ch6_choice"] = choice
	GameManager.flags["final_choice"] = choice   # finale (Aşama 18) taşınır
	if _choice_ui:
		_choice_ui.close()
		_choice_ui = null
	if choice == "expose":
		AudioManager.say("Yusuf: ...Biliyorum, hak ediyorum. Şalteri indir, oğlum. Bitir bunu.", 5.0)
	else:
		AudioManager.say("Yusuf: Teşekkür ederim, Murat. Ama şalteri sen indir; ben yapamam.", 5.0)
	choice_recorded.emit(choice)
	return choice


func pull_switch() -> String:
	if not corridor_active or not end_reached:
		AudioManager.say("Şalter henüz erişilemiyor. Koridorun sonuna ulaş.", 2.5)
		return "not_ready"
	if not choice_made:
		AudioManager.say("Telefon çalıyor. Önce Yusuf'a cevap ver.", 2.5)
		ask_yusuf()
		return "no_choice"
	finish_chapter()
	return "ok"


func finish_chapter() -> void:
	corridor_active = false
	GameManager.set_flag("ch6_done")
	_complete("ch6_corridor")
	var sc := _controller()
	if sc and sc.sayici and is_instance_valid(sc.sayici):
		sc.sayici.queue_free()
		sc.sayici = null
	AudioManager.play_sfx("door_slam")
	AudioManager.say("Şalter indi. Işıklar söndü... 03.17 bitti.", 4.0)
	if chase_wait:
		_fade(1.0, 0.5)
		await get_tree().create_timer(0.6).timeout
	factory.player.global_position = MAINT_RETURN
	factory.player.velocity = Vector3.ZERO
	var tl := _tl()
	var inst := tl.instant
	tl.instant = true
	tl._cool_until = 0.0
	await tl.switch_to("2026")
	tl.instant = inst
	if chase_wait:
		_fade(0.0, 0.8)
	GameManager.set_chapter(7)
	_checkpoint()
	chapter_finished.emit()


func _on_died() -> void:
	corridor_active = false
	end_reached = false
	loops = 0
	if _choice_ui:
		_choice_ui.close()
		_choice_ui = null


# ------------------------------------------------------------------ sahne
func _build_props() -> void:
	# 2026: Yükleme deposunun doğu ucunu kapatan beton duvar; üstünde okunabilir not alanı
	var wall := StaticBody3D.new()
	wall.collision_layer = 1
	wall.position = Vector3(13.65, 1.8, 12.0)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.5, 3.6, 7.6)
	mi.mesh = bm
	mi.material_override = _mat(Color(0.5, 0.5, 0.48))
	wall.add_child(mi)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = bm.size
	cs.shape = bs
	wall.add_child(cs)
	wall.name = "Concrete2026"
	factory.add_child(wall)
	_register_2026(wall)
	var note := _spot(factory, Vector3(13.3, 1.4, 12.0), Vector3(0.1, 0.5, 0.8), Color(0.75, 0.72, 0.6), func(): return "İncele: Beton duvar", func(_p): inspect_concrete())
	_register_2026(note)
	# 2004: açık depo, terminal
	var desk := _box(factory, Vector3(15.2, 0.45, 12.0), Vector3(0.9, 0.9, 2.2), Color(0.35, 0.28, 0.2))
	desk.name = "Depo2004Masa"
	_register_2004(desk)
	var term := _spot(factory, Vector3(14.95, 1.15, 12.0), Vector3(0.12, 0.55, 0.8), Color(0.1, 0.3, 0.18), func(): return "Vardiya terminali", func(_p): read_terminal())
	_register_2004(term)
	# 2026: vardiya dolabı (6 haneli kod) — lineC doğu duvarı
	var kp := Keypad.new()
	kp.position = Vector3(15.3, 1.0, 1.0)
	kp.code = CODE
	kp.power_flag = ""
	kp.unlock_flag = "ch6_locker_open"
	kp.quest_id = "ch6_locker"
	kp.title_text = "Vardiya dolabı — 6 haneli kod"
	kp.ok_text = "Dolap açıldı."
	var kmi := MeshInstance3D.new()
	var kbm := BoxMesh.new()
	kbm.size = Vector3(0.5, 2.0, 1.0)
	kmi.mesh = kbm
	kmi.material_override = _mat(Color(0.3, 0.33, 0.35))
	kp.add_child(kmi)
	var kcs := CollisionShape3D.new()
	var kbs := BoxShape3D.new()
	kbs.size = Vector3(0.6, 2.0, 1.1)
	kcs.shape = kbs
	kp.add_child(kcs)
	factory.add_child(kp)
	kp.unlocked.connect(_on_locker_open)
	_register_2026(kp)
	var label := _spot(factory, Vector3(15.0, 1.9, 1.0), Vector3(0.05, 0.3, 0.6), Color(0.8, 0.8, 0.7), func(): return "Oku: dolap etiketi", func(_p): AudioManager.say("Dolap etiketi: 'Şifre = depo kapanış kayıt numarası (altı hane). Kayıt terminalinde.'", 6.0))
	_register_2026(label)
	# 2004: bakım odası ana şalter panosu
	var panel := _spot(factory, Vector3(0, 1.4, -11.55), Vector3(1.2, 1.0, 0.1), Color(0.35, 0.35, 0.38), func(): return "Ana şalter panosu", func(_p): use_breaker_panel())
	_register_2004(panel)


func _build_corridor() -> void:
	var len := 116.0
	var cx := X0 + len * 0.5 - 2.0
	for spec in [
		["Zemin", Vector3(cx, -0.15, Z0), Vector3(len, 0.3, 3.4)],
		["Tavan", Vector3(cx, 3.15, Z0), Vector3(len, 0.3, 3.4)],
		["DuvarSol", Vector3(cx, 1.5, Z0 - 1.7), Vector3(len, 3.3, 0.3)],
		["DuvarSag", Vector3(cx, 1.5, Z0 + 1.7), Vector3(len, 3.3, 0.3)],
		["Bas", Vector3(X0 - 2.2, 1.5, Z0), Vector3(0.3, 3.3, 3.4)],
		["Son", Vector3(X0 + CORRIDOR_END + 0.7, 1.5, Z0), Vector3(0.3, 3.3, 3.4)],
	]:
		var b := _box(factory, spec[1], spec[2], Color(0.4, 0.34, 0.24))
		b.name = "Koridor" + spec[0]
		_register_2004(b)
		_corridor_nodes.append(b)
	var x := X0 + 6.0
	while x < X0 + CORRIDOR_END:
		var l := OmniLight3D.new()
		l.position = Vector3(x, 2.8, Z0)
		l.light_color = Color(1.0, 0.85, 0.55)
		l.light_energy = 1.6
		l.omni_range = 11.0
		factory.add_child(l)
		_register_2004(l)
		x += 12.0
	# 11 işçi: iki yanda (6 sol, 5 sağ), ilk 33 metrede
	var tl := _tl()
	for i in 11:
		var side := -1.0 if i % 2 == 0 else 1.0
		var npc := tl.spawn_npc("kor%d" % (i + 1), Vector3(X0 + 8.0 + i * 3.0, 0, Z0 + side * 1.1), "2004", PI if side < 0 else 0.0)
		_npcs.append(npc)
		if GameManager.time_state != "2004":
			npc.visible = false
	# koridor sonu: telefon masası ve şalter
	var phone_desk := _box(factory, Vector3(X0 + CORRIDOR_END - 1.5, 0.45, Z0 - 0.9), Vector3(1.2, 0.9, 0.8), Color(0.3, 0.25, 0.2))
	_register_2004(phone_desk)
	var phone := _spot(factory, Vector3(X0 + CORRIDOR_END - 1.5, 0.95, Z0 - 0.9), Vector3(0.3, 0.15, 0.25), Color(0.1, 0.1, 0.1), func(): return "Telefonu aç", func(_p): ask_yusuf())
	_register_2004(phone)
	var sw := _spot(factory, Vector3(X0 + CORRIDOR_END + 0.4, 1.4, Z0 + 0.6), Vector3(0.1, 0.8, 0.5), Color(0.7, 0.2, 0.15), func(): return "Şalteri indir", func(_p): pull_switch())
	_register_2004(sw)
