class_name Chapter7
extends ChapterBase
## Bölüm 7: Betonun Arkası. Bakım tünelinde dört sistem (hidrolik hortum, jeneratör, kilit devresi, basınç dengeleme) Mühürlü Alan'ın
## hidrolik kilidini açar. Alanda delil toplanır (11 isimlik, 3 ayakkabı, 3 iz, 1 fotoğraf), Yusuf–Selim–Ayşe kaseti çalınır,
## en az 6 isimlik + fotoğraf + kaset tamamlanınca Sayıcı'nın son sayımı başlar ve final rotası (Bölüm 8) açılır.

const Y := -4.0
const HOSE_SOLUTION := [1, 2, 3]            # BASINÇ = kırmızı(1), DÖNÜŞ = mavi(2), TAHLİYE = yeşil(3)
const HOSE_COLORS := ["boş", "kırmızı", "mavi", "yeşil"]
const CIRCUIT_PATTERN := [true, false, true, false]
const PRESSURE_START := 9.0
const PRESSURE_TARGET := 5.0
const VALVE_DELTA := {"A": -3.0, "B": 2.0, "C": -1.0}
const TAGS_REQUIRED := 6
const TAPE := [
	"[Kaset — Ayşe] Beni duyan varsa... on bir kişiyiz. Kapı kapandı. Gaz geliyor.",
	"[Kaset — Selim] Yusuf! Vanayı aç, çocuklar içeride!",
	"[Kaset — Yusuf] Açamam Selim. Rapor yazıldı: bakım iptali. Kimse duymayacak.",
	"[Kaset — Ayşe] Annem... annem yarın beni bekliyor.",
	"[Kaset — Yusuf] (fısıltı) Beni affedin.",
]
const NUMBERS := ["Bir", "İki", "Üç", "Dört", "Beş", "Altı", "Yedi", "Sekiz", "Dokuz", "On", "On bir", "On iki"]

var _wait := true
var pressure_resets := 0
var tape_lines_played: Array = []
var counting_lines: Array = []
var _ports: Array[Node] = []


signal unsealed
signal final_count_started


func _ready() -> void:
	_build_props()
	GameManager.chapter_changed.connect(func(c): if c >= 7: _begin())
	if GameManager.current_chapter >= 7 and not GameManager.has_flag("ch7_done"):
		_begin()


func _begin() -> void:
	if GameManager.has_flag("ch7_started"):
		return
	GameManager.set_flag("ch7_started")
	QuestManager.start_quest("ch7_unseal")
	QuestManager.start_quest("ch7_evidence")
	AudioManager.say("Bakım tüneli. Mühürlü Alan'ın hidrolik kilidi burada. Hortum, jeneratör, devre ve basınç.", 6.0)


# ------------------------------------------------------------------ delil kaydı
func evidence() -> Array:
	var v: Variant = GameManager.flags.get("evidence", [])
	return v if v is Array else []


func evidence_count() -> int:
	return evidence().size()


func tags_count() -> int:
	var n := 0
	for id in evidence():
		if String(id).begins_with("tag_"):
			n += 1
	return n


## Delili kayda işler (kaybolmaz, tekrar eklenmez). Bayrak listesi kayıtla saklanır.
func collect(id: String) -> bool:
	var item := EvidenceData.get_item(id)
	if item.is_empty():
		return false
	var list := evidence().duplicate()
	if list.has(id):
		AudioManager.say("Bu delili zaten kayda işledin.", 2.0)
		return false
	list.append(id)
	GameManager.flags["evidence"] = list
	AudioManager.play_sfx("click")
	AudioManager.say("DELİL %d/18 — %s. %s" % [list.size(), item["title"], item["desc"]], 7.0)
	check_final()
	return true


# ------------------------------------------------------------------ puzzle 1: hidrolik hortum
func hose() -> Array:
	# JSON kaydından sayılar ondalık gelir (1.0); karşılaştırma için tam sayıya çevrilir.
	var v: Variant = GameManager.flags.get("ch7_hose", [0, 0, 0])
	var out: Array = []
	if v is Array:
		for x in v:
			out.append(int(x))
	while out.size() < 3:
		out.append(0)
	return out


func cycle_port(i: int) -> String:
	if GameManager.has_flag("ch7_hose_ok"):
		AudioManager.say("Hortumlar doğru bağlı.", 1.5)
		return "done"
	var h := hose().duplicate()
	h[i] = (int(h[i]) + 1) % HOSE_COLORS.size()
	GameManager.flags["ch7_hose"] = h
	AudioManager.play_sfx("click")
	if h == HOSE_SOLUTION:
		GameManager.set_flag("ch7_hose_ok")
		AudioManager.say("Hortum kuruldu: basınç kırmızıda, dönüş mavide, tahliye yeşilde. Hidrolik hatta basınç geldi.", 5.0)
		check_unseal()
		return "ok"
	AudioManager.say("Giriş %d: %s hortum." % [i + 1, HOSE_COLORS[h[i]]], 1.5)
	return "set"


# ------------------------------------------------------------------ puzzle 2: jeneratör
func use_generator() -> String:
	if GameManager.has_flag("ch7_gen_on"):
		AudioManager.say("Jeneratör çalışıyor.", 1.5)
		return "on"
	if not InventoryManager.has_item("fuel_can"):
		AudioManager.play_sfx("error")
		AudioManager.say("Jeneratör susuyor: depo boş. Yakıt bidonu lazım (tünelde bir yerde).", 4.0)
		return "no_fuel"
	GameManager.set_flag("ch7_gen_on")
	AudioManager.start_layer("machine", -12.0)
	AudioManager.say("Jeneratör ilk denemede tuttu. Devre panosuna enerji geldi.", 4.0)
	return "ok"


# ------------------------------------------------------------------ puzzle 3: kilit devresi
func switches() -> Array:
	var v: Variant = GameManager.flags.get("ch7_sw", [false, false, false, false])
	return v if v is Array else [false, false, false, false]


func correct_switches() -> int:
	var n := 0
	var s := switches()
	for i in 4:
		if bool(s[i]) == CIRCUIT_PATTERN[i]:
			n += 1
	return n


func toggle_switch(i: int) -> String:
	if GameManager.has_flag("ch7_circuit_ok"):
		AudioManager.say("Devre kilidi açık.", 1.5)
		return "done"
	var s := switches().duplicate()
	s[i] = not bool(s[i])
	GameManager.flags["ch7_sw"] = s
	AudioManager.play_sfx("click")
	if not GameManager.has_flag("ch7_gen_on"):
		AudioManager.say("Anahtar %d %s. Devre enerjisiz: jeneratörü çalıştır." % [i + 1, "yukarı" if s[i] else "aşağı"], 3.0)
		return "no_power"
	var ok := correct_switches()
	if ok == 4:
		GameManager.set_flag("ch7_circuit_ok")
		AudioManager.play_sfx("beep")
		AudioManager.say("Devre doğru: kilit çözüldü.", 3.0)
		check_unseal()
		return "ok"
	AudioManager.say("Devre ışığı: %d/4 anahtar doğru." % ok, 3.0)
	return "partial"


# ------------------------------------------------------------------ puzzle 4: basınç dengeleme
func pressure() -> float:
	return float(GameManager.flags.get("ch7_pressure", PRESSURE_START))


## Vana A −3, B +2, C −1. Hedef 5 bar. 10 ve üstü ya da 0 ve altı: emniyet valfi açar, basınç 9'a sıfırlanır.
func valve(letter: String) -> String:
	if GameManager.has_flag("ch7_pressure_ok"):
		AudioManager.say("Basınç dengede (5 bar).", 1.5)
		return "done"
	if not GameManager.has_flag("ch7_hose_ok") or not GameManager.has_flag("ch7_gen_on"):
		AudioManager.say("Vanalar çalışmıyor: hortum ve jeneratör gerekiyor.", 3.0)
		return "no_system"
	var p := pressure() + float(VALVE_DELTA[letter])
	AudioManager.play_sfx("click")
	if p >= 10.0 or p <= 0.0:
		GameManager.flags["ch7_pressure"] = PRESSURE_START
		pressure_resets += 1
		AudioManager.play_sfx("error")
		AudioManager.say("Emniyet valfi açtı! Basınç sıfırlandı: 9 bar. Kılavuzdaki değerleri yeniden hesapla.", 5.0)
		return "reset"
	GameManager.flags["ch7_pressure"] = p
	if is_equal_approx(p, PRESSURE_TARGET):
		GameManager.set_flag("ch7_pressure_ok")
		AudioManager.say("Basınç 5 bar: dengede.", 3.0)
		check_unseal()
		return "ok"
	AudioManager.say("Basınç: %.0f bar (hedef 5)." % p, 2.5)
	return "set"


func check_unseal() -> void:
	if GameManager.has_flag("ch7_unsealed"):
		return
	if GameManager.has_flag("ch7_hose_ok") and GameManager.has_flag("ch7_circuit_ok") and GameManager.has_flag("ch7_pressure_ok"):
		GameManager.set_flag("ch7_unsealed")
		_complete("ch7_unseal")
		AudioManager.play_sfx("door_slam")
		AudioManager.say("Hidrolik kilit çözüldü. Mühürlü Alan'ın kapıları açılabilir.", 5.0)
		_checkpoint()
		unsealed.emit()


# ------------------------------------------------------------------ kaset ve fotoğraf
func play_cassette() -> String:
	if not InventoryManager.has_item("cassette"):
		AudioManager.say("Kaset çalar boş. Kasetin bir yerlerde olmalı.", 3.0)
		return "no_cassette"
	GameManager.set_flag("ch7_tape")
	tape_lines_played.clear()
	for i in TAPE.size():
		tape_lines_played.append(TAPE[i])
		if _wait:
			get_tree().create_timer(4.5 * i).timeout.connect(func(): AudioManager.say(TAPE[i], 5.0))
		else:
			AudioManager.say(TAPE[i], 5.0)
	check_final()
	return "ok"


func take_photo() -> String:
	if not InventoryManager.has_item("camera"):
		AudioManager.say("Fotoğraf makinesi lazım.", 2.5)
		return "no_camera"
	AudioManager.play_sfx("click")
	collect("photo_scene")
	return "ok"


# ------------------------------------------------------------------ son sayım ve final rotası
func final_ready() -> bool:
	return tags_count() >= TAGS_REQUIRED and evidence().has("photo_scene") and GameManager.has_flag("ch7_tape")


func check_final() -> void:
	if final_ready() and not GameManager.has_flag("ch7_final") and GameManager.has_flag("ch7_unsealed"):
		start_final_count()


## Sayıcı toplanan her isimliği sayar, sonunda Murat'ı: "On iki". Ardından final rotası (Bölüm 8) açılır.
func start_final_count() -> void:
	GameManager.set_flag("ch7_final")
	final_count_started.emit()
	var tags: Array = []
	for id in evidence():
		if String(id).begins_with("tag_"):
			tags.append(String(id).trim_prefix("tag_"))
	counting_lines.clear()
	for i in tags.size():
		var w := WorkerData.get_worker(tags[i])
		counting_lines.append("Sayıcı: %s — %s." % [NUMBERS[i], w["name"]])
	counting_lines.append("Sayıcı: %s — Murat Demir. Sayım tamam." % NUMBERS[mini(tags.size(), 11)])
	var sy := _spawn_counter()
	for l in counting_lines:
		AudioManager.play_sfx("chime" if String(l).contains("Murat") else "click")
		AudioManager.say(l, 3.0)
		if _wait:
			await get_tree().create_timer(2.2).timeout
			if not is_inside_tree():
				return
	_finish(sy)


func _spawn_counter() -> Node3D:
	var sy := Sayici.new()
	factory.add_child(sy)
	sy.player = factory.player
	sy.global_position = Vector3(-11, Y + 0.05, -18)
	sy.enabled = false
	return sy


func _finish(sy: Node) -> void:
	if is_instance_valid(sy):
		sy.queue_free()
	GameManager.flags["final_metrics"] = {
		"tags": tags_count(), "evidence": evidence_count(), "tape": GameManager.has_flag("ch7_tape"),
		"photo": evidence().has("photo_scene"), "choice": String(GameManager.flags.get("final_choice", "")),
	}
	GameManager.set_flag("ch7_done")
	GameManager.set_flag("final_route_open")
	_complete("ch7_evidence")
	AudioManager.play_sfx("door_slam")
	AudioManager.say("Kapılar kapanıyor! Son sayım başladı: çıkışa ulaş!", 5.0)
	GameManager.set_chapter(8)
	_checkpoint()


# ------------------------------------------------------------------ sahne
func _port_spot(pos: Vector3, label: String, idx: int) -> void:
	var s := _spot(factory, pos, Vector3(0.3, 0.3, 0.12), Color(0.4, 0.4, 0.42), func(): return "%s girişi: %s hortum" % [label, HOSE_COLORS[int(hose()[idx])]], func(_p): cycle_port(idx))
	_ports.append(s)


func _evidence_spot(pos: Vector3, id: String, prompt: String, size := Vector3(0.28, 0.06, 0.18)) -> void:
	_spot(factory, pos, size, Color(0.75, 0.7, 0.5), func(): return prompt, func(_p): collect(id))


func _build_props() -> void:
	# --- Bakım tüneli: hortum girişleri (güney duvar), jeneratör, yakıt, devre, basınç, belgeler
	_port_spot(Vector3(-3.0, Y + 1.3, -23.65), "BASINÇ", 0)
	_port_spot(Vector3(0.0, Y + 1.3, -23.65), "DÖNÜŞ", 1)
	_port_spot(Vector3(3.0, Y + 1.3, -23.65), "TAHLİYE", 2)
	_box(factory, Vector3(4.0, Y + 0.45, -22.6), Vector3(2.0, 0.9, 0.8), Color(0.3, 0.25, 0.2))
	_doc(Vector3(3.4, Y + 0.93, -22.6), "Hortum renk kodu", "Hidrolik hat: KIRMIZI hortum basınç, MAVİ hortum dönüş, YEŞİL hortum tahliye. Her girişin üstünde adı yazar.")
	_doc(Vector3(3.9, Y + 0.93, -22.6), "Devre şeması", "Kilit devresi dört anahtarlıdır: 1 ve 3 yukarı, 2 ve 4 aşağı olmalı. Devre jeneratör çalışmadan okunmaz.")
	_doc(Vector3(4.4, Y + 0.93, -22.6), "Basınç kılavuzu", "Başlangıç 9 bar. Vana A: −3, vana B: +2, vana C: −1. Hedef 5 bar. 10 bar ve üstü ya da 0 ve altı: emniyet valfi açar, sistem 9 bara döner.")
	_box(factory, Vector3(-4.8, Y + 0.5, -22.5), Vector3(1.2, 1.0, 1.4), Color(0.25, 0.3, 0.2))
	_spot(factory, Vector3(-4.8, Y + 1.15, -22.5), Vector3(0.4, 0.2, 0.4), Color(0.8, 0.6, 0.2), func(): return "Jeneratörü çalıştır", func(_p): use_generator())
	_box(factory, Vector3(4.4, Y + 0.45, -13.0), Vector3(0.8, 0.9, 0.8), Color(0.35, 0.3, 0.22))
	_pickup(Vector3(4.4, Y + 0.95, -13.0), "fuel_can", "ch7_fuel")
	for i in 4:
		var idx := i
		_spot(factory, Vector3(-5.65, Y + 1.4, -13.2 - i * 0.6), Vector3(0.1, 0.3, 0.2), Color(0.7, 0.7, 0.2), func(): return "Devre anahtarı %d (%s)" % [idx + 1, "yukarı" if bool(switches()[idx]) else "aşağı"], func(_p): toggle_switch(idx))
	for j in 3:
		var letter: String = ["A", "B", "C"][j]
		_spot(factory, Vector3(5.65, Y + 1.3, -15.0 - j * 0.8), Vector3(0.1, 0.3, 0.3), Color(0.55, 0.2, 0.15), func(): return "Vana %s (%+.0f bar) — şimdi %.0f bar" % [letter, VALVE_DELTA[letter], pressure()], func(_p): valve(letter))
	# --- Mühürlü Alan: isimlikler, ayakkabılar, izler, makine, kaset
	var i := 0
	for w in WorkerData.WORKERS:
		var x := -15.0 + (i % 4) * 2.4
		var z := -22.5 + (i / 4) * 3.2
		_evidence_spot(Vector3(x, Y + 0.1, z), "tag_" + String(w["id"]), "Al: isimlik — %s" % w["name"], Vector3(0.25, 0.05, 0.15))
		i += 1
	_evidence_spot(Vector3(-14.5, Y + 0.1, -13.3), "shoes_1", "İncele: ayakkabı çifti", Vector3(0.3, 0.12, 0.2))
	_evidence_spot(Vector3(-9.0, Y + 0.1, -13.2), "shoes_2", "İncele: iş botu", Vector3(0.3, 0.12, 0.2))
	_evidence_spot(Vector3(-12.0, Y + 0.1, -20.8), "shoes_3", "İncele: postal", Vector3(0.3, 0.12, 0.2))
	_evidence_spot(Vector3(-15.6, Y + 1.0, -17.0), "trace_nails", "İncele: tırnak izleri", Vector3(0.1, 0.5, 0.5))
	_evidence_spot(Vector3(-9.0, Y + 1.2, -23.6), "trace_hands", "İncele: el izleri", Vector3(0.6, 0.5, 0.1))
	_evidence_spot(Vector3(-8.0, Y + 0.02, -18.0), "trace_line", "İncele: zemindeki çizgi", Vector3(0.6, 0.04, 0.3))
	_box(factory, Vector3(-7.4, Y + 0.45, -14.6), Vector3(0.8, 0.9, 2.0), Color(0.3, 0.25, 0.2))
	_pickup(Vector3(-7.4, Y + 0.95, -13.9), "camera", "ch7_camera")
	_pickup(Vector3(-7.4, Y + 0.95, -14.6), "cassette", "ch7_cassette")
	_spot(factory, Vector3(-7.4, Y + 0.95, -15.4), Vector3(0.3, 0.12, 0.2), Color(0.15, 0.15, 0.18), func(): return "Kaset çalar", func(_p): play_cassette())
	_spot(factory, Vector3(-15.6, Y + 1.8, -20.0), Vector3(0.1, 0.8, 1.6), Color(0.35, 0.32, 0.3), func(): return "Duvardaki izleri fotoğrafla", func(_p): take_photo())
