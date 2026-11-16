# SON VARDİYA: 03.17 — proje kuralları

Türkçe, birinci şahıs 3D, 8 bölümlü KURGUSAL endüstriyel korku oyunu. Godot 4.7 + GDScript, Windows PC, tek oyunculu, Steam hedefli.
Hikâye tamamen kurgusaldır; gerçek vakaymış gibi pazarlanmaz.

## Çalışma kuralları
1. Önce mevcut yapıyı incele; aynı işi yapan ikinci bir sistem yazma.
2. Yalnızca istenen aşamayı uygula; büyük refaktör ve kapsam dışı özellik ekleme.
3. Olaylar sinyallerle ilerler. İlerleme tekil ID + bayraklarla (`GameManager.flags`) saklanır.
4. Kritik görev eşyaları kaybolamaz; bulmacalar sıfırlanabilir; softlock olmaz (kapı/geçişte sıkışma yok).
5. Her etkileşimde başarı, hata ve tekrar deneme durumu olur. Metinler Türkçe, altyazılı.
6. Eksik model/ses için telif açısından güvenli geçici varlık (gri kutu, sentetik ses) kullan.
7. Her aşama sonunda testleri GERÇEKTEN çalıştır, sonucu dürüstçe bildir; çalıştıramadıysan söyle.
8. Kabul edilen her aşama ayrı Git commit'i. Kullanıcı değişikliklerine dokunma.

## Testler
```
godot --headless --path . --import
godot --headless --path . --script tests/run_tests.gd
godot --headless --path . --script tests/run_factory_tests.gd
godot --headless --path . --script tests/run_horror_tests.gd
godot --headless --path . --script tests/run_chapter1_tests.gd
godot --headless --path . --script tests/run_chapter2_tests.gd
godot --headless --fixed-fps 60 --path . --script tests/run_enemy_tests.gd
```
Godot: `Godot_v4.7.2-stable_win64_console.exe` (winget ile kurulu).

## Mimari
- Autoload: GameManager, SaveManager, QuestManager, InventoryManager, AudioManager, HorrorDirector (`scripts/autoload/`).
- Korku: `HorrorDirector` karar verir, `scripts/horror/horror_effects.gd` uygular; sesler `AudioManager`da sentezlenir.
- Bölümler: `scripts/chapters/` (`ChapterBase` ortak yardımcılar, `Chapter1`, `Chapter2`). Kapı kilitleri `FactoryLayout.DOORS` içinde `req_item`/`req_flag`.
- Düşman: `scripts/enemy/mimic.gd` (NavigationAgent3D; yol ağı `factory.gd` içinde koddan bake edilir, kepenk inince yeniden). `scripts/world/shutter.gd`.
- Oyuncu: `scenes/player/player.tscn`, `scripts/player/player.gd`.
- Etkileşim: `Interactable` tabanı → `Door`, `Pickup`, `Document` (`scripts/interact/`).
- Kayıt: `user://savegame.json` (+ `.bak`). F5 kaydet, F9 yükle (test sahnesinde).

## Aşama durumu
Bkz. docs/GAME_DESIGN.md → "Yol haritası".
