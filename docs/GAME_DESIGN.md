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
| 11 | Bölüm 4: CCTV ve delil zaman çizelgesi | ✅ otomatik testlerle doğrulandı; elle oynama bekliyor |
| 12 | Sayıcı AI ve saklanma | ✅ otomatik testlerle doğrulandı; elle oynama ve denge ayarı bekliyor |
| 13 | Bölüm 5: Gaz ve havalandırma | ✅ otomatik testlerle doğrulandı; elle oynama ve denge ayarı bekliyor |
| 14 | İki zaman durumu altyapısı (2026/2004) | ✅ otomatik testlerle doğrulandı; elle oynama bekliyor |
| 15 | Bölüm 6: 03.17 Vardiyası | ✅ otomatik testlerle doğrulandı; elle oynama bekliyor |
| 16+ | Bölümler 7–8, finaller, cila, build | ⏳ |

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

## Bölüm 4: CCTV ve delil zaman çizelgesi (Aşama 11)
Kod: `scripts/chapters/chapter4.gd`, `scripts/ui/cctv_ui.gd`, veri `scripts/data/cctv_data.gd`.
- **Monitör:** Kamera Odası'ndaki masada. Bölüm 3 bitince (Yusuf'un kartı) açılır. Arayüzde 6 kamera seçilir (Giriş, A/B/C Hattı, Kamera Odası, Bodrum Pompa); her biri sahneyi gerçekten görür (SubViewport; yalnızca seçili kamera çizilir). Kamera yeşili ton ve zaman damgası vardır.
- **Klipler:** "önceden kaydedilmiş" 7 klip, kısa sahnelemeyle (figürler yürür, altyazılı). 3 kritik: **03.14** (B Hattı, bakım iptali), **03.16** (Pompa, Selim vanaya uzanır, Yusuf durdurur), **03.17** (Giriş, anons, 11 işçi personel kapısına yürür). 4 yanıltıcı rutin klip.
- **İşaretleme:** oyuncu kritik üç klibi 03.14 → 03.16 → 03.17 sırasıyla işaretler. İzlemeden işaretlenmez; ilgisiz klip reddedilir; yanlış sırada işaretler sıfırlanır ve tekrar denenir. İlerleme kayıtla korunur.
- **Canlı kamera korkusu:** K5 (kamera odası) canlı izlenirken, en az bir kritik klip işaretlendiyse sandalyenin arkasında siluet + anons belirir (bir kez); ekran değişince siluet silinir, "Arkana bakıyorsun. Kimse yok."
- **Tamamlanınca:** USB belleğe kopyalanır, **Selim–Yusuf ses kaydı** (6 satır altyazı) çalar, görev güncellenir: "Bodruma in: kontrol odasındaki mühür panosunu bul"; Bölüm 5'e geçilir ve kayıt alınır.
- **Sınırlar:** klipler sahnelemedir (gerçek video yok); ses kaydı yalnızca altyazı + efekt (ses oyunculuğu yok); figürler düz silüet.

## Sayıcı AI ve saklanma (Aşama 12)
Kod: `scripts/enemy/sayici.gd` (ortak taban `enemy_base.gd`; Taklitçi de aynı tabanı kullanır), `scripts/chapters/sayici_controller.gd`, `scripts/interact/hide_spot.gd`.
- **Durumlar:** devriye → şüphe → arama → takip → saldırı. Devriye zemin kat odalarını dolaşır (Bölüm 5'te, oyuncu zemin kata inince, oyuncudan en uzak noktada belirir).
- **Sebepsiz bilmez:** yalnızca **görüş** (20 m, 110° koni, duvar/kapı/makine engeli; çömelen oyuncu makine arkasında görünmez; arkadaki oyuncu görünmez) ya da **ses** ile fark eder. Ses yarıçapları: çömelme 1,5 m, yürüme 4,5 m, koşu 11 m, kapı 6 m, radyo 16 m; duvar arkasında %60'a düşer. Şüphe kademeli artar (çömelen daha yavaş, koşan daha hızlı fark edilir); önce şüphe (durup bakar), sonra takip.
- **Arama:** son bilinen konuma gider, 8 sn arar, devriyeye döner. Görüş kesilince 3,5 sn sonra aramaya geçer.
- **Adil kaçış:** takip hızı 3,9 m/sn (yürüme 3,0 < Sayıcı < koşu 5,5; koşu dayanıklılığı sınırlı). Saldırı öncesi 0,7 sn uyarı: bu sürede uzaklaşan oyuncuya saldırı boşa gider. Yakalanınca ölüm → kontrol noktası; Sayıcı oyuncu zemin kata dönünce yeniden devriyeye başlar.
- **Saklanma:** 3 dolap (güvenlik kulübesi, A Hattı, C Hattı). Görülürken saklanılamaz. İçeride oyuncu görünmez ve ses çıkarmaz (E ile çıkılır; ekranda ince aralık). Sayıcı aramada yakındaysa dolabı olasılıkla (%50) kontrol eder ve bulursa takip eder.
- **Dikkat dağıtma:** 3 radyo (C Hattı, A Hattı, Bakım). Basınca 16 m'de gürültü; Sayıcı oraya gider. 12 sn bekleme.
- **Ses taklidi:** `ev_voice_mimic`: yalnızca Bölüm 5+, Sayıcı devriyedeyken ve oyuncuyu görmüyorken, oyunda bir kez; "Hakan'ın sesi: Murat? Buraya gel..." Sayıcı 6 sn pusuda bekler.
- **Debug:** **F6** (test modu) Sayıcı durumunu, şüpheyi ve son bilinen konumu ekranın sağ altında gösterir.
- **Düzeltmeler:** oyuncu sahneye artık başlangıç konumunda eklenir (önceden bir an orijinde belirip yanlış alan olayı tetikliyordu); koşu dayanıklılık çubuğu ekranda görünür hale getirildi (önceden ekran dışındaydı).
- **Sınırlar:** Sayıcı şimdilik düz silüet; Bölüm 5'in kendi bulmacaları (Aşama 13) yok, yani şu an Sayıcı'yı bodruma inmeye çalışırken deneyimlersiniz. Denge (hız, görüş, ses yarıçapları) elle oynayınca ayarlanacak.

## Bölüm 5: Gaz ve havalandırma (Aşama 13)
Kod: `scripts/chapters/chapter5.gd`. Ortak yardımcılar `chapter_base.gd` (saklanma dolabı artık burada), kovalamaca için `SayiciController.spawn_at`.
- **Gaz sistemi:** bodrum odaları gazlıdır (Area3D bölgeleri): boru 0,04 · fan odası 0,06 · pompa 0,07 · kontrol 0,09 · tünel 0,12 (saniyede zehirlenme, filtresizken). Fanlar çalışınca pompa ve kontrol odası temizlenir. **Gaz ölçer** (iniş masasında) ekranda gaz seviyesini gösterir. Ekranda filtre sayısı, takılı filtrenin süresi, zehirlenme yüzdesi ve "FİLTRE YOK — GAZDAN ÇIK" uyarısı vardır.
- **Filtre:** gazdayken otomatik takılır, 30 sn korur. Dünyada 7 filtre: yedek dolap 5 (en fazla 3 taşınır), boru kutusu 1, fan odası kutusu 1. Ana rota ≈ 60 sn gaz = 2 filtre → iki tam deneme + pay. Filtre biterken uyarı, bitince net mesaj; filtresiz kalınca zehirlenme %100'de bayılma → kontrol noktasına dönülür (kaynaklar kayıttan geri gelir: softlock yok). Hafif gaz tek geçişte filtresiz öldürmez.
- **Fan bulmacası F2 → F1 → F3:** iki ipucu: iniş masasındaki havalandırma kılavuzu ve pompadaki kazancı Hüseyin'in notu. Yanlış sırada sistem sıfırlanır ve ani gaz (+0,25; ölümcül değil, üst sınır 0,9) olur; sınırsız tekrar. Tamamlanınca kontrol noktası.
- **Sayıcı kovalamacası:** fanlar bitince pompa odasına girince Sayıcı bodrum merdiveninden iner ve kovalar. Kaçış: pompadaki **buhar vanası** (kapıda 12 sn buhar perdesi görüşü keser, hareketi engellemez; vision katmanı 16) + **saklanma dolapları** (pompa, kontrol). Sayıcı aramayı bırakınca geri çekilir. Yakalanınca fan kontrol noktasına dönülür, kovalamaca yeniden başlar.
- **Mühür panosu:** kontrol odasında. Fanlar + kovalamaca bitmeden ve Yusuf'un kartı olmadan çalışmaz. Kartla **Yusuf elektronik onayı** + **interkom kadın sesi** ("Sen on ikincisin"); Bölüm 6'ya geçiş ve kayıt. Kontrol odasına girince `ev_intercom` olayı da çalar.
- **Sınırlar:** gaz görseli yok (yalnızca ekran göstergesi ve uyarılar); buhar basit parçacık; ses oyunculuğu yok; Sayıcı'nın bodrum rotası tek senaryo (devriye bodrumda sürmez).

## İki zaman durumu: 2026 / 2004 (Aşama 14)
Kod: `scripts/world/time_layers.gd` (TimeLayers), `scripts/interact/card_reader.gd`; durum `GameManager.time_state` (kayıtta saklanır).
- **Ortak geometri:** duvar, zemin, tavan, rampa ve kapı konumları iki zamanda da aynıdır. Fark yalnızca katmanlardadır.
- **Katmanlar:** `TimeLayers.register(düğüm, durum)` bir düğümü yalnızca o zamanda var sayar (görünürlük + çarpışma + etkileşim). Işık/ortam: 2004 sıcak, parlak ve seyrek sisli; 2026 soğuk ve loş (geçişte birebir geri gelir). Kapı: `Door.only_in_state`. Eşya/etkileşim: `Interactable.time_state_required`. NPC: `spawn_npc` (2004'te çalışan işçi siluetleri). Duruma özel engel: 2026'da B Hattı'nda çökmüş tavan molozu (2004'te yok).
- **Kontrollü geçiş (kart okuyucu):** B Hattı kuzey duvarında. Bölüm 5 bitince (`ch5_done`) enerjilenir; Yusuf'un kartını okutunca 2026 ⇄ 2004 geçer. Enerji ya da kart yoksa çalışmaz; geçiş sırasında ve 3 sn bekleme süresinde tekrar basılamaz.
- **Güvenlik:** geçişte ekran kararır, durum değişir, oyuncu yeni katmanın engelinin içindeyse en yakın boş ve zeminli konuma taşınır (halka araması; yedek: son güvenli konum). Yüklemede kontrol noktası engel içindeyse de aynı düzeltme uygulanır. Geçiş sürerken kayıt kilitlidir (yarım durum yazılmaz).
- **Kayıt:** zaman durumu kayda yazılır; yeni sahne kayıtlı durumun katmanlarıyla açılır.
- **Bilinen sınırlar:** dünyada şimdilik yalnızca örnek katman içeriği var (moloz, 3 işçi, ışık); Bölüm 6–7 kendi 2004/2026 içeriğini bu sisteme kaydeder. Navigasyon ağı 2026 hâliyle üretilir (2004'te moloz yeri düşmanlar için kapalı kalır; zararsız).

## Bölüm 6: 03.17 Vardiyası (Aşama 15)
Kod: `scripts/chapters/chapter6.gd`, `scripts/ui/choice_ui.gd`; zaman altyapısı `time_layers.gd` (Aşama 14). Bölüm 5 bitince (mühür onayı) başlar; "[Anons] 03.17" ile B Hattı'ndaki kart okuyucu çalışır.
- **Bulmaca 1 (beton + 2004):** 2026'da Yükleme deposunun doğu ucu betonla örülü (kapsül geçemez). 2004'te beton yok; kart okuyucuyla 2004'e geçip depoya girilir. Duvardaki not 2004'e yönlendirir.
- **Bulmaca 2 (kod 041117):** 2004 deposundaki **vardiya terminali** "kapanış kayıt no 04-11-17 → 041117" gösterir (yalnızca 2004'te). 2026'da C Hattı'ndaki **vardiya dolabı** 6 haneli kod ister; etiket "şifre = depo kapanış kayıt numarası (altı hane), kayıt terminalinde" der. Yanlış kodda sınırsız tekrar. Açılınca **şalter kolu** (kritik eşya).
- **Bulmaca 3 (şalter panosu):** bakım odasındaki ana pano yalnızca 2004'te vardır; kol yoksa net mesaj. Kolla zaman bozulur (kontrol noktası alınır).
- **2004 atmosferi:** 2004'te üç makine de çalışır (parlar), makine sesi çalar, işçi siluetleri görünür; ışık sıcak.
- **11 işçi koridoru ve uzayan koridor kaçışı:** fabrika dışında 2004'e özel bir koridor. İki yanda 11 işçi oyuncuya döner. Oyuncuyu Sayıcı kovalar (hızı 2,8 m/sn: yürümeden yavaş; durmadan ilerleyen yakalanmaz, duran yakalanır). Eşiği geçen oyuncu ve Sayıcı bir periyot geri alınır: koridor 3 kez "uzar", sonra sona gidilir.
- **Yusuf telefonu:** koridor sonunda çalar; **iki seçenek** (anlatacağım / kimseye söylemeyeceğim). Seçim bir kez yapılır ve `ch6_choice` + `final_choice` bayraklarına yazılır (finale taşınır); ikinci cevap reddedilir, önceki bayraklar/envanter/ziyaretler değişmez.
- **Şalter sahnesi:** cevap verdikten sonra şalter indirilir; zaman durur, oyuncu bakım odasına 2026'da döner, Bölüm 7'ye geçilir ve kayıt alınır.
- **Ölüm/tekrar:** koridorda yakalanınca bakım odasındaki kontrol noktasına dönülür (kol kaybolmaz, zaman durumu tutarlı); panoya kol takılarak yeniden denenir.
- **Sınırlar:** Sayıcı dönüşten sonra fabrikada yine devriyeye çıkar (Bölüm 7'de de sürer); seçim penceresi ve koridor görseli sade; ses oyunculuğu yok.
