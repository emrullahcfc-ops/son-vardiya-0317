# SON VARDİYA: 03.17

Kurgusal, birinci şahıs, Türkçe endüstriyel korku oyunu. Godot 4.7 · GDScript · Windows.

> Hikâye ve karakterler tamamen kurgusaldır.

## Çalıştırma
1. Godot 4.7.x ile `project.godot` dosyasını aç, ya da: `godot --path .`
2. Kontroller: **WASD** hareket · **Shift** koş · **Ctrl** çömel · **E** etkileşim · **ESC** fare serbest · **F5/F9** kaydet/yükle · **F2/F3** alanlar arası ışınlanma · **F4** korku olaylarını oynat · **F6** düşman durumu (test modu) · koşu dayanıklılığı sınırlıdır

## Test
```
godot --headless --path . --import
godot --headless --path . --script tests/run_tests.gd
godot --headless --path . --script tests/run_factory_tests.gd
godot --headless --path . --script tests/run_horror_tests.gd
godot --headless --path . --script tests/run_chapter1_tests.gd
godot --headless --path . --script tests/run_chapter2_tests.gd
godot --headless --path . --script tests/run_chapter3_tests.gd
godot --headless --path . --script tests/run_chapter4_tests.gd
godot --headless --fixed-fps 60 --path . --script tests/run_enemy_tests.gd
godot --headless --fixed-fps 60 --path . --script tests/run_sayici_tests.gd
godot --headless --fixed-fps 60 --path . --script tests/run_chapter5_tests.gd
godot --headless --fixed-fps 60 --path . --script tests/run_time_tests.gd
godot --headless --fixed-fps 60 --path . --script tests/run_chapter6_tests.gd
```

Tasarım ve yol haritası: [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md)

## Ekran kartı notu
Bazı bilgisayarlarda Vulkan/Direct3D 12 sürücüsü Godot'u çökertebilir (boş bir Godot projesi bile). Böyle bir durumda oyunu OpenGL uyumluluk moduyla açın:
```
godot --path . --rendering-driver opengl3 --rendering-method gl_compatibility
```
