class_name EvidenceData
extends RefCounted
## Bölüm 7 delil kaydı: 11 isimlik (işçi başına bir), 3 ayakkabı çifti, 3 fiziksel iz, 1 fotoğraf = 18 delil.
## Deliller GameManager.flags["evidence"] listesine işlenir (kayıtta saklanır; silme yolu yoktur: kaybolmaz).

const SHOES := [
	{"id": "shoes_1", "title": "Küçük bir çift ayakkabı", "desc": "Numara 37, bağcıkları çözülmüş. Ayşe'ye ait olmalı: son vardiyada acele etmiş."},
	{"id": "shoes_2", "title": "Çamurlu iş botu", "desc": "Numara 44, tabanında makine yağı. Kemal'in botu: koşarken bir teki düşmüş."},
	{"id": "shoes_3", "title": "Bekçi postalı", "desc": "Numara 43, topukları aşınmış. Hasan her gece aynı turu atardı."},
]

const TRACES := [
	{"id": "trace_nails", "title": "Kapı içinde tırnak izleri", "desc": "Çelik kapının iç yüzünde yan yana derin çizikler. Kapıyı içeriden açmaya çalışmışlar."},
	{"id": "trace_hands", "title": "Duvarda el izleri", "desc": "Duvarın alt yarısında on bir çift el izi, kurumuş kurum ve toz içinde."},
	{"id": "trace_line", "title": "Zeminde gaz çizgisi", "desc": "Zeminde sarı bir çizgi: gazın yükseldiği seviye. Çizginin altında beden ölçüsünde boşluklar."},
]

const PHOTO := {"id": "photo_scene", "title": "Duvarın fotoğrafı", "desc": "Alanın tamamı tek karede: izler, ayakkabılar, isimlikler. Kanıt olarak kullanılabilir."}


static func all() -> Array:
	var out: Array = []
	for w in WorkerData.WORKERS:
		out.append({"id": "tag_" + String(w["id"]), "title": "İsimlik — %s" % w["name"], "desc": "%s (%s). Yaka isimliği, yere düşmüş." % [w["name"], w["role"]], "category": "tag"})
	for s in SHOES:
		var d: Dictionary = s.duplicate()
		d["category"] = "shoes"
		out.append(d)
	for t in TRACES:
		var d2: Dictionary = t.duplicate()
		d2["category"] = "trace"
		out.append(d2)
	var p: Dictionary = PHOTO.duplicate()
	p["category"] = "photo"
	out.append(p)
	return out


static func get_item(id: String) -> Dictionary:
	for e in all():
		if e["id"] == id:
			return e
	return {}
