# SON VARDİYA: 03.17 — Oyun Tasarım Belgesi (Steam odaklı)

## Tek cümle
2004'te 11 işçinin kaybolduğu terk edilmiş iplik fabrikasında, kovalayan bir varlıktan saklanarak delil toplayıp çıkışa ulaştığın kurgusal birinci şahıs korku oyunu.

## Hedef kitle ve konumlandırma
- Kısa/orta uzunlukta (2–3 saat), hikâye ağırlıklı, "bulmaca + saklanma" korkusu seven oyuncular.
- Referans hissiyat: Alien: Isolation'ın gerilimi, Signalis/Amnesia'nın bulmaca-belge dengesi, ama savaş yok.
- Türkiye yerel teması (Türkçe öncelikli, endüstriyel miras) = Steam'de ayırt edici nokta.
- Fiyat hedefi: düşük/orta bütçe. Türkçe + İngilizce.

## Çekirdek döngü
Keşfet → belge/delil oku → kod bulmacasını çöz → kapı aç → Sayıcı'dan saklan/kaç → kayıt noktası.
Korku oyuncunun kırılganlığından gelir: silah yok, kaynak sınırlı (filtre, pil), saklanma ve ses yönetimi.

## Steam'e uygun olması gerekenler
- Erişilebilirlik: altyazı boyutu, flaş/titreme azaltma, fare hassasiyeti, FOV, parlaklık, ses kanalları.
- Kayıt: otomatik kontrol noktası + bozuk kayıt kurtarma.
- Mağaza metni: "Tamamen kurgusal" ibaresi; gerçek olay iddiası yok.
- Hedef sürüm: Windows 64-bit, 1080p/60 FPS orta donanımda; düşük/orta/yüksek grafik profili.
- Başarımlar (Steamworks): 4 son, 11 işçi kimliği, hiç yakalanmadan bölüm, vb.

## Bölümler (hedef süre)
1 Giriş ve Güvenlik 15 dk · 2 Üretim Hattı 25 · 3 Personel Katı 25 · 4 Kamera Kayıtları 20 ·
5 Kimyasal Bölüm 30 · 6 03.17 Vardiyası 30 · 7 Betonun Arkası 25 · 8 Son Sayım 20 → ~190 dk (tasarım hedefi, testle doğrulanır).

## Dört son
A (6+ işçi, kayıtlar, yedek) · B (delil yetersiz, kaçış) · C (defteri imzala, öncelikli) · Gizli (11 kimlik, tüm Yusuf kayıtları, 2 özel belge, tam rapor).

## Yol haritası (aşama durumu)
| Aşama | Konu | Durum |
|---|---|---|
| 01 | Proje kurulumu, git | ✅ yapıldı |
| 02 | FPS oyuncu | ✅ kod hazır, elle oynama testi bekliyor |
| 03 | Etkileşim, kapı, belge | ✅ kod hazır, elle oynama testi bekliyor |
| 04 | Envanter, görev, kayıt | ✅ otomatik testlerle doğrulandı |
| 05 | Fabrika blokları (19 alan, 3 kat) | ✅ otomatik testlerle doğrulandı; elle oynama testi bekliyor |
| 06 | Atmosfer, ses, korku olayları | ⏳ (HorrorDirector iskeleti var) |
| 07+ | Bölümler 1–8, düşmanlar, finaller, cila, build | ⏳ |

## Ürün riskleri
- Sanat ve ses üretimi: tüm modeller şu an geçici; Steam için sanatçı/varlık paketi gerekir.
- 190 dk kapsam büyük; önce Bölüm 1–3 "dikey dilim" ile oyuncu testi yapılmalı.

## Fabrika haritası (Aşama 5)
Veri: `scripts/world/factory_layout.gd`. Üretici: `scripts/world/factory.gd`. Ana sahne: `scenes/world/factory.tscn`.
- **Zemin (7):** Giriş, Güvenlik, Yükleme, A/B/C Hattı, Bakım. Dış alan oyuncunun başlangıcıdır.
- **Üst kat (6):** Soyunma, Yemekhane, Revir, Personel Bürosu, Arşiv, Kamera Odası.
- **Bodrum (6):** Boru, Pompa, Kontrol, Fan, Bakım Tüneli, Mühürlü Alan.
- Merdivenler: batıda zemin↔üst, doğuda zemin↔bodrum (26,6° rampa).
- Mühürlü Alan kapısı şimdilik kilitsiz; Bölüm 7'de kilitlenecek.
- Test modu: **F2/F3** ile alanlar arasında ışınlanma, ekranda "(n/19 alan)" sayacı.
- Şu an her şey gri kutu; sanat geçişi Aşama 20.
