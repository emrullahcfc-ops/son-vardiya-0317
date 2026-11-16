class_name FinalInput
extends RefCounted
## Final çözümleyicinin (Aşama 18) girdisi: oyun boyunca toplanan TÜM seçim ve delil bayrakları tek sözlükte.
## "Yusuf kayıtları": (1) Bölüm 4 Selim–Yusuf kaydı, (2) Bölüm 5 elektronik onayı, (3) Bölüm 6 telefon görüşmesi,
## (4) Bölüm 7 Yusuf–Selim–Ayşe kaseti. "Özel belgeler": Nuray'ın muhasebe defteri, Cemal'in imzasız bakım iptali.


static func build() -> Dictionary:
	var workers := WorkerData.collected_count(InventoryManager)
	var ev: Array = GameManager.flags.get("evidence", []) if GameManager.flags.get("evidence", []) is Array else []
	var tags := 0
	var shoes := 0
	var traces := 0
	for id in ev:
		var s := String(id)
		if s.begins_with("tag_"):
			tags += 1
		elif s.begins_with("shoes_"):
			shoes += 1
		elif s.begins_with("trace_"):
			traces += 1
	var yusuf := 0
	for f in ["ch4_tape", "ch5_done", "ch6_choice", "ch7_tape"]:
		if GameManager.has_flag(f):
			yusuf += 1
	var specials := 0
	for f in ["doc_nuray", "doc_cemal"]:
		if GameManager.has_flag(f):
			specials += 1
	var backup := String(GameManager.flags.get("ch8_energy", "")) == "backup"
	var ledger := String(GameManager.flags.get("ch8_ledger", ""))
	return {
		"workers": workers,                      # toplanan işçi kimliği (0–11)
		"workers_all": workers >= 11,
		"tags": tags, "shoes": shoes, "traces": traces,
		"photo": ev.has("photo_scene"),
		"evidence_total": ev.size(),             # 0–18
		"yusuf_records": yusuf,                  # 0–4
		"yusuf_all": yusuf >= 4,
		"special_docs": specials,                # 0–2
		"yusuf_choice": String(GameManager.flags.get("final_choice", "")),   # expose / protect (Bölüm 6)
		"usb": InventoryManager.has_item("usb_drive"),
		"backup": backup,                        # delil USB'ye kopyalandı
		"energy": String(GameManager.flags.get("ch8_energy", "")),           # backup / cut
		"ledger": ledger,                        # sign / close / report
		"report_complete": ledger == "report" and backup,
		"count_decision": String(GameManager.flags.get("ch8_count", "")),    # accept / reject (yanlış sayımı reddet)
		"deaths": GameManager.deaths_total,
	}
