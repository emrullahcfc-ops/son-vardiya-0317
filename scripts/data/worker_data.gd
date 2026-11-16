class_name WorkerData
extends RefCounted
## 11 işçinin kimlik dosyaları (kurgusal). Altısı "zorunlu" (ana rotada), beşi isteğe bağlı (gizli köşelerde).
## Ana görev altı kimlikle tamamlanır; on birinin hepsi toplanabilir. Tüm metinler tutarlıdır:
## aynı ad, görev, dolap numarası, işe giriş yılı, son vardiya 03.17 (2004).

const WORKERS := [
	{"id": "ayse", "name": "Ayşe Yıldız", "role": "Dikiş ustası", "age": 24, "locker": 2, "since": 2001, "required": true,
		"bio": "Ayşe Yıldız, 24, dikiş ustası. Vardiya sonunda annesine telefon edecekti. Son kayıt: 03.02, revir, baş ağrısı."},
	{"id": "kemal", "name": "Kemal Arslan", "role": "Makinist", "age": 41, "locker": 6, "since": 1993, "required": true,
		"bio": "Kemal Arslan, 41, makinist. Üç çocuk babası. B Hattı'nı en iyi o tanırdı. Son kayıt: 03.09, revir, el yarası."},
	{"id": "zeynep", "name": "Zeynep Aksoy", "role": "Revir hemşiresi", "age": 29, "locker": 4, "since": 2002, "required": true,
		"bio": "Zeynep Aksoy, 29, revir hemşiresi. Defterleri düzenli tutardı. Son kayıt: 03.14, kendi başı dönüyordu."},
	{"id": "hasan", "name": "Hasan Çelik", "role": "Bekçi", "age": 52, "locker": 1, "since": 1988, "required": true,
		"bio": "Hasan Çelik, 52, bekçi. Kapıları kendi anahtarıyla kilitlerdi. Son kayıt: kulübede, 03.15."},
	{"id": "fatma", "name": "Fatma Demirci", "role": "İplik kontrol", "age": 35, "locker": 3, "since": 1997, "required": true,
		"bio": "Fatma Demirci, 35, iplik kontrol. Sayaç numaralarını defterine yazardı. Son kayıt: C Hattı, 03.16."},
	{"id": "mehmet", "name": "Mehmet Kaya", "role": "Arşiv memuru", "age": 47, "locker": 5, "since": 1990, "required": true,
		"bio": "Mehmet Kaya, 47, arşiv memuru. Her dosyanın bir kopyasını saklardı. Son kayıt: arşiv, 03.16."},
	{"id": "elif", "name": "Elif Şahin", "role": "Aşçı", "age": 31, "locker": 7, "since": 1999, "required": false,
		"bio": "Elif Şahin, 31, aşçı. Gece vardiyasına çorba hazırlardı. Son kayıt: yemekhane, 03.10."},
	{"id": "ramazan", "name": "Ramazan Öztürk", "role": "Elektrikçi", "age": 38, "locker": 8, "since": 1995, "required": false,
		"bio": "Ramazan Öztürk, 38, elektrikçi. Şalterleri gece kontrol ederdi. Son kayıt: revir, 03.12, yorgunluk."},
	{"id": "nuray", "name": "Nuray Polat", "role": "Muhasebe", "age": 44, "locker": 9, "since": 1992, "required": false,
		"bio": "Nuray Polat, 44, muhasebe. Maaş pusulalarında 12. bir satır fark etmişti. Son kayıt: arşiv, 03.13."},
	{"id": "cemal", "name": "Cemal Erdem", "role": "Vardiya amiri", "age": 50, "locker": 10, "since": 1989, "required": false,
		"bio": "Cemal Erdem, 50, vardiya amiri. Bakım iptalini imzalamak zorunda kalan kişi. Son kayıt: arşiv, 03.15."},
	{"id": "huseyin", "name": "Hüseyin Taş", "role": "Kazancı", "age": 56, "locker": 11, "since": 1985, "required": false,
		"bio": "Hüseyin Taş, 56, kazancı. Bodrumdaki pompayı tek başına çalıştırırdı. Son kayıt: arşiv, 03.14."},
]

const REQUIRED_FOR_MAIN := 6


static func item_id(worker_id: String) -> String:
	return "worker_id_" + worker_id


static func get_worker(worker_id: String) -> Dictionary:
	for w in WORKERS:
		if w["id"] == worker_id:
			return w
	return {}


static func ids() -> Array:
	return WORKERS.map(func(w): return w["id"])


## Envanter için eşya tanımları (kritik: kaybolmaz).
static func item_defs() -> Dictionary:
	var d := {}
	for w in WORKERS:
		d[item_id(w["id"])] = {"name": "%s'nin kimliği" % w["name"], "critical": true,
			"desc": "Kuzey İplik personel kimliği: %s, %s." % [w["name"], w["role"]]}
	return d


static func collected_count(inventory: Node) -> int:
	var n := 0
	for w in WORKERS:
		if inventory.has_item(item_id(w["id"])):
			n += 1
	return n
