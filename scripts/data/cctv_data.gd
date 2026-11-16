class_name CctvData
extends RefCounted
## Bölüm 4 CCTV verisi: 6 kamera ve önceden kaydedilmiş klipler (performans için canlı simülasyon yerine
## sahnedeki gerçek konumlarda kısa sahneleme). Kritik üç klip: 03.14 → 03.16 → 03.17 sırasıyla işaretlenir.

const ORDER := ["c_0314", "c_0316", "c_0317"]

const CAMERAS := [
	{"id": "k1", "name": "K1 — Giriş", "pos": Vector3(-5.5, 3.3, 9.0), "look": Vector3(3, 1, 13)},
	{"id": "k2", "name": "K2 — A Hattı", "pos": Vector3(-15.3, 3.3, 7.0), "look": Vector3(-8.5, 1, 1)},
	{"id": "k3", "name": "K3 — B Hattı", "pos": Vector3(-5.3, 3.3, 7.0), "look": Vector3(2.5, 1, 2)},
	{"id": "k4", "name": "K4 — C Hattı", "pos": Vector3(15.3, 3.3, 7.0), "look": Vector3(13.5, 1, 2)},
	{"id": "k5", "name": "K5 — Kamera Odası", "pos": Vector3(6.5, 7.2, -3.3), "look": Vector3(14, 5, 2)},
	{"id": "k6", "name": "K6 — Bodrum Pompa", "pos": Vector3(-5.3, -0.7, -4.7), "look": Vector3(0, -3, -9)},
]

# actors: {"name", "from", "to", "start", "dur"}  (konumlar dünya koordinatı, y = zemin)
# lines: [saniye, metin]
const CLIPS := [
	{"id": "c_0302", "cam": "k3", "time": "03.02", "critical": false, "title": "Hat B — vardiya başı", "dur": 6.0,
		"lines": [[0.0, "03.02 — B Hattı. Makineler çalışıyor, herkes yerinde."]],
		"actors": [{"name": "Kemal", "from": Vector3(-4, 0, 6), "to": Vector3(0, 0, 3), "start": 0.0, "dur": 5.0}]},
	{"id": "c_0306", "cam": "k2", "time": "03.06", "critical": false, "title": "A Hattı — rutin kontrol", "dur": 6.0,
		"lines": [[0.0, "03.06 — A Hattı. Ayşe dikiş tezgâhında. Olağan bir gece."]],
		"actors": [{"name": "Ayşe", "from": Vector3(-14, 0, 5), "to": Vector3(-9, 0, 2), "start": 0.0, "dur": 5.0}]},
	{"id": "c_0308", "cam": "k1", "time": "03.08", "critical": false, "title": "Giriş — bekçi turu", "dur": 6.0,
		"lines": [[0.0, "03.08 — Giriş. Hasan bekçi turunda. Kapılar kilitli."]],
		"actors": [{"name": "Hasan", "from": Vector3(-4, 0, 11), "to": Vector3(3, 0, 13), "start": 0.0, "dur": 5.0}]},
	{"id": "c_0310", "cam": "k4", "time": "03.10", "critical": false, "title": "C Hattı — rutin", "dur": 6.0,
		"lines": [[0.0, "03.10 — C Hattı. Fatma sayaç defterine yazıyor."]],
		"actors": [{"name": "Fatma", "from": Vector3(12, 0, 6), "to": Vector3(13, 0, 2), "start": 0.0, "dur": 5.0}]},
	{"id": "c_0312", "cam": "k5", "time": "03.12", "critical": false, "title": "Kamera Odası — boş", "dur": 5.0,
		"lines": [[0.0, "03.12 — Kamera odası. Kimse yok. Sandalye hafifçe dönüyor."]], "actors": []},
	{"id": "c_0314", "cam": "k3", "time": "03.14", "critical": true, "title": "Hat B — bakım iptali", "dur": 9.0,
		"lines": [[0.0, "03.14 — Vardiya amiri Cemal, bakım iptal formunu imzalıyor."], [5.0, "(ses yok) Yusuf formu alıp onaylıyor."]],
		"actors": [{"name": "Cemal", "from": Vector3(-4, 0, 6), "to": Vector3(0.5, 0, 3.5), "start": 0.0, "dur": 5.0},
			{"name": "Yusuf", "from": Vector3(-1, 0, 7), "to": Vector3(1.5, 0, 3.5), "start": 1.0, "dur": 5.0}]},
	{"id": "c_0316", "cam": "k6", "time": "03.16", "critical": true, "title": "Pompa odası — vana", "dur": 9.0,
		"lines": [[0.0, "03.16 — (ses yok) Selim vanaya uzanıyor."], [4.0, "Yusuf onun kolunu tutup durduruyor. Selim geri çekiliyor."]],
		"actors": [{"name": "Selim", "from": Vector3(-3, -4, -6), "to": Vector3(0, -4, -8), "start": 0.0, "dur": 4.0},
			{"name": "Yusuf", "from": Vector3(2, -4, -6), "to": Vector3(0.8, -4, -8), "start": 0.5, "dur": 4.0}]},
	{"id": "c_0317", "cam": "k1", "time": "03.17", "critical": true, "title": "Giriş — sayım", "dur": 10.0, "sfx": "chime",
		"lines": [[0.0, "[Anons] 03.17 — Vardiya sayımı. Herkes yerine."], [4.0, "On bir kişi sırayla personel kapısına yürüyor. Kapı arkalarından kapanıyor."]],
		"actors": []},  # 11 figür Chapter4 tarafından üretilir
]

# Selim–Yusuf ses kaydı (03.16.22) — altyazılı
const TAPE := [
	"Selim: Yusuf, vana açık kalırsa bodrum doluyor. İçeride on bir kişi var.",
	"Yusuf: Raporda 'bakım iptali' yazacak. Kimse sormayacak.",
	"Selim: Ya çocuklar? Ayşe daha yirmi dört yaşında!",
	"Yusuf: Mühür panosu bodrumdaki kontrol odasında. Kapıyı kapat, Selim. Hemen.",
	"Selim: Bunu taşıyamam...",
	"Murat: Baba... sen de oradaydın.",
]


static func get_clip(clip_id: String) -> Dictionary:
	for c in CLIPS:
		if c["id"] == clip_id:
			return c
	return {}


static func get_camera(cam_id: String) -> Dictionary:
	for c in CAMERAS:
		if c["id"] == cam_id:
			return c
	return {}


static func clips_for(cam_id: String) -> Array:
	return CLIPS.filter(func(c): return c["cam"] == cam_id)
