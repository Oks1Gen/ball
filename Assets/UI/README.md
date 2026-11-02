# Итоговые UI-ассеты

32 иконки созданы встроенным ImageGen **отдельными запросами**, по одному
предмету на прозрачном фоне. Каждый PNG — самостоятельное изображение
512×512; уменьшен весь исходный холст, без обрезки или нарезки.

Стиль: насыщенные контрастные цвета, толстая чёрная обводка, простая
мультяшная заливка, минимум бликов. Shop и Rebirth используют яркую фуксию
и голубой. Robux — белый знак с чёрной обводкой по образцу пользователя.
Камни в Trail-иконках заменены футбольными мячами.

`studs.png` — точная копия предоставленного пользователем файла
`RobloxGames/Assets/ui/studstandalone.png` (420×420), без изменения рисунка.
`burst.png` — отдельная прозрачная текстура лучей карточек наград, сохранена
из предыдущей реализации; это фон, не иконка и не фрагмент атласа.

- `prompts.json`: отдельный промпт и путь исходной генерации каждой иконки.
- `verification.json`: размеры, границы непрозрачной области и проверка краёв.
- `roblox-assets.json`: загруженные Roblox Image asset IDs.

Игра использует целые изображения, без ImageRectOffset/ImageRectSize.
Старые атласы сохранены в резервном Git-коммите `a010fd2`; из рабочего дерева удалены.

`update-log.png` — отдельная иконка журнала обновлений, созданная встроенным
ImageGen 29.10.2026: голубой планшет с жёлтым зажимом и листом новостей.
Сохранён исходный прозрачный PNG 1254×1254, без обрезки; подробности и точный
промпт — `update-log.asset.json` и `prompts.json`. Roblox Image:
`106721086001751`. Используется в верхней панели и углу окна Update Log.

`sunburst.png` — исходная текстура пользователя, скопирована без изменений из
`RobloxGames/Assets/Textures/sunburst.png`; лучи Starter Pack.
Roblox Image `100836241976168`, источник — `sunburst.asset.json`.

## Карточки питомцев

Текущий набор — 16 отдельных PNG в `Pets/individual-v3/`, без атласа и нарезки.
Каждая иконка создана отдельным запросом ImageGen и хранит исходный alpha-канал.
`individual-v3-generation.json` содержит промпты,
`individual-v3-verification.json` — проверку размеров и прозрачности,
`individual-v3-roblox-assets.json` — Image ID. `Modules/PetCardArt.luau`
подключает изображения целиком; английские подписи выводятся живым текстом.

Заменённые атласы v1/v2 с метаданными сохранены в Git-коммите `a010fd2`,
из текущего дерева удалены 03.11.2026. Их ID — 123833931134956 и 86854425517241.

## Training Boost bubbles

`training-boost.asset.json` documents the native Roblox UI asset. Its reusable
React component is `RojoTest/src/client/Controllers/TrainingBoostBubble.luau`.
It uses the existing studs and Robux textures, five gradients and a rainbow
gradient with live outlined text. No new bitmap or Image asset upload is needed.
