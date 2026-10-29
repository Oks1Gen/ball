# Модуль DirectionGuide

Самостоятельный клиентский ModuleScript: `RojoTest/src/shared/DirectionGuide.luau`.
Не зависит от GameConfig, UI, профиля или этапов обучения. Для переноса в другую
игру достаточно скопировать один файл в ReplicatedStorage.

```lua
local DirectionGuide = require(game.ReplicatedStorage.Shared.DirectionGuide)
local guide = DirectionGuide.new({ target = workspace.QuestTarget })
-- По умолчанию начало следует за персонажем, движение обновляется автоматически.
guide:setTarget(workspace.NextTarget)
guide:setReducedMotion(true)
guide:setEnabled(false)
guide:destroy()
```

`source` и `target` принимают Vector3, BasePart, Model, Attachment или функцию,
возвращающую такой объект/позицию. Функция может вернуть nil, пока объект не
загружен. Удалённые объекты и пустая цель скрывают стрелки. Модель использует
Pivot, Attachment — WorldPosition. Начало по умолчанию переживает respawn.
`setSource(nil)` скрывает путь; для возврата к персонажу передай callback.

Параметры `new`: name, parent (по умолчанию workspace), source, target,
automatic (true), enabled (true), reducedMotion (false), texture,
width (2), spacing (3.3), speed (1.5 цикла/с), minDistance (4), startOffset (2.5),
outlineWidth (0.4), color (белый), outlineColor (чёрный).

В своём RenderStepped укажи `automatic = false` и вызывай
`guide:update(os.clock(), reducedMotion)` после изменения source/target.
При скрытии подсказки вызывай setEnabled(false), при завершении — destroy().
Не запускай автоматическое и ручное обновление одновременно.

Внешний вид сохранён: готовая Roblox-текстура 5886559421, стандартные Beam,
движущиеся белые стрелки с чёрной обводкой. Ресурсы локальные и без коллизий.
Модуль показывает прямое направление; обход стен и pathfinding не выполняет.
Последовательность и успех действий определяются вызывающим кодом/сервером.
Текущий Controllers/Tutorial использует этот модуль в ручном режиме.

Навык `$roblox-direction-guide` содержит переносимую копию модуля и инструкции.
Канонический исходник этой игры — файл в src/shared; после изменения визуального
контракта обновляй копию assets/DirectionGuide.luau в установленном навыке.

Проверка в Studio Play: смена координат и callback-цели, nil/удалённая/близкая
цель, ручное и автоматическое обновление, отключение, повторный destroy и
отсутствие оставшихся объектов. Полный check.mjs и проверка навыка прошли.
