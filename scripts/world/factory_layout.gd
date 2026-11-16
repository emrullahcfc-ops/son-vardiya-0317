class_name FactoryLayout
extends RefCounted
## Fabrikanın veri tanımı: 3 kat, 19 ana alan, kapılar ve merdiven rampaları.
## Koordinatlar metre. Dikdörtgen: [x0, z0, x1, z1]. Kat: B=bodrum, G=zemin, U=üst.
## Geometri koddan üretilir (factory.gd); testler bu veriyi doğrudan kullanır.

const FLOOR_Y := {"B": -4.0, "G": 0.0, "U": 4.0}
const WALL_T := 0.2
const DOOR_W := 1.2
const DOOR_H := 2.1

# count=true olanlar "19 ana alan"dır. Diğerleri dış alan / merdiven boşluğudur.
const ROOMS := [
	# --- ZEMİN ---
	{"id": "g_out", "name": "Dış alan", "f": "G", "r": [-6, 16, 6, 24], "count": false, "ceils": []},
	{"id": "g_entry", "name": "Giriş", "f": "G", "r": [-6, 8, 6, 16]},
	{"id": "g_guard", "name": "Güvenlik", "f": "G", "r": [-14, 8, -6, 16]},
	{"id": "g_load", "name": "Yükleme", "f": "G", "r": [6, 8, 16, 16]},
	{"id": "g_lineA", "name": "A Hattı", "f": "G", "r": [-16, -4, -6, 8]},
	{"id": "g_lineB", "name": "B Hattı", "f": "G", "r": [-6, -4, 6, 8]},
	{"id": "g_lineC", "name": "C Hattı", "f": "G", "r": [6, -4, 16, 8]},
	{"id": "g_maint", "name": "Bakım", "f": "G", "r": [-6, -12, 6, -4]},
	{"id": "g_stairU", "name": "Merdiven (yukarı)", "f": "G", "r": [-20, -4, -16, 12], "count": false, "slabs": [[-20, -4, -16, 0]], "ceils": []},
	{"id": "g_stairD", "name": "Merdiven (bodrum)", "f": "G", "r": [16, -4, 20, 12], "count": false, "slabs": [[16, 4, 20, 12]]},
	# --- ÜST KAT ---
	{"id": "u_dress", "name": "Soyunma", "f": "U", "r": [-16, 8, -6, 16]},
	{"id": "u_cant", "name": "Yemekhane", "f": "U", "r": [-6, 8, 6, 16]},
	{"id": "u_infirm", "name": "Revir", "f": "U", "r": [6, 8, 16, 16]},
	{"id": "u_arch", "name": "Arşiv", "f": "U", "r": [-16, -4, -6, 8]},
	{"id": "u_office", "name": "Personel Bürosu", "f": "U", "r": [-6, -4, 6, 8]},
	{"id": "u_cam", "name": "Kamera Odası", "f": "U", "r": [6, -4, 16, 8]},
	{"id": "u_stairU", "name": "Merdiven (üst)", "f": "U", "r": [-20, -4, -16, 12], "count": false, "slabs": [[-20, 8, -16, 12]]},
	# --- BODRUM ---
	{"id": "b_stairD", "name": "Merdiven (alt)", "f": "B", "r": [16, -4, 20, 4], "count": false, "ceils": [], "no_walls": ["n"]},
	{"id": "b_land", "name": "Bodrum inişi", "f": "B", "r": [16, -12, 20, -4], "count": false},
	{"id": "b_pipe", "name": "Boru", "f": "B", "r": [6, -12, 16, -4]},
	{"id": "b_pump", "name": "Pompa", "f": "B", "r": [-6, -12, 6, -4]},
	{"id": "b_ctrl", "name": "Kontrol", "f": "B", "r": [-16, -12, -6, -4]},
	{"id": "b_fan", "name": "Fan", "f": "B", "r": [6, -24, 16, -12]},
	{"id": "b_tunnel", "name": "Bakım Tüneli", "f": "B", "r": [-6, -24, 6, -12]},
	{"id": "b_sealed", "name": "Mühürlü Alan", "f": "B", "r": [-16, -24, -6, -12]},
]

# axis "z": duvar düzlemi z=c, kapı x=p konumunda. axis "x": düzlem x=c, kapı z=p konumunda.
# open=true: kapı düğümü yok, geniş açıklık.
const DOORS := [
	{"f": "G", "a": "g_out", "b": "g_entry", "axis": "z", "c": 16, "p": 0},
	{"f": "G", "a": "g_guard", "b": "g_entry", "axis": "x", "c": -6, "p": 12, "req_item": "key_security_booth"},
	{"f": "G", "a": "g_entry", "b": "g_load", "axis": "x", "c": 6, "p": 12},
	{"f": "G", "a": "g_entry", "b": "g_lineB", "axis": "z", "c": 8, "p": 0, "req_flag": "ch1_staff_unlocked", "hint": "Personel kapısı. Elektronik kilit: enerji ve kod gerekiyor."},
	{"f": "G", "a": "g_lineA", "b": "g_guard", "axis": "z", "c": 8, "p": -10},
	{"f": "G", "a": "g_lineC", "b": "g_load", "axis": "z", "c": 8, "p": 11},
	{"f": "G", "a": "g_lineA", "b": "g_lineB", "axis": "x", "c": -6, "p": 2, "open": true},
	{"f": "G", "a": "g_lineB", "b": "g_lineC", "axis": "x", "c": 6, "p": 2},
	{"f": "G", "a": "g_lineB", "b": "g_maint", "axis": "z", "c": -4, "p": 0, "req_flag": "ch2_machines_on", "hint": "Bakım kapısı kilitli. Hatlar çalışınca kilit düşer."},
	{"f": "G", "a": "g_stairU", "b": "g_lineA", "axis": "x", "c": -16, "p": -1, "req_item": "floor_key"},
	{"f": "G", "a": "g_lineC", "b": "g_stairD", "axis": "x", "c": 16, "p": 6},
	{"f": "U", "a": "u_stairU", "b": "u_dress", "axis": "x", "c": -16, "p": 10},
	{"f": "U", "a": "u_dress", "b": "u_cant", "axis": "x", "c": -6, "p": 12},
	{"f": "U", "a": "u_cant", "b": "u_infirm", "axis": "x", "c": 6, "p": 12},
	{"f": "U", "a": "u_arch", "b": "u_dress", "axis": "z", "c": 8, "p": -11},
	{"f": "U", "a": "u_office", "b": "u_cant", "axis": "z", "c": 8, "p": 0},
	{"f": "U", "a": "u_cam", "b": "u_infirm", "axis": "z", "c": 8, "p": 11},
	{"f": "U", "a": "u_arch", "b": "u_office", "axis": "x", "c": -6, "p": 2},
	{"f": "U", "a": "u_office", "b": "u_cam", "axis": "x", "c": 6, "p": 2},
	{"f": "B", "a": "b_stairD", "b": "b_land", "axis": "z", "c": -4, "p": 18, "w": 3.8, "open": true},
	{"f": "B", "a": "b_land", "b": "b_pipe", "axis": "x", "c": 16, "p": -8},
	{"f": "B", "a": "b_pipe", "b": "b_pump", "axis": "x", "c": 6, "p": -8},
	{"f": "B", "a": "b_pump", "b": "b_ctrl", "axis": "x", "c": -6, "p": -8},
	{"f": "B", "a": "b_pipe", "b": "b_fan", "axis": "z", "c": -12, "p": 11},
	{"f": "B", "a": "b_pump", "b": "b_tunnel", "axis": "z", "c": -12, "p": 0},
	{"f": "B", "a": "b_fan", "b": "b_tunnel", "axis": "x", "c": 6, "p": -18},
	{"f": "B", "a": "b_tunnel", "b": "b_sealed", "axis": "x", "c": -6, "p": -18},
	{"f": "B", "a": "b_ctrl", "b": "b_sealed", "axis": "z", "c": -12, "p": -11},
]

# Rampalar kat değiştirir. Eğim yukarı doğru +z yönündedir.
const RAMPS := [
	{"id": "stairU", "x0": -20.0, "x1": -16.0, "z0": 0.0, "y0": 0.0, "z1": 8.0, "y1": 4.0, "a": "g_stairU", "b": "u_stairU"},
	{"id": "stairD", "x0": 16.0, "x1": 20.0, "z0": -4.0, "y0": -4.0, "z1": 4.0, "y1": 0.0, "a": "b_stairD", "b": "g_stairD"},
]

const START_ROOM := "g_out"


static func floor_y(f: String) -> float:
	return FLOOR_Y[f]


static func room(id: String) -> Dictionary:
	for r in ROOMS:
		if r["id"] == id:
			return r
	return {}


static func counted_rooms() -> Array:
	return ROOMS.filter(func(r): return r.get("count", true))


static func count_areas() -> int:
	return counted_rooms().size()


static func room_center(r: Dictionary) -> Vector3:
	var b: Array = r["r"]
	return Vector3((b[0] + b[2]) * 0.5, floor_y(r["f"]), (b[1] + b[3]) * 0.5)


static func ramp_slope_deg(rp: Dictionary) -> float:
	return rad_to_deg(atan2(rp["y1"] - rp["y0"], rp["z1"] - rp["z0"]))


## Kapı/rampa grafiğinde başlangıçtan erişilebilen oda kimlikleri.
static func reachable(start: String = START_ROOM) -> Array:
	var adj := {}
	var link := func(a: String, b: String):
		adj.get_or_add(a, []).append(b)
		adj.get_or_add(b, []).append(a)
	for d in DOORS:
		link.call(d["a"], d["b"])
	for rp in RAMPS:
		link.call(rp["a"], rp["b"])
	var seen := {start: true}
	var queue := [start]
	while not queue.is_empty():
		var cur: String = queue.pop_front()
		for n in adj.get(cur, []):
			if not seen.has(n):
				seen[n] = true
				queue.append(n)
	return seen.keys()
