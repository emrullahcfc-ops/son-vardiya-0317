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
| 06 | Atmosfer, ses, korku olayları | ✅ otomatik testlerle doğrulandı; kulakla/gözle deneme bekliyor |
| 07 | Bölüm 1: Giriş ve Güvenlik | ✅ otomatik testlerle doğrulandı; baştan sona elle oynama bekliyor |
| 08 | Bölüm 2: Üretim Hattı | ✅ otomatik testlerle doğrulandı; elle oynama bekliyor |
| 09 | Taklitçi düşman ve ilk kovalamaca | ✅ otomatik testlerle doğrulandı; elle oynama ve süre/denge ayarı bekliyor |
| 10 | Bölüm 3: Personel Katı | ✅ otomatik testlerle doğrulandı; elle oynama bekliyor |
| 11+ | Bölümler 4–8, Sayıcı, finaller, cila, build | ⏳ |

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

## Atmosfer ve korku olayları (Aşama 6)
- **Ses:** `AudioManager` telifsiz, sentetik sesler üretir (kapı çarpması, anons zili, vızıltı, boğuk vuruş, fısıltı) ve döngülü ortam katmanları çalar (uğultu, rüzgâr). Kanallar: Master, SFX, Ambient (ayarlardan ayrı ayrı kısılır). Gerçek ses dosyaları Aşama 20'de eklenir.
- **Olay motoru:** `HorrorDirector.EVENTS` alana bağlı olayları tanımlar. Kurallar: tek seferlik, 20 sn genel bekleme, en erken bölüm koşulu, kayıtta korunur. `intensity` (0–1) her olayla artar, zamanla düşer; ortam uğultusunun sesini sürer.
- **Etkiler:** `HorrorEffects` olayları uygular: ışık titremesi (B Hattı), anons (A Hattı), kapı çarpması (Bakım), siluet (Bakım Tüneli).
- **Erişilebilirlik:** `flash_reduction` açıkken ışık titremesi hızlı yanıp sönmez (adımlar ≥ 0,3 sn, ani değişim ≤ %50); siluet yavaş solar.
- **Test modu:** **F4** olayları sırayla oynatır (bekleme süresini yok sayar).

## Bölüm 1: Giriş ve Güvenlik (Aşama 7)
Kod: `scripts/chapters/chapter1.gd` (Chapter1), `scripts/interact/keypad.gd`, `callback_interactable.gd`.
Akış: yağmurlu dış alan + araç → Hakan telefonu (zil + altyazı) → Giriş: kulübe anahtarı (masada) → Güvenlik: ölçü aleti, vardiya defteri, durmuş saat (03.17), sigorta panosu (1. etkileşim: voltaj ölçümü 0 V, 2.: şalter) → Giriş: tuş takımı (kod **0317**, enerji gerekir, sınırsız deneme) → personel kapısı → üretim hattına girince 03.17 anonsu, Bölüm 2'ye geçiş, otomatik kontrol noktası.
- **12. siluet:** 11 işçi panosu yalnızca enerji açıkken ve ilk incelemede 12. karartılı çerçeveyi ve "12. — Murat Demir" satırını gösterir; ardından Hakan'ın ikinci telefonu gelir.
- **Softlock yok:** tüm eşyalar kilitsiz bölgelerde; yanlış kod serbestçe tekrar denenir; anahtar/ölçü aleti kritik eşyadır, kaybolmaz.
- **Kilit verisi:** `FactoryLayout.DOORS` içinde `req_item` (eşya) ve `req_flag` (bayrak) anahtarları.
- Bilinen eksik: turnike şimdilik dekor (etkileşimsiz); gerçek ses/ses oyunculuğu yok.

## Bölüm 2: Üretim Hattı (Aşama 8)
Kod: `scripts/chapters/chapter2.gd` (ortak yardımcılar: `chapter_base.gd`).
- **Faz sırası (B → C → A):** her hattın yanında kırmızı başlat düğmesi var. Doğru sırada hat yeşil yanar; yanlış sırada hepsi sıfırlanır ve tekrar denenir. Sırayı B Hattı'ndaki **vardiya çizelgesi** verir ("2. hat, 3. hat, 1. hat"; 1=A, 2=B, 3=C).
- **Dolap kodu 317 (tahmin değil, belgeyle):** A Hattı'ndaki **dilekçe** duruş sırasını (A, B, C) ve sayaçları söyler; Bakım'daki **bakım iptal formu** kuralı verir: "hat sayısı, ardından en son duran hattın sayacı". Makine plakaları sayaçları gösterir (A 04, B 11, C 17). Hat sayısı 3 + son duran C'nin sayacı 17 = **317**.
- **Final:** üç hat eşzamanlı çalışır (makine sesi, ışık nefesi, anons); bakım kapısının kilidi düşer. Dolaptan **kat anahtarı** alınır, bölüm biter ve kayıt alınır; merdiven kapısı artık açılır (kat anahtarı ister).
- Kilit verisi: `FactoryLayout.DOORS` `req_flag` (bakım kapısı: `ch2_machines_on`) ve `req_item` (merdiven: `floor_key`).
- Not: Bölüm 3'e (Personel Katı) geçiş Aşama 10'da; şimdilik `ch2_done` bayrağı ve kayıt var.

## Taklitçi ve ilk kovalamaca (Aşama 9)
Kod: `scripts/enemy/mimic.gd`, `scripts/world/shutter.gd`, kovalamaca mantığı `chapter2.gd` (alt kısım).
- **Taklitçi:** koyu, gözleri parlayan insan siluetli düşman. `NavigationAgent3D` ile yol bulur; yol ağı fabrika kurulurken koddan üretilir (`factory.gd` → `_build_navigation`). Görüş: 22 m, 120° koni, duvar/kapı engeli. Durumlar: uyku → kovalama → (4 sn görmezse) arama (son bilinen konum, 5 sn) → vazgeçme. Hız 3,6 m/sn; oyuncu 3,0 yürür, 5,5 koşar. Kapıları açar (kilidi yok sayar), duvardan geçmez, ışınlanmaz, yakalayınca (1 m) ölüm.
- **Dayanıklılık:** oyuncu ~4,5 sn koşabilir, yorulunca 0,35'e dolana kadar koşamaz; ekranda sol altta ince çubuk. Böylece koşmak kaçış aracı ama sınırsız değil.
- **Senaryo:** kat anahtarını alınca (kontrol noktası kaydı) bakım odasının köşesinde Taklitçi uyanmadan belirir. Oyuncu odadan çıkınca 1,5 sn sonra (ya da 10 sn sonra) kovalamaca başlar. Kaçış: A Hattı tarafındaki **kepenk kolunu** çekmek; kepenk B↔A geçidini kapatır, yol ağı yeniden hesaplanır, Taklitçi dolaşmak zorunda kalır; kepenk inikken merdiven alanına ulaşınca (ya da Taklitçi aramayı bırakınca) kaçış tamamlanır.
- **Ölüm ve tekrar:** yakalanınca ekran kararır, kontrol noktası yüklenir (oyuncu dolabın başında), kovalamaca baştan başlar; sınırsız tekrar. F5/F9 artık konumu da kaydeder.
- **Adillik:** Taklitçi başta uyur; çıkış kapısı senaryoda zorla açık; koşan oyuncu kola vardığında Taklitçi testte 14 m geride; kepenk geçitteki oyuncuya inmez.
- **Bilinen sınırlar:** tipik kovalamaca ~25–35 sn (hedef 45–60 sn): oyuncu testi sonrası mesafe/hız ayarlanacak. Kepenk inerken yol ağı yeniden hesaplanır (~0,3 sn küçük takılma). Taklitçi şimdilik sadece Bölüm 2'de; merdiveni kullanmaz davranışı Aşama 12'de (Sayıcı) genişler.

## Bölüm 3: Personel Katı (Aşama 10)
Kod: `scripts/chapters/chapter3.gd`, işçi verisi `scripts/data/worker_data.gd` (11 işçi, tek yerde tutarlı).
- **Başlangıç:** üst kat merdivenine çıkınca Bölüm 3 başlar (kayıt alınır). Görevler: altı kimlik, revir dolabı, Yusuf'un kartı.
- **11 kimlik:** 6 zorunlu (ana rota) + 5 isteğe bağlı (gizli köşeler). Ana görev **herhangi altı** kimlikle biter; 11'i de toplanabilir ve kayda geçer (kritik eşya, kaybolmaz).
  - Soyunma dolapları: Hasan (1), Ayşe (2), Fatma (3); dolap 4–6 plakaları revir kodu ipucudur.
  - Yemekhane: çorba/sandalye olayı → Kemal; mutfak tezgâhı → Elif (isteğe bağlı).
  - Revir: ilaç dolabı (264) → Zeynep; yatak altı → Ramazan (isteğe bağlı).
  - Arşiv: çekmece → Mehmet; dosyalar → Nuray, Cemal, Hüseyin (isteğe bağlı).
- **Revir kodu 264 (üç ipucu):** (1) dolap notu: "son üç hastanın dolap numaraları, geliş sırasıyla"; (2) revir defteri: Ayşe, Kemal, Zeynep; (3) soyunma plakaları: Ayşe 2, Kemal 6, Zeynep 4 → 264.
- **Yemekhane:** çorba "hâlâ sıcak", sandalye geri çekilir, altında Kemal'in kimliği; yemekhaneye girince (Bölüm 3'te) kadın silueti olayı (`ev_cant_woman`).
- **Kilit:** altı kimlikle personel bürosunun üç kapısı açılır (`ch3_ids_done`).
- **Yusuf'un kartı ve sayım:** büroda kartı alınca Sayıcı 1'den 12'ye sayar; 12. satırda "On ikinci isim yazılı: Murat Demir." Bölüm 4'e geçiş ve kayıt.
- **Kapsam notu:** 8 işçinin "dosyası" şimdilik kısa biyografi (kimlik başına tek paragraf); uzun belgeler/ses Aşama 19'da (diyalog/belge/yerelleştirme).
