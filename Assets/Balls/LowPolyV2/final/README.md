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

## Состав после очистки 03.11.2026

- `models/` — отдельные GLB и FBX каждого мяча; встроенные текстуры сохранены.
- `roblox/roblox-ids.json` — сведения о загруженных ассетах.
- Общий GLB, атлас и manifest — в `../roblox/`.
- Рендеры — в `../previews/`, исходная сцена и скрипты — в родительской папке.

Дубли исходников и рендеров удалены. Полная прежняя поставка доступна
в резервном Git-коммите `a010fd2`. Старый `source/make_templates.py`
также удалён: актуальная версия лежит в `../make_templates.py` и использует FitSize.
