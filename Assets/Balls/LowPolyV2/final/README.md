# Ball Pack — Low Poly V2 (итоговый)

Десять low-poly мячей, которые стоят в игре Ball с 31.10.2026. Цвета хранятся в одном атласе 1024×1024 (`textures/atlas.png`). Это плоские плитки 16 px, затенение граней и свечение запечены прямо в цвет. Каждый мяч сделан одним мешем. Радиус тела около 1, центр мяча в начале координат, лицевая сторона смотрит на -Z (Y-up).

| # | Файл | Мяч в игре (id) | Треугольники |
|---|---|---|---:|
| 01 | `Ball_01_Rubber` | Rubber Ball (`Pebble`) | 1284 |
| 02 | `Ball_02_Classic` | Classic Ball (`Smooth`) | 2416 |
| 03 | `Ball_03_Beach` | Beach Ball (`Golden`) | 532 |
| 04 | `Ball_04_Basketball` | Basketball (`Ruby`) | 2474 |
| 05 | `Ball_05_Leather` | Leather Ball (`Emerald`) | 3736 |
| 06 | `Ball_06_Steel` | Steel Ball (`Galaxy`) | 1848 |
| 07 | `Ball_07_Gold` | Gold Ball (`Rainbow`) | 2464 |
| 08 | `Ball_08_Storm` | Storm Ball (`DragonSun`) | 6424 |
| 09 | `Ball_09_Volcano` | Volcano Ball (`BlackHole`) | 2062 |
| 10 | `Ball_10_Sun` | Sun Ball (`WorldCreator`) | 2968 |

## Состав

- `models/` — по каждому мячу `.glb` и `.fbx`; материал ссылается на атлас, а в `.fbx` атлас встроен. Подходит для Blender, Studio 3D Importer и любого просмотрщика.
- `textures/atlas.png` — общий атлас цветов.
- `roblox/balls-roblox.glb` — все 10 мешей одним файлом без материалов, в том виде, в каком их загружали в Roblox. `manifest.json` содержит габариты, `roblox-ids.json` — ID ассетов:
  - Model `72414326263846`;
  - атлас Image `125793810196493`;
  - MeshId каждого мяча.

  Владелец ассетов — 11789507527. У игры (universe `10770268214`) есть право Use.
- `previews/` — рендеры:
  - `review_XX` — каждый мяч спереди;
  - `turntable_*` — пять ракурсов;
  - `compare_*` — сравнение с референсом;
  - `overview` — весь пак.
- `source/` — сцена Blender `ball-pack-low-poly-v2.blend` и скрипты сборки, рендера и экспорта. Порядок работы описан в README рабочей папки `Assets/Balls/LowPolyV2/`.

В Studio: Roblox при импорте `.glb` поворачивает модель на 180° вокруг Y. Если важна лицевая сторона, разверните её обратно. Чтобы текстура легла правильно, у MeshPart нужен белый Color.
