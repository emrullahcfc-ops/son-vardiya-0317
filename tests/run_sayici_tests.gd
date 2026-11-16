extends SceneTree
## Aşama 12 testleri: godot --headless --fixed-fps 60 --path . --script tests/run_sayici_tests.gd
## Sayıcı: devriye, sebepsiz bilmez, görüş (makine arkası, çömelme), ses (adım/duvar), arama, takip hızı,
## saldırı uyarısı (kaçış penceresi), dolapta saklanma, radyo ile dikkat dağıtma, ses taklidi koşulları, ölüm/tekrar.

var failures: Array[String] = []
var finished := false
var gm: Node
var sv: Node
var inv: Node
var qm: Node
var hd: Node
var level: Node
var pl: Node
var sc: Node
var s: Node   # Sayıcı
var SY: GDScript


func _check(cond: bool, name: String) -> void:
	print("  ", "PASS" if cond else "FAIL", "  ", name)
	if not cond:
		failures.append(name)


func _initialize() -> void:
	var names := {
		"GameManager": "res://scripts/autoload/game_manager.gd",
		"SaveManager": "res://scripts/autoload/save_manager.gd",
		"QuestManager": "res://scripts/autoload/quest_manager.gd",
		"InventoryManager": "res://scripts/autoload/inventory_manager.gd",
		"AudioManager": "res://scripts/autoload/audio_manager.gd",
		"HorrorDirector": "res://scripts/autoload/horror_director.gd",
	}
	for n in names:
		if root.get_node_or_null(n) == null:
			var node := Node.new()
			node.name = n
			node.set_script(load(names[n]))
			root.add_child(node)
	gm = root.get_node("GameManager")
	sv = root.get_node("SaveManager")
	inv = root.get_node("InventoryManager")
	qm = root.get_node("QuestManager")
	hd = root.get_node("HorrorDirector")
	SY = load("res://scripts/enemy/sayici.gd")
	await process_frame
	await _run()
	print("")
	if not finished:
		failures.append("test sonuna ulaşılamadı (çalışma hatası)")
	if failures.is_empty():
		print("TÜM SAYICI TESTLERİ GEÇTİ")
		quit(0)
	else:
		print("BAŞARISIZ: ", failures)
		quit(1)


func _frames(n: int) -> void:
	for _i in n:
		await physics_frame


func _fresh(chapter: int) -> void:
	gm.flags.clear()
	gm.visited_areas.clear()
	gm.checkpoint_pos = []
	gm.current_chapter = chapter
	qm.clear()
	inv._items.clear()
	hd._fired.clear()
	hd.cooldown = 0.0
	sv.delete_save()
	gm.set_flag("ch2_done")
	gm.set_flag("ch2_chase_done")
	gm.set_flag("ch3_done")
	if chapter >= 5:
		gm.set_flag("ch4_done")


func _load() -> void:
	level = load("res://scenes/world/factory.tscn").instantiate()
	root.add_child(level)
	pl = level.player
	sc = level.find_children("*", "SayiciController", false, false)[0]
	level.find_children("*", "Chapter2", false, false)[0].chase_enabled = false
	await _frames(60)


func _place_player(p: Vector3, crouch := false) -> void:
	pl.global_position = p
	pl.velocity = Vector3.ZERO
	if crouch:
		Input.action_press("crouch")   # oyuncunun kendi çömelme mantığı bayrağı sıfırlamasın
	else:
		Input.action_release("crouch")
	pl.crouching = crouch
	pl.head.position.y = 0.9 if crouch else 1.6


## Sayıcı'yı sabit bir konuma koy (devriyesiz): görüş/ses testleri için.
func _put_sayici(p: Vector3, yaw: float, state_name := "PATROL") -> void:
	s.global_position = p
	s.velocity = Vector3.ZERO
	s.rotation.y = yaw
	s.route.clear()
	s.suspicion = 0.0
	s.sees_now = false
	s.hold_time = 0.0
	s._set_state(SY.State[state_name])


func _wait_state(target: String, max_frames: int) -> int:
	var f := 0
	while s.state != SY.State[target] and f < max_frames:
		await physics_frame
		f += 1
	return f


func _run() -> void:
	print("Çıkış koşulları")
	_fresh(4)
	await _load()
	gm.enter_area("g_entry", "Giriş")
	_check(sc.sayici == null, "Bölüm 5 öncesi Sayıcı yok")
	level.queue_free()
	await _frames(2)
	_fresh(5)
	await _load()
	_check(sc.sayici == null, "zemin kata inmeden Sayıcı yok")
	gm.enter_area("u_cam", "Kamera Odası")
	_check(sc.sayici == null, "üst katta Sayıcı belirmez")
	gm.enter_area("g_entry", "Giriş")
	s = sc.sayici
	_check(s != null and s.state == SY.State.PATROL, "Bölüm 5'te zemin kata girince Sayıcı devriyede belirir")

	print("Devriye ve 'sebepsiz bilmez'")
	_place_player(Vector3(0, 0.1, 22))   # dış alan: duvar arkası, sessiz
	s.global_position = Vector3(-11, 0.05, 1)
	s.start_patrol(sc.ROUTE.duplicate())
	var seen_wps := {}
	var bad_state := false
	var min_susp := 0.0
	for i in 1500:  # 25 sn
		await physics_frame
		seen_wps[s._wp] = true
		if s.state != SY.State.PATROL:
			bad_state = true
		min_susp = maxf(min_susp, s.suspicion)
	_check(seen_wps.size() >= 3, "devriye birden çok noktayı dolaşır (%d)" % seen_wps.size())
	_check(not bad_state and min_susp == 0.0, "oyuncu görünmez ve sessizken Sayıcı hiç şüphelenmez (şüphe %.2f)" % min_susp)

	print("Görüş")
	_put_sayici(Vector3(2.5, 0.05, 0.0), PI)   # +z'ye bakar; B Hattı makinesi (z 3.2–5.8) ortada
	_place_player(Vector3(2.5, 0.0, 7.0), false)
	await _frames(3)
	_check(s.can_see_player(), "makinenin arkasında AYAKTA oyuncu görünür")
	_place_player(Vector3(2.5, 0.0, 7.0), true)
	await _frames(3)
	_check(not s.can_see_player(), "makinenin arkasında ÇÖMELEN oyuncu görünmez (görüş kesilir)")
	_put_sayici(Vector3(0, 0.05, 5.0), 0.0)   # -z'ye bakar
	_place_player(Vector3(0, 0.0, 7.0))        # arkasında
	await _frames(3)
	_check(not s.can_see_player(), "arkasındaki oyuncu görünmez (görüş konisi)")
	# Kademeli şüphe: önünde, açıkta
	_put_sayici(Vector3(0, 0.05, 6.5), 0.0)
	_place_player(Vector3(0, 0.0, -2.5))
	var t_susp := -1
	var t_chase := -1
	for i in 900:
		await physics_frame
		if t_susp < 0 and s.state == SY.State.SUSPICIOUS:
			t_susp = i
		if s.state == SY.State.CHASE:
			t_chase = i
			break
	_check(t_susp > 15 and t_susp < t_chase, "önce şüphe (%.1f sn), sonra takip (%.1f sn): kademeli, ani değil" % [t_susp / 60.0, t_chase / 60.0])
	var stand_time := t_chase
	# Çömelen oyuncu daha geç fark edilir
	_put_sayici(Vector3(0, 0.05, 6.5), 0.0)
	_place_player(Vector3(0, 0.0, -2.5), true)
	var t_crouch := -1
	for i in 1800:
		await physics_frame
		if s.state == SY.State.CHASE:
			t_crouch = i
			break
	_check(t_crouch < 0 or t_crouch > stand_time, "çömelen oyuncu daha geç ya da hiç fark edilmez (%s)" % ("hiç" if t_crouch < 0 else "%.1f sn" % (t_crouch / 60.0)))

	print("Ses")
	_place_player(Vector3(0, 0.0, 22))
	_put_sayici(Vector3(0, 0.05, 0), 0.0)
	gm.make_noise(Vector3(0, 0, 10), 11.0, "test")   # duvar arkası, 10 m: 11*0.6=6.6 < 10
	await _frames(2)
	_check(s.state == SY.State.PATROL, "duvar arkasındaki uzak ses (10 m, koşu yarıçapı) duyulmaz")
	gm.make_noise(Vector3(-4.5, 0, -1), pl.NOISE_WALK, "test")  # 4.5 m açık alan, yürüme yarıçapı 4.5
	await _frames(2)
	_check(s.state == SY.State.PATROL or s.state == SY.State.SUSPICIOUS, "yürüme sesi sınırda")
	_put_sayici(Vector3(0, 0.05, 0), 0.0)
	gm.make_noise(Vector3(-5.5, 0, -1), pl.NOISE_WALK, "test")  # 5.5 m > 4.5
	await _frames(2)
	_check(s.state == SY.State.PATROL, "yürüme sesi 5,5 m'de duyulmaz")
	gm.make_noise(Vector3(-5.5, 0, -1), pl.NOISE_CROUCH, "test")
	await _frames(2)
	_check(s.state == SY.State.PATROL, "çömelme sesi (1,5 m) hiç duyulmaz")
	gm.make_noise(Vector3(-5.5, 0, -1), pl.NOISE_SPRINT, "test")  # koşu yarıçapı 11
	await _frames(2)
	_check(s.state == SY.State.SUSPICIOUS, "koşu sesi 5,5 m'de duyulur → şüphe")
	var d0: float = s.global_position.distance_to(Vector3(-5.5, 0, -1))
	s.route.clear()
	await _wait_state("SEARCH", 400)
	_check(s.state == SY.State.SEARCH, "şüpheden sonra ARAMA durumu (son bilinen konum)")
	await _frames(300)
	_check(s.global_position.distance_to(Vector3(-5.5, 0, -1)) < d0 - 1.5 or s.global_position.distance_to(Vector3(-5.5, 0, -1)) < 2.0, "ses kaynağına doğru gider")

	print("Takip hızı ve saldırı uyarısı")
	_put_sayici(Vector3(-4, 0.05, 6), 0.0, "CHASE")
	s.suspicion = 1.0
	_place_player(Vector3(3, 0.0, -2.0))
	s.last_known = pl.global_position
	var p0: Vector3 = s.global_position
	await _frames(60)
	var spd: float = Vector2(s.global_position.x - p0.x, s.global_position.z - p0.z).length() / 1.0
	_check(spd > 3.0 and spd < pl.SPRINT_SPEED, "takip hızı %.1f m/sn: yürümeden hızlı, koşudan yavaş (kaçış mümkün)" % spd)
	# Saldırı: yan yana, durağan oyuncu
	_put_sayici(Vector3(0, 0.05, 0), 0.0, "CHASE")
	s.suspicion = 1.0
	s.enabled = true
	_place_player(Vector3(0, 0.0, -1.1))
	var caught_t := [-1.0]
	var attack_t := [-1.0]
	var clock := [0.0]
	s.caught.connect(func(): caught_t[0] = clock[0])
	s.attack_started.connect(func(): attack_t[0] = clock[0])
	var died := [false]
	sc.player_died.connect(func(): died[0] = true)
	for i in 240:
		await physics_frame
		clock[0] += 1.0 / 60.0
		if caught_t[0] >= 0.0:
			break
	_check(attack_t[0] >= 0.0 and caught_t[0] - attack_t[0] >= 0.6, "saldırı ile yakalama arasında en az 0,6 sn uyarı (%.2f)" % (caught_t[0] - attack_t[0]))
	_check(died[0], "durağan oyuncu yakalanınca ölüm akışı başlar")
	await _frames(200)
	_check(sc.sayici == null, "ölümden sonra Sayıcı sahneden kalkar (yeniden doğmayı bekler)")
	# Kaçış penceresi: uyarı sırasında uzaklaşan oyuncu kurtulur
	gm.enter_area("g_entry", "Giriş")
	s = sc.sayici
	_check(s != null, "oyuncu zemin kata dönünce Sayıcı yeniden devriyeye başlar (tekrarlanabilir)")
	_put_sayici(Vector3(0, 0.05, 0), 0.0, "CHASE")
	s.suspicion = 1.0
	_place_player(Vector3(0, 0.0, -1.1))
	died[0] = false
	var f := 0
	while s.state != SY.State.ATTACK and f < 120:
		await physics_frame
		f += 1
	_check(s.state == SY.State.ATTACK, "yakın oyuncuya saldırı başlar")
	_place_player(Vector3(0, 0.0, -5.0))  # uyarı süresinde uzaklaş
	await _frames(60)
	_check(not died[0] and s.state != SY.State.ATTACK, "uyarı sırasında uzaklaşan oyuncuya saldırı boşa gider (kaçış penceresi)")

	print("Dolapta saklanma")
	var spot: Node = null
	for h in get_nodes_in_group("hide_spots"):
		if h.global_position.distance_to(Vector3(-13.3, 0, 15.3)) < 0.5:
			spot = h
	_check(spot != null, "güvenlik kulübesinde saklanma dolabı var")
	_put_sayici(Vector3(-11, 0.05, 11.0), PI, "CHASE")   # +z'ye bakıyor (oyuncuyu görüyor)
	s.suspicion = 1.0
	_place_player(Vector3(-11, 0.0, 14.0))
	await _frames(3)
	_check(s.can_see_player(), "(hazırlık) Sayıcı oyuncuyu görüyor")
	spot.interact(pl)
	_check(not pl.hidden and not spot.occupied, "görülürken saklanılamaz")
	_put_sayici(Vector3(0, 0.05, 0), 0.0)
	_place_player(Vector3(-12.0, 0.0, 14.0))
	spot.interact(pl)
	_check(pl.hidden and spot.occupied and not pl.controls_enabled, "görünmüyorken dolaba girilir (kontroller kilitli)")
	_check(spot.get_prompt() == "Dolaptan çık", "ipucu: dolaptan çık")
	_put_sayici(Vector3(-12.0, 0.05, 12.0), PI, "PATROL")   # dolaba bakıyor, 3 m
	await _frames(3)
	_check(not s.can_see_player(), "dolapta saklanan oyuncu 3 m'den bile görünmez")
	# Arama: dolabı kontrol ETMEZ
	s.hide_check_chance = 0.0
	s.last_known = Vector3(-12.5, 0, 13.0)
	s._set_state(SY.State.SEARCH)
	s.route = sc.ROUTE.duplicate()
	for i in 1500:
		await physics_frame
		if s.state == SY.State.PATROL:
			break
	_check(s.state == SY.State.PATROL and spot.occupied and pl.hidden, "dolabı kontrol etmeyen Sayıcı aramayı bırakır; oyuncu güvende")
	# Arama: dolabı kontrol EDER
	_put_sayici(Vector3(-12.0, 0.05, 12.0), PI, "PATROL")
	s.hide_check_chance = 1.0
	s.last_known = Vector3(-12.5, 0, 13.0)
	s._set_state(SY.State.SEARCH)
	s.route = sc.ROUTE.duplicate()
	for i in 1500:
		await physics_frame
		if s.state == SY.State.CHASE or s.state == SY.State.ATTACK or not spot.occupied:
			break
	_check(not spot.occupied and not pl.hidden, "dolabı kontrol eden Sayıcı oyuncuyu bulur (dolap açılır)")
	_check(s.state == SY.State.CHASE or s.state == SY.State.ATTACK, "bulunca takip/saldırı başlar")
	# Çıkış
	_put_sayici(Vector3(0, 0.05, 0), 0.0)
	_place_player(Vector3(-12.0, 0.0, 14.0))
	spot.interact(pl)
	spot.interact(pl)
	_check(not pl.hidden and not spot.occupied and pl.controls_enabled, "E ile dolaptan çıkılır, kontroller geri gelir")
	_check(pl.global_position.distance_to(Vector3(-13.3, 0, 14.1)) < 1.0, "çıkış konumu dolabın önü (duvarda sıkışma yok)")

	print("Dikkat dağıtma (radyo)")
	var radio: Node = null
	for c in level.get_children():
		if "prompt_fn" in c and c.get_prompt().begins_with("Radyoyu aç") and c.global_position.distance_to(Vector3(13.0, 1.0, 7.6)) < 0.5:
			radio = c
	_check(radio != null, "C Hattı'nda radyo var")
	_place_player(Vector3(0, 0.0, 22))
	_put_sayici(Vector3(11, 0.05, -1.0), 0.0, "PATROL")
	s.route.clear()
	radio.interact(pl)
	await _frames(2)
	_check(s.state == SY.State.SUSPICIOUS, "radyo sesi Sayıcı'yı şüphelendirir")
	var dr0: float = s.global_position.distance_to(radio.global_position)
	await _frames(600)
	_check(s.global_position.distance_to(radio.global_position) < dr0 - 2.0, "Sayıcı radyoya doğru gider (dikkat dağıtma işe yarar): %.1f → %.1f m" % [dr0, s.global_position.distance_to(radio.global_position)])
	var before_noise: int = s.state
	radio.interact(pl)
	_check(true, "radyo bekleme süresinde tekrar basılabilir (hata vermez)")

	print("Ses taklidi koşulları")
	_put_sayici(Vector3(0, 0.05, 0), 0.0, "CHASE")
	_check(not sc.try_voice_mimic(), "takipteyken ses taklidi tetiklenmez")
	gm.current_chapter = 4
	_put_sayici(Vector3(0, 0.05, 0), 0.0, "PATROL")
	_check(not sc.try_voice_mimic(), "Bölüm 5 öncesi tetiklenmez")
	gm.current_chapter = 5
	hd._fired.clear()
	_put_sayici(Vector3(0, 0.05, 0), 0.0, "PATROL")
	_check(sc.try_voice_mimic() and s.hold_time > 5.0, "Bölüm 5'te devriyedeyken tetiklenir; Sayıcı pusuda bekler")
	_check(not sc.try_voice_mimic(), "yalnızca bir kez")

	print("Debug AI durumu")
	_check("PATROL" in s.debug_text() and "şüphe" in s.debug_text(), "debug metni durum ve şüpheyi gösterir")
	level.queue_free()
	sv.delete_save()
	finished = true
