class_name Chapter5
extends ChapterBase
## Bölüm 5: Kimyasal Bölüm (bodrum). Gaz ölçer, filtre kaynağı, gazlı alanlar (Area3D), fan sırası F2 → F1 → F3,
## Sayıcı kovalamacası (buhar perdesi + saklanma rotası), Yusuf'un elektronik onayı ve interkom kadın sesi.
##
## Kaynak dengesi: bir filtre 30 sn korur; ana rota ~60 sn gazda geçer (≈2 filtre). Dünyada 7 filtre vardır
## (yedek dolap 5, boru 1, fan odası 1) = iki tam deneme + pay. Hafif gaz (boru) filtresiz de bir geçişte öldürmez;
## filtre bitince net uyarı verilir; gaz öldürürse kontrol noktasına dönülür (kontrol noktası envanteri geri yükler).

const Y := -4.0
const FILTER_SECONDS := 30.0
const WARN_LOW := 8.0
const RECOVER := 0.08                 # gazsız ortamda saniyede toparlanma
const BURST := 0.25                   # yanlış fan sırasında ani gaz
const ROUTE_GAS_SECONDS := 60.0       # ana rotanın gazda geçen tahmini süresi
const FAN_ORDER := [2, 1, 3]
const LOCKER_STOCK := 5
const CARRY_MAX := 3
const DENSITY := {"b_pipe": 0.04, "b_fan": 0.06, "b_pump": 0.07, "b_ctrl": 0.09, "b_tunnel": 0.12}
const CLEARED_BY_FANS := ["b_pump", "b_ctrl"]
const BASEMENT_ROUTE: Array[Vector3] = [Vector3(11, Y, -8), Vector3(0, Y, -8), Vector3(-11, Y, -8)]

var exposure := 0.0
var chase_enabled := true
var chase_active := false
var steam_on := false
var steam_duration := 15.0
var _wait := true
var deaths := 0
var approval_lines: Array = []
var _in: Dictionary = {}
var _dead := false
var _gas_label: Label
var _fans: Array[MeshInstance3D] = []
var _steam_body: StaticBody3D
var _steam_fx: CPUParticles3D
var _sc: SayiciController

signal collapsed
signal chase_succeeded


func _ready() -> void:
	_build_props()
	_build_hud()
	GameManager.area_entered.connect(_on_area)
	for r in ["b_pipe", "b_fan", "b_pump", "b_ctrl", "b_tunnel"]:
		_make_zone(r)
	_refresh_fans()


func _controller() -> SayiciController:
	if _sc == null:
		var found := factory.find_children("*", "SayiciController", false, false)
		if not found.is_empty():
			_sc = found[0]
			_sc.player_died.connect(_on_player_died)
	return _sc


func active() -> bool:
	return GameManager.current_chapter >= 5 and GameManager.has_flag("ch4_done") and not GameManager.has_flag("ch5_done")


# ------------------------------------------------------------------ kaynaklar (kayıtta saklanır)
func filters() -> int:
	return int(GameManager.flags.get("ch5_filters", 0))


func filter_left() -> float:
	return float(GameManager.flags.get("ch5_filter_left", 0.0))


func locker_stock() -> int:
	return int(GameManager.flags.get("ch5_locker", LOCKER_STOCK))


func _set_filters(n: int) -> void:
	GameManager.flags["ch5_filters"] = n


func _set_filter_left(t: float) -> void:
	GameManager.flags["ch5_filter_left"] = t


func density_of(room_id: String) -> float:
	if room_id in CLEARED_BY_FANS and GameManager.has_flag("ch5_fans"):
		return 0.0
	return float(DENSITY.get(room_id, 0.0))


func density_here() -> float:
	var d := 0.0
	for r in _in:
		if _in[r]:
			d = maxf(d, density_of(r))
	return d


## Gaz modeli: gazdayken filtre otomatik takılır ve süre harcar; filtre yoksa maruziyet artar; gazsızda toparlanır.
func tick(delta: float, density: float) -> void:
	if _dead:
		return
	if density <= 0.0:
		exposure = maxf(0.0, exposure - RECOVER * delta)
		return
	if filter_left() <= 0.0 and filters() > 0:
		_set_filters(filters() - 1)
		_set_filter_left(FILTER_SECONDS)
		AudioManager.say("Yeni filtre takıldı. Kalan yedek: %d" % filters(), 2.5)
	if filter_left() > 0.0:
		var before := filter_left()
		_set_filter_left(maxf(0.0, before - delta))
		if before > WARN_LOW and filter_left() <= WARN_LOW and filters() == 0:
			AudioManager.say("Filtre bitmek üzere! Yedek filtren yok — gazdan çık.", 3.0)
		if filter_left() <= 0.0 and filters() == 0:
			AudioManager.say("Filtre bitti! Gazdan çık ya da yedek filtre bul (yedek dolap, kutular).", 4.0)
	else:
		exposure = minf(1.0, exposure + density * delta)
		if exposure >= 1.0:
			collapse()


func _process(delta: float) -> void:
	if factory == null or factory.player == null:
		return
	for f in _fans:
		if f.visible and GameManager.has_flag("ch5_fan_on_" + f.name):
			f.rotation.y += delta * 8.0
	if active():
		tick(delta, density_here())
	_update_hud()


func collapse() -> void:
	if _dead:
		return
	_dead = true
	deaths += 1
	GameManager.add_death()
	factory.player.controls_enabled = false
	AudioManager.say("Gaz seni yere serdi. Kontrol noktasına dönüyorsun.", 3.0)
	collapsed.emit()
	_fade(1.0, 1.0)
	if _wait:
		await get_tree().create_timer(2.0).timeout
		if not is_inside_tree():
			return
	_reset_chase()
	factory.respawn_player()
	exposure = 0.0
	_in.clear()
	_fade(0.0, 0.8)
	_dead = false


# ------------------------------------------------------------------ alan olayları
func _on_area(id: String, _n: String, _c: bool) -> void:
	if id in ["b_stairD", "b_land"] and GameManager.current_chapter >= 5 and not GameManager.has_flag("ch5_started"):
		GameManager.set_flag("ch5_started")
		QuestManager.start_quest("ch5_fans")
		QuestManager.start_quest("ch5_seal")
		AudioManager.say("Bodrum. Havada gaz kokusu var. Gaz ölçeri ve yedek filtreleri al.", 5.0)
		_checkpoint()
	if id == "b_pump" and GameManager.has_flag("ch5_fans") and not GameManager.has_flag("ch5_chase_done") and not chase_active and chase_enabled:
		start_chase()


func _make_zone(room_id: String) -> void:
	var r := FactoryLayout.room(room_id)
	if r.is_empty():
		return
	var b: Array = r["r"]
	var a := Area3D.new()
	a.collision_layer = 0
	a.collision_mask = 2
	a.position = FactoryLayout.room_center(r) + Vector3(0, 1.8, 0)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(b[2] - b[0] - 0.4, 3.4, b[3] - b[1] - 0.4)
	cs.shape = bs
	a.add_child(cs)
	a.body_entered.connect(func(body: Node3D): if body.is_in_group("player"): _in[room_id] = true)
	a.body_exited.connect(func(body: Node3D): if body.is_in_group("player"): _in[room_id] = false)
	factory.add_child(a)


# ------------------------------------------------------------------ filtre ve gaz ölçer
func take_from_locker() -> int:
	var stock := locker_stock()
	var can := mini(stock, CARRY_MAX - filters())
	if stock <= 0:
		AudioManager.say("Yedek dolap boş. Kutularda filtre aramalısın.", 3.0)
		return 0
	if can <= 0:
		AudioManager.say("Zaten en fazla %d filtre taşıyorsun." % CARRY_MAX, 2.5)
		return 0
	_set_filters(filters() + can)
	GameManager.flags["ch5_locker"] = stock - can
	AudioManager.play_sfx("click")
	AudioManager.say("%d filtre aldın. Elindeki: %d. Dolapta kalan: %d." % [can, filters(), stock - can], 4.0)
	return can


func take_filter(id: String) -> bool:
	if GameManager.has_flag("ch5_filter_" + id):
		AudioManager.say("Burada başka filtre yok.", 1.5)
		return false
	GameManager.set_flag("ch5_filter_" + id)
	_set_filters(filters() + 1)
	AudioManager.play_sfx("click")
	AudioManager.say("Bir filtre buldun. Elindeki: %d" % filters(), 3.0)
	return true


# ------------------------------------------------------------------ fanlar (F2 → F1 → F3)
func fan_sequence() -> Array:
	# JSON kaydından sayılar ondalık gelir; Array.has/== için tam sayıya çevrilir.
	var v: Variant = GameManager.flags.get("ch5_fan_seq", [])
	var out: Array = []
	if v is Array:
		for x in v:
			out.append(int(x))
	return out


func press_fan(n: int) -> String:
	if GameManager.has_flag("ch5_fans"):
		AudioManager.say("Fanlar çalışıyor. Havalandırma tamam.", 2.0)
		return "done"
	var seq := fan_sequence().duplicate()
	if seq.has(n):
		AudioManager.say("Fan %d zaten çalışıyor." % n, 1.5)
		return "already"
	if n != FAN_ORDER[seq.size()]:
		_reset_fans()
		_burst()
		return "wrong"
	seq.append(n)
	GameManager.flags["ch5_fan_seq"] = seq
	GameManager.set_flag("ch5_fan_on_Fan%d" % n)
	AudioManager.play_sfx("click")
	if seq.size() == FAN_ORDER.size():
		_fans_done()
		return "ok_done"
	AudioManager.say("Fan %d çalıştı (%d/3)." % [n, seq.size()], 2.0)
	return "ok"


func _reset_fans() -> void:
	GameManager.flags["ch5_fan_seq"] = []
	for i in [1, 2, 3]:
		GameManager.flags.erase("ch5_fan_on_Fan%d" % i)


## Yanlış sırada ani gaz: filtre takılıysa filtre süresi yer, yoksa maruziyet artar (öldürmez; toparlanılır).
func _burst() -> void:
	AudioManager.play_sfx("error")
	if filter_left() > 0.0:
		_set_filter_left(maxf(0.0, filter_left() - 5.0))
	else:
		exposure = minf(0.9, exposure + BURST)
	AudioManager.say("Basınç dengesizliği! Sistem sıfırlandı, gaz yükseldi. Kılavuzdaki fan sırasını kontrol et.", 5.0)


func _fans_done() -> void:
	GameManager.set_flag("ch5_fans")
	_complete("ch5_fans")
	AudioManager.start_layer("machine", -14.0)
	AudioManager.play_sfx("chime")
	AudioManager.say("Üç fan sırayla çalıştı. Pompa ve kontrol odasındaki gaz çekiliyor.", 5.0)
	_checkpoint()


func _refresh_fans() -> void:
	pass


# ------------------------------------------------------------------ Sayıcı kovalamacası
func start_chase() -> void:
	var sc := _controller()
	if sc == null or chase_active or factory.player == null:
		return
	chase_active = true
	var sy := sc.spawn_at(Vector3(18, Y + 0.05, -8), BASEMENT_ROUTE.duplicate())
	sy.last_known = factory.player.global_position
	sy.suspicion = 1.0
	sy._set_state(Sayici.State.CHASE)
	sy.state_changed.connect(_on_sayici_state)
	AudioManager.say("Merdivenden ağır adımlar iniyor. Sayıcı seni duydu!", 4.0)
	AudioManager.play_sfx("thump", sy.global_position)


func _on_sayici_state(s: int) -> void:
	if chase_active and s == Sayici.State.PATROL:
		_chase_success()


func _chase_success() -> void:
	chase_active = false
	GameManager.set_flag("ch5_chase_done")
	var sc := _controller()
	if sc and sc.sayici and is_instance_valid(sc.sayici):
		var sy: Sayici = sc.sayici
		sy.enabled = false
		var tw := create_tween()
		tw.tween_interval(2.0)
		tw.tween_callback(func(): if is_instance_valid(sy): sy.queue_free())
		sc.sayici = null
	AudioManager.say("Sayıcı seni kaybetti ve geri çekildi. Kontrol panosuna gidebilirsin.", 4.0)
	_checkpoint()
	chase_succeeded.emit()


func _reset_chase() -> void:
	chase_active = false
	if steam_on:
		_steam(false)


func _on_player_died() -> void:
	_reset_chase()
	exposure = 0.0


func use_valve() -> void:
	if steam_on:
		AudioManager.say("Buhar zaten akıyor.", 1.5)
		return
	_steam(true)
	AudioManager.play_sfx("steam", _steam_body.global_position)
	AudioManager.say("Buhar vanası açıldı: kapıda buhar perdesi var. Perdenin ardında görülmezsin.", 4.0)
	get_tree().create_timer(steam_duration).timeout.connect(func(): _steam(false))


func _steam(on: bool) -> void:
	steam_on = on
	_steam_body.collision_layer = 16 if on else 0   # yalnızca görüşü keser, hareketi engellemez
	_steam_fx.emitting = on


# ------------------------------------------------------------------ mühür panosu
func use_panel() -> String:
	if GameManager.has_flag("ch5_done"):
		AudioManager.say("Mühür kaydı zaten onaylı.", 2.0)
		return "done"
	if not GameManager.has_flag("ch5_fans"):
		AudioManager.say("Panel gaz basıncı yüzünden yanıt vermiyor. Havalandırmayı çalıştır.", 3.0)
		return "no_fans"
	if chase_enabled and not GameManager.has_flag("ch5_chase_done"):
		AudioManager.say("Panel yanıt vermiyor. Önce Sayıcı'dan kurtulmalısın.", 3.0)
		return "no_chase"
	if not InventoryManager.has_item("yusuf_card"):
		AudioManager.say("Panel bir personel kartı istiyor: Yusuf'un kartı.", 3.0)
		return "no_card"
	approval_lines = [
		"Panel: Kimlik okundu — Yusuf Demir. Mühür kaydı onaylandı.",
		"Yusuf (kayıt): Ben, Y. Demir, bakım iptalini ve alanın mühürlenmesini onaylıyorum. 03.17.",
		"[İnterkom — kadın sesi] Murat... bu babanın sesi. On bir kişi içeride. Sen on ikincisin.",
	]
	GameManager.set_flag("ch5_done")
	_complete("ch5_seal")
	_complete("ch4_basement")
	AudioManager.play_sfx("beep")
	for l in approval_lines:
		AudioManager.say(l, 5.0)
	GameManager.set_chapter(6)
	_checkpoint()
	return "ok"


# ------------------------------------------------------------------ arayüz
func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 12
	_gas_label = Label.new()
	_gas_label.add_theme_font_size_override("font_size", 16)
	_gas_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_gas_label.add_theme_constant_override("outline_size", 5)
	_gas_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(_gas_label)
	add_child(layer)
	_gas_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_gas_label.offset_top = -170
	_gas_label.offset_bottom = -130


func hud_text() -> String:
	if not active() or not (density_here() > 0.0 or filter_left() > 0.0 or exposure > 0.02 or InventoryManager.has_item("gas_meter")):
		return ""
	var t := "Filtre: %d" % filters()
	if filter_left() > 0.0:
		t += "  (takılı: %d sn)" % int(ceil(filter_left()))
	if InventoryManager.has_item("gas_meter"):
		var bars := int(round(density_here() / 0.12 * 6.0))
		t += "   Gaz: " + "▮".repeat(bars) + "▯".repeat(6 - bars)
	if exposure > 0.02:
		t += "   ZEHİRLENME %%%d" % int(exposure * 100.0)
	if density_here() > 0.0 and filter_left() <= 0.0 and filters() == 0:
		t += "\nFİLTRE YOK — GAZDAN ÇIK!"
	return t


func _update_hud() -> void:
	_gas_label.text = hud_text()
	var danger := exposure > 0.5 or (density_here() > 0.0 and filter_left() <= 0.0 and filters() == 0)
	_gas_label.add_theme_color_override("font_color", Color(1, 0.4, 0.3) if danger else Color(0.9, 0.95, 0.8))


# ------------------------------------------------------------------ sahne
func _filter_spot(pos: Vector3, id: String) -> void:
	_box(factory, pos - Vector3(0, 0.45, 0), Vector3(0.8, 0.9, 0.8), Color(0.35, 0.3, 0.22))
	_spot(factory, pos, Vector3(0.3, 0.15, 0.2), Color(0.6, 0.75, 0.6), func(): return "Al: filtre", func(_p): take_filter(id))


func _build_props() -> void:
	# --- Bodrum inişi: masa (gaz ölçer + kılavuz), yedek filtre dolabı
	_box(factory, Vector3(18.5, Y + 0.45, -11.3), Vector3(2.0, 0.9, 0.8), Color(0.3, 0.25, 0.2))
	_pickup(Vector3(18.0, Y + 0.95, -11.3), "gas_meter", "ch5_gas_meter")
	_doc(Vector3(19.0, Y + 0.93, -11.3), "Havalandırma kılavuzu", "Bodrum fanları F1, F2, F3. Basınç dengesi için sıra: F2, ardından F1, en son F3. Sıra bozulursa sistem sıfırlanır ve gaz yükselir.")
	_box(factory, Vector3(19.3, Y + 1.0, -9.5), Vector3(0.6, 2.0, 0.9), Color(0.5, 0.5, 0.2))
	_spot(factory, Vector3(18.95, Y + 1.4, -9.5), Vector3(0.05, 0.4, 0.5), Color(0.8, 0.8, 0.3), func(): return "Yedek filtre dolabı (%d)" % locker_stock(), func(_p): take_from_locker())
	# --- Boru odası: filtre kutusu
	_filter_spot(Vector3(9.0, Y + 0.95, -5.5), "pipe")
	# --- Fan odası: 3 şalter, 3 fan, filtre kutusu
	for i in 3:
		var n := i + 1
		var z := -15.0 - i * 3.0
		_spot(factory, Vector3(15.5, Y + 1.4, z), Vector3(0.1, 0.4, 0.4), Color(0.7, 0.2, 0.15), func(): return "Fan %d şalteri" % n, func(_p): press_fan(n))
		var fan := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(2.2, 0.05, 0.3)
		fan.mesh = bm
		fan.material_override = _mat(Color(0.5, 0.52, 0.55))
		fan.name = "Fan%d" % n
		fan.position = Vector3(11.0, Y + 3.3, z)
		factory.add_child(fan)
		_fans.append(fan)
	_filter_spot(Vector3(8.0, Y + 0.95, -21.5), "fan")
	# --- Pompa odası: kazancı notu, buhar vanası ve perdesi, saklanma dolabı
	_box(factory, Vector3(-3.0, Y + 0.45, -11.2), Vector3(2.4, 0.9, 0.8), Color(0.3, 0.25, 0.2))
	_doc(Vector3(-3.0, Y + 0.93, -11.2), "Kazancı Hüseyin'in notu", "Fan sırası: iki numara basıncı düşürür, ardından bir, en son üç. Yanlış sırada patlama olur. Buhar vanası kapıda: buhar kimseyi göstermez.")
	_spot(factory, Vector3(5.65, Y + 1.2, -6.2), Vector3(0.1, 0.4, 0.4), Color(0.7, 0.7, 0.75), func(): return "Buhar vanasını aç", func(_p): use_valve())
	_steam_body = StaticBody3D.new()
	_steam_body.collision_layer = 0
	_steam_body.collision_mask = 0
	_steam_body.position = Vector3(5.5, Y + 1.1, -8.0)
	var scs := CollisionShape3D.new()
	var sbs := BoxShape3D.new()
	sbs.size = Vector3(0.3, 2.2, 1.4)
	scs.shape = sbs
	_steam_body.add_child(scs)
	factory.add_child(_steam_body)
	_steam_fx = CPUParticles3D.new()
	_steam_fx.position = Vector3(5.5, Y + 0.2, -8.0)
	_steam_fx.amount = 90
	_steam_fx.lifetime = 1.6
	_steam_fx.emitting = false
	_steam_fx.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_steam_fx.emission_box_extents = Vector3(0.2, 0.05, 0.7)
	_steam_fx.direction = Vector3(0, 1, 0)
	_steam_fx.spread = 15.0
	_steam_fx.initial_velocity_min = 1.0
	_steam_fx.initial_velocity_max = 1.6
	var pm := SphereMesh.new()
	pm.radius = 0.25
	pm.height = 0.5
	_steam_fx.mesh = pm
	_steam_fx.material_override = _mat(Color(0.85, 0.9, 0.92), true)
	factory.add_child(_steam_fx)
	_hide_locker(Vector3(-3.5, Y, -11.4), Vector3(0, 0, 1.2))
	# --- Kontrol odası: mühür panosu, interkom, saklanma dolabı
	_spot(factory, Vector3(-15.5, Y + 1.4, -8.0), Vector3(0.1, 0.9, 1.2), Color(0.15, 0.25, 0.3), func(): return "Mühür panosu", func(_p): use_panel())
	_box(factory, Vector3(-10.0, Y + 2.5, -11.6), Vector3(0.4, 0.3, 0.1), Color(0.2, 0.2, 0.22))
	_hide_locker(Vector3(-12.0, Y, -11.4), Vector3(0, 0, 1.2))
