# Проверки проекта

## Robux catalog, shop and full Dev reset — 2026-11-06

Created and read back 4 Game Passes and 8 Developer Products for universe
10770268214, including base prices and uploaded existing UI icons. All are off
sale pending a separately authorized publication of the new handlers.
Runtime IDs also match MarketplaceService engine readback.
See [monetization.md](monetization.md) for the catalog and deployment boundary.

The full project gate passed: 132 Lune tests, 5 verification-tool tests, StyLua,
Selene, Rojo build, requires, ProfileStore routing/integrity and zero Luau type
errors. In Studio, 71 isolated receipt checks covered all products, repeated
receipts, failed profile saves, archive read/write failures, full pet storage,
paid charges and interrupted/busy paid rebirth. Nine additional isolated checks
covered Dev Reset, failed-save rollback, receipt locking and stale ownership
requests. These fixtures never wrote the actual player's profile or made a paid
purchase. Real ownership queries restored the current player's permanent passes;
Starter Pack's 10K Wins did not repeat on a subsequent Play start.

PC Play showed the shop, its Owned/Off Sale states and all offers reachable by
scrolling. All six HUD price/status rows fit their labels; the shop contains 12
offers. Update Log opened and closed, its new entry expanded to 130 px of details
with Dakemo555's name/avatar and collapsed to 0 px; list scrolling worked.
Player purchase policy loaded. Native paid checkout, its cancellation,
real receipt persistence and production grants remain untested until deployment.
No mobile tests, public publication or real paid purchases were performed.

During the task, rclone moved 7 working files to conflict copies. Every pair was
diffed: conflict1 contained the current reset/commerce changes, conflict2 their
earlier versions. The missing originals were restored from conflict1, verified
byte-for-byte, and the complete gate passed again. All 14 conflict copies remain
untouched; no backup deletion or commit/push was performed.

## Training boosts, character races and sync conflicts — 2026-11-05

Local fixes split the active training boost from a queued free offer. The first
contact activates the queued offer without consuming another paid charge; queued
acknowledgements no longer clear the client's current boosted-cycle visuals.
Stopping/restarting training clears both transient states. Character callbacks
check both character and session identity before work, after each wait, and on death.

Validation: complete check.mjs passed with 126 Lune tests, five gate tests, clean
StyLua/Selene, Rojo build/sourcemap and zero type diagnostics. An isolated Studio
Edit invocation loaded the updated on-disk sources into mock contexts: remaining
paid rewards stayed 14,400 before/after a free claim, the next cycle received 9.3x,
and the spare paid charge was preserved. VerifySessionCharacter passed eight
isolated assertions with the updated source; the stale Studio source reproduced
the original failure after HumanoidRootPart wait. No actual profile or scene changed.

After the user accepted Rojo Connect, source markers confirmed both fixes arrived
through Rojo. VerifySessionCharacter passed all eight assertions against the synced
Studio source. Fresh PC Play ran VerifyTrainingBoost with isolated contexts: 505
checks passed on all 14 lanes and three receipt fixtures. No real purchase or charge
was created. A normal character death produced a different healthy character,
SpawnReady=true, Health=100 and the configured WalkSpeed=24.

Client Play confirmed Dakemo555 / 11789507527. The current unpublished v0.4.0 entry
was updated in place, retaining five highlights. PC QA used the real HudPanels and
UpdateLogView with an isolated UI context because the real HUD had a pending offline
reward. Mouse input opened/expanded/collapsed/closed the window and scrolled its list
300 pixels. The new details fit, and the author avatar loaded. The temporary UI was
destroyed and the real HUD restored; no offline reward or daily gift was claimed.
The final full gate passed again, including 126 unit tests and zero type errors.

All 42 visible sync conflicts were reviewed: 14 identical, 28 older different
copies across 19 originals. Keep current originals (final rigs, 2x fish, atmosphere,
safe school envelopes and full release history). Verified byte-for-byte backup:
Assets/OceanDepths/ConflictRecovery/2026-11-05-sync-conflicts.zip (1,546,942 bytes),
with SHA-256 inventory. The user authorized the separate backup commit/push;
f8ba402 reached origin/main and its LFS object uploaded successfully before the
42 exact deletions. All 19 originals remained unchanged by deletion. Decisions:
docs/audits/sync-conflicts-2026-11-05.md. No visible conflict copies remain.
Only the recovery ZIP was committed/pushed; gameplay fixes remain local.
No game publication or mobile test performed. Studio returned to Edit after QA.

## HD Studs MaterialVariant в Lobby World1 — 05.11.2026

- Studio MCP, Edit-превью. 9 872 детали с материалом, 0 старых HD Studs Texture в Lobby. Проверены дорожка с углами, шахматные стены и террасы, газон, стенд яиц и общий вид.
- Сравнение сцены до/после показало 0 изменений геометрии, цвета и физики BasePart, 0 изменений MaterialVariant вне Lobby.
- `node RojoTest/tools/check.mjs` прошёл, включая 123 Lune-теста, сборку и проверку типов. Постоянный startup-перенос не включён. Детали теста — [hd-studs.md](hd-studs.md).

## Стенды рейтингов по референсу и рейтинг доната — 04.11.2026

- `node RojoTest/tools/check.mjs`: StyLua, Selene, Lune-тесты (включая
  Update Log), 5 тестов verification gate, Rojo build/sourcemap, 214 require
  и проверка типов прошли; новых диагностик типов — 0.
- Studio MCP, Edit: четыре стенда собраны стилем 9 (по поправкам: короткие
  ножки у краёв на общем основании, скруглённые углы, без эмблемы сверху,
  иконка в шапке слева от названия). Сделаны снимки спереди, от игрока,
  вблизи, сбоку и шапки. Строки, медали, аватары и длинные числа (до 985,000,000)
  проверены на временных данных; строки затем очищены. Качество рендера
  возвращено в Automatic. Проверки стенда «ДОНАТ» из `VerifyMapReadability` и
  ролей прозрачных деталей из `VerifyWorldLayout` прошли в Edit.
- Studio MCP, два запуска Play. Первый показал два дефекта, оба исправлены:
  - журнал WorldLayout возвращал в стенды скрытую старую `Frame`;
  - передний край 251.9 сдвигал `EggPlaza` на клетку.
- Второй запуск Play и повторный для стиля 9: в стендах только новые детали
  (`BodyRim`, `Body`, `Panel`, `HeaderRim`, `Header`, `HeaderSurface`, `Stand`),
  `EggPlaza` в `HubLayout` совпадает с Edit, текущий игрок Dakemo555 с
  аватаром в Skill/Wins/Best Throw, «ДОНАТ» пуст при нуле. На первом снимке
  сразу после старта шрифт заголовков ещё догружался; на повторном названия
  целые. В Output нет ошибок, только прежние предупреждения
  об ассете 203785492 и SurfaceSeparation (778, стенды в счёт не входят).
- Начисление `donated` реальной покупкой не проверялось: ID продуктов равны
  нулю. Мобильная проверка, коммит и публикация не выполнялись.

## Персонаж и пол перед остальными ассетами — 03.11.2026

- `node RojoTest/tools/check.mjs`: StyLua, Selene, 110 Lune-тестов,
  5 тестов verification gate, Rojo build/sourcemap и проверка типов прошли;
  новых, известных и устаревших диагностик типов — 0.
- Studio MCP, два свежих запуска Play на ПК: `SpawnPositioned=true`,
  `SpawnReady=true`, корень освобождён, интро закрыто, под персонажем клиентский
  raycast находит `World1/Lobby/KickZone/KickZoneFloor`.
- Обычная смерть и респавн: 12 секунд наблюдения, 1400 кадров,
  ни одного кадра с незакреплённым персонажем без поверхности под ним;
  минимальная Y корня 23.527. Подтверждение готовности получено повторно.
- Пустой, строковый, чужой Instance и лишний аргумент в подтверждении спавна
  не вызвали ошибок сервера. После увеличения ожидания сервиса до 60 секунд
  предупреждения Infinite yield больше нет. Старые предупреждения плагина
  Rojo о звуке 203785492 и SurfaceSeparation остаются вне этой правки.
- Новая запись Update Log с автором Dakemo555 проверена в клиентском
  UpdateLogView: краткий текст, подробности и подпись помещаются. Временный
  экран проверки удалён, Play остановлен. Полный интерактивный прогон
  оболочки журнала повторно не выполнялся: её код не изменялся.
- Численное ускорение на холодном live-клиенте и медленной сети не измерялось.
  Мобильная проверка и публикация не выполнялись.

## Уборка декора и центрирование Hub — 03.11.2026

- Удалены 582 детали декора (включая 93 скрытых оригинала), пустые исходные
  LobbyGardens/LobbyAccents возвращены в ServerStorage. Стены, обе системы
  водопадов, станции и физический пол сохранены.
- Hub, спавн и подход к мячам: Z=204.449356, как фиксированная середина стенда.
  VerifyLobbyHub в Edit/Server: 204 клетки, 43 части обводки, 848 проб,
  восемь связанных групп. Подход и BallCourt центрированы с допуском 0.001.
- VerifyLobbyComposition в Edit/Server: 9 непересекающихся габаритов зон,
  4 свободных центральных маршрута, 342 пробы пола/высоты. Декор отсутствует;
  повторные apply ничего не меняют. Обычный startup проходит.
- Аудиты стен, верхнего яруса и водопадов проходят; параметры не менялись.
  Описание, границы проверок и сохранность — [lobby-composition.md](lobby-composition.md).
- Граф контактов: 11417 деталей, 0 оторванных компонентов. Структура мира
  проходит в Edit и Server; персонаж проходит к подходу мячей и обратно.
- check.mjs: 110 Lune, 5 Node и остальные этапы проходят. Новый текст
  Update Log и автор Dakemo555 проверены на ПК вместе с раскрытием,
  сворачиванием, прокруткой и повторным открытием. Телефон не проверялся.

## Полное покрытие газона — 03.11.2026

- LobbyLawn: 812 полных клеток 6.4, непрерывная сетка под дорожками и
  площадками, без LawnEdge; studs шага 1.6. Старые Texture 8 и offset 4 удалены.
  210 физических плиток сохраняют геометрию и физику. Kick Zone выровнена
  на 0.084 по X с осью поля; размеры и передняя граница сохранены.
- Edit и обычный Server Play: VerifyLobbyLawn, 4060 проб опоры.
  Независимая проверка разностей площадей — в пределах Float32;
  конкретные результаты и допуски: [lobby-lawn.md](lobby-lawn.md).
  Повторный apply: rebuilt=false, 812 клеток, 812 частей.
- VerifyLobbyHub: 217 клеток дорожек, 846 проб, 54 клетки Kick Zone,
  8 связанных групп. VerifyWorldLayout: 1 мир, 8 полей, 10 мячей,
  7 тренировок и 4 обычных яйца. Движения станций и стен не требовалось.
- 3 новых теста SurfaceGrid.partition; check.mjs: 110 Lune, 5 Node,
  StyLua, Selene, Rojo build и Luau types проходят.
- Update Log: пункт lobby-walls дополнен газоном, автор Dakemo555.
  Текст и автор, раскрытие/сворачивание, прокрутка, закрытие/открытие
  проверены на ПК. Временный GUI удалён; мобильный UI не проверялся.

## Отступ верхнего яруса — 03.11.2026

- Верхний ярус отступает наружу на 6.4, оставляя полку шириной 4 шага studs.
  Измерение совпадает с предыдущим верхним шагом; высота и масштаб текстур
  не менялись. Проверены боковой профиль, угол, вид игрока и оба водопада.
- Edit/Server Play: 8175 клеток, 137 зелёных накладок, 117 краевых деталей,
  82 непустые плоскости, 8429 проб облицовки и 3468 проверок опоры верхних
  блоков. Профиль проверяется относительно фактических нижних крышек,
  новые стены не висят за пределами их объединения.
- Верхние точки водопадов следуют новому краю; верхние ручьи укорочены,
  дальний источник и нижние бассейны остаются на месте. Повторный apply:
  rebuilt=false, added=0, changed=0, removedDecor=0. Отступ не накапливается.
- Полный check.mjs: 107 Lune, 5 Node, сборка, формат, lint и типы проходят.
  Первоначальное замечание анализатора к присваиванию нового ObjectValue
  устранено типизированной ссылкой и отдельной переменной создания.

## Целые края studs и четвёртый ярус стен — 03.11.2026

- Сами стены и зелёные крышки подогнаны под сетку; открытые поверхности
  полностью покрыты studs, включая горизонтальные края и вертикальные
  зелёные торцы. Проверка площади не допускает гладких остатков. Проверка
  наложений теперь охватывает плоскости разных объектов, в том числе вход.
- Edit/Server Play: 8191 клетка, 128 зелёных накладок, 117 краевых деталей,
  66 непустых плоскостей, 128 источников, 8436 проб опоры.
- Верхний ярус — 16, верх Y≈85.72, 34 новые исходные части. Оба водопада
  начинаются у нового верха и заканчиваются в прежних бассейнах. Повторный
  apply не меняет размеры и не добавляет детали. Отдельный читающий аудит:
  VerifyLobbyWallGeometry.
- Снимок до/после: изменены только 106 исходных частей стен, связанных
  коллизий опор и верхних частей водопадов; 15289 остальных сохранены.
  Флаги физики и видимость исходных частей не менялись. Клетки облицовки
  заменены. Дорожки, Kick Zone, станции, новые яйца и стенд сохранены.
- VerifyLobbyHub: 217 клеток дорожек, 846 проб, 54 клетки Kick Zone,
  8 связанных групп. VerifyWorldLayout: 1 мир, 8 полей, 10 мячей,
  7 тренировок, 4 обычных яйца. Декор террас не возвращается.
- Update Log: текущий пункт переписан по итоговому результату с автором
  Dakemo555. На ПК раскрытие/сворачивание, текст, аватар, прокрутка 814,
  закрытие и повторное открытие прошли; временный GUI удалён.
- check.mjs: 107 Lune, 5 Node, StyLua, Selene, Rojo build, requires,
  Luau types без ошибок. Прежние предупреждения про ассет 203785492
  и безопасный пропуск SurfaceSeparation остаются вне этой правки.

## Стены и удаление декора — повторная правка 03.11.2026

- Удалены конфликтующие старые накладки входа из FootballCourse/Zone01.
  Снимок до правки воспроизводит двоение. Снимки после: ровные целые studs
  на входе, наружной боковой стене и внутреннем углу; общий вид без декора
  на террасах, с сохранёнными водопадами и новыми яйцами.
- Edit/Server Play: 6005 клеток, 48 плоскостей, 6117 проб опоры; новые
  краевые ряды проверяются на полноту. Повторный apply: rebuilt=false,
  removedDecor=0. После штатного запуска план декора пуст, старых слоёв нет.
- Снимок до/после: 15395 оставшихся исходных частей без изменений CFrame,
  Size, видимости и физики. Удалено 4005 косметических частей старой
  облицовки и декора, включая последние 12 перенесённых моделей цветов.
  Все удалённые части косметические; оба водопада без изменений потомков.
- VerifyWorldLayout: 1 мир, 8 полей, 10 мячей, 7 тренировок, 4 обычных яйца.
- Update Log: текущий пункт стен — Dakemo555, ник подтверждён пользователем.
  ПК: раскрытие/сворачивание, аватар, вместимость текста, прокрутка 796,
  закрытие и повторное открытие. Временный GUI удалён.
- В штатном Play есть прежние сообщения ContentId 203785492 (неверный тип
  ассета) и безопасный пропуск SurfaceSeparation при изменении авторских
  частей. Новых ошибок стен/декора не обнаружено. Телефон не проверялся.

## Первый проход шахматки стен — 03.11.2026 (заменён повторной правкой выше)

- Новый контракт: [lobby-walls.md](lobby-walls.md). Edit и Server Play:
  2873 полные клетки, 35 деталей зелёного верха, 32 плоскости и 2908 проб опоры.
  Нет обрезанных клеток, двойных слоёв, дробных рядов или копланарных накладок.
  Кромки оставлены гладкими, цвет основы одинаков со светлой клеткой.
- Узкий apply сохранил геометрию/физику/видимость 18860 оставшихся частей,
  физических удалений нет; повторный apply не перестраивает сетку.
  Обычный startup сохраняет результат, сервер/клиент без ошибок игрового кода.
- 5 новых Lune-проверок SurfaceGrid; полный набор — 107 Lune и 5 Node.
  VerifyLobbyHub и VerifyWorldLayout.run проходят. Пункт lobby-walls добавлен
  в текущий неопубликованный 0.2.1, интерфейс журнала проверен на ПК.
- Временный UI-harness сначала проверял устаревшую позицию кнопки после
  прокрутки; повтор с фактическими координатами прошёл. Код UI не менялся.

## Kick Zone без выступающей основы — 03.11.2026

- Контур основы выровнен с панелью: 89.6×9.6, 54 клетки 3.2×3.2,
  кант 1.6. Убраны разные жёлтые поля снаружи обводки и зазор под панелью.
  Сохранены фронт у поля (Z=124), arenaFrame, высота пола и физические флаги.
- VerifyLobbyHub в Edit и Server Play: 54 клетки, 4 полосы канта, 846 проб
  сети. Дополнительно проверено совпадение всех четырёх краёв основы и панели.
  VerifyKickZone — 68 проверок удара и границ. Startup сохраняет новый контур;
  ошибок сервера и клиента нет. За пределами Paths/KickZone сохранена 19861 часть.
- Полный check.mjs: 102 Lune, 5 Node, форматирование, lint, Rojo build,
  requires и Luau types — пройдены, 0 диагностик. Update Log дополнен в том же
  неопубликованном пункте; открытие, раскрытие/сворачивание, автор, читаемость,
  прокрутка и повторное открытие проверены на ПК, временный GUI удалён.
- Прежний результат ниже описывает вариант до выравнивания основы.

## Kick Zone: имя и цельное покрытие — 03.11.2026

Полный результат — [kick-zone.md](kick-zone.md). Edit и Server Play:
52 целые клетки, 4 полосы канта; 846 проб сети лобби. VerifyKickZone —
68 проверок начала удара и границ без изменения сохранённых профилей.
Физическая площадка сохранена; старых имён зоны в рабочей сцене нет,
журнал WorldLayout восстанавливает новые имена. VerifyWorldLayout.run прошёл;
ошибок сервера/клиента нет. Полный check.mjs — 102 Lune, 5 Node и остальные
проверки пройдены, Luau types — 0 диагностик. Update Log проверен на ПК.

## Увеличенные studs дорожек — 03.11.2026

- `LobbyPaths` grid-8 / `PathGridVersion=2`: studs и наружный кант увеличены
  с 0.8 до 1.6 stud, Texture 6.4; квадрат 6.4×6.4 теперь содержит 4×4 studs.
- Узкий apply со свежими зависимостями сохранил размеры и позиции всех 217
  checker-квадратов и CFrame/Size/видимость/физические флаги 19905 частей
  вне Lobby.Paths. Повторный apply — 0. Вся карта вручную не перестраивалась.
- `VerifyLobbyHub` прошёл в Edit и обычном Server Play: 240 поверхностей,
  43 детали канта, 845 проб, 8 связанных групп. Проверены новая кратность
  размеров, Texture 6.4, нулевые UV offsets, отсутствие накладок/ступенек.
- Снимки Studio сверху, с высоты игрока и крупно на углах: studs крупнее,
  целые ряды на канте, размеры шахматных клеток прежние. Рубрика 5/5:
  масштаб, клетки, прямые края, оба типа углов, стыки.
- Полный `node RojoTest/tools/check.mjs` пройден: 102 Lune, 5 Node,
  StyLua, Selene, Rojo build, requires и Luau types — 0 диагностик.
- В существующем неопубликованном 0.2.1 уточнён пункт lobby-paths:
  larger studs / wider single border. Игра не публиковалась.
- На ПК отдельный canvas HudPanels проверил открытие/повторное открытие,
  раскрытие/сворачивание реальным кликом MCP, читаемость описания, автора
  и прокрутку. Harness использует ZIndexBehavior.Sibling, как основной HUD;
  ошибочная первоначальная настройка harness не меняла код игры.
  Временные GUI удалены, прочие GUI восстановлены; Play остановлен,
  камера и качество Edit восстановлены.

## Ровная сетка дорожек и анимированные стрелки — 03.11.2026

- `VerifyLobbyHub` в Edit и Server Play: 240 деталей покрытия (217 цельных
  checker-квадратов 6.4×6.4 и 23 однотонных участка), 43 детали единого канта.
  Нет копланарных перекрытий, частичных checker-клеток и дробных рядов studs;
  UV offsets нулевые. Соединены все 8 групп, 845 проб мощения/физической опоры
  проходят. Пробы на точных Float32-швах имеют допуск 0.001 stud.
- Геометрия шевронов проверена по реальным шести вершинам каждого клина,
  а не по завышенному bounding box: видимые части не выходят за края пути.
  Вычисленная скорость 2.56 stud/s; Client за 0.9995 s измерил 2.558 stud.
  Уточнённый контур GeometryVersion2 повторно проверен в Edit/Server Play,
  клиент подтвердил движение. На сервере и клиенте ошибок нет.
- После переподключения Studio узкий apply сохранил CFrame/Size/видимость/
  физические флаги 19905 деталей вне Lobby.Paths. Старые строители и
  WorldLayout.prepare вручную не запускались. Повторный apply возвращает 0.
- Полный `node RojoTest/tools/check.mjs`: 102 Lune, 5 Node, StyLua, Selene,
  Rojo build, requires и Luau types — пройдены, 0 диагностик.
- Update Log: дополнен существующий неопубликованный 0.2.1, четыре итоговых
  пункта. На ПК проверены открытие, раскрытие/сворачивание реальным MCP-кликом,
  автор, читаемость подробностей, прокрутка, закрытие и повторное открытие
  на отдельном canvas через действующие HudPanels/UpdateLogView.
- Независимый visual-critic: 6/6 после исправления срезов шеврона.
  Снимки: `.tools/lobby-path-grid-2026-11-03/`, итог стрелок `arrows-final.png`.
  Ранние `arrows-1/2` показывают прежний контур, который заменён.

Play остановлен; временные GUI, калибровочные полосы и локальный HTTP-сервер
убраны. Качество рендера возвращено к обычному. Мобильные проверки,
публикация игры, commit и push не выполнялись. Сцену нужно сохранить в Studio.


## Равные отступы и уборка лобби — 03.11.2026

Текущее состояние после уточнения пользователя; заменяет прежнее решение
с отдельным подъёмом заднего ряда и неподвижными карточками.

- `VerifyMapReadability`: 10 подписей, 4 подхода, 73 положения за полный оборот
  (22.5 s и девять bob-циклов); 0 пересечений GUI/GUI и GUI/мячи, одинаковый
  видимый зазор и центровка над своим мячом. Client Play: 18 измерений за
  полный bob-цикл подтверждают реальный зазор и одинаковые TextBounds.
- `VerifyLobbySceneCleanup`: Edit и обычный Server Play — 7585 деталей в графе
  OBB-контактов, 0 оторванных групп. Повторный plan: 0 неподдержанных/пересекающихся
  цветов, 0 изменений сундука, 0 удалений и 0 восстановлений лепестков.
  Исправлена посадка 279 цветов; устранено пересечение сундука со стойкой;
  удалены подвеска без крепления, отдельный лепесток и скрытый оригинал.
- `VerifyWorldLayout.run` в Server Play: 1 мир, 8 полей, 10 слотов, 7 тренировок,
  4 обычных яйца. `TransparentCleanup.plan` в Edit: 0 кандидатов.
- Snapshot сравнивает CFrame/Size/физические флаги всех сохранившихся физических
  деталей; отдельно защищены геометрия/видимость яиц, рейтингов, курса и тренировок.
  Собственные изменения прохода не затрагивают эти объекты.
- Обычный startup сохраняет исправленную сцену. В новом Play нет ошибок
  игрового кода на сервере и клиенте. Временные камеры/GUI удалены, качество
  рендера восстановлено; Play остановлен.
- Update Log: дополнен текущий неопубликованный 0.2.1, автор Ball team.
  На ПК проверены открытие/закрытие и повторное открытие через HudPanels,
  раскрытие/сворачивание нового пункта настоящим кликом MCP, подпись автора,
  читаемость подробностей и прокрутка на отдельном canvas.
- Полный `node RojoTest/tools/check.mjs`: 102 Lune-теста, 5 Node-тестов,
  StyLua, Selene, Rojo build и Luau types — пройдены, 0 диагностик.
- Независимый visual-critic: 6/6 в пределах видимого — зазор, привязка,
  свободный текст, удаление подвески, посадка декора и отсутствие заметных
  ненужных пересечений на показанных ракурсах.

Реализация и ограничения: [lobby-scene-cleanup.md](lobby-scene-cleanup.md),
[ball-signs.md](ball-signs.md). Снимки: `.tools/lobby-cleanup-2026-11-03/`.
Мобильные проверки, публикация, commit и push не выполнялись.

## Предыдущий проход подписей и ориентиров — 03.11.2026

Исправления аудита 1, 3–6; размещение яиц и действующих рейтингов сохранено
по прямому указанию пользователя. Узкие Edit-pass применены из свежих модулей,
без WorldLayout.prepare и без пересборки авторской карты.

- `VerifyMapReadability`: Edit и Server Play — 10 карточек мячей без пересечения
  прямоугольников с трёх подходов, 7 подписей над видимым декором тренировок,
  8 ориентиров за пределами поля и внутри своей зоны; прежний «ДОНАТ» восстановлен.
- Снимок Client Play подтверждает реальные LOCKED/UNLOCKED из профиля;
  покупки и игровые команды для проверки не отправлялись.
- `VerifyFootballCityArt`: 189 объектов, 32 предмета мебели с проверенной
  посадкой, 0 OBB-пересечений разных объектов.
- `VerifyFootballCitySurfaces`: во всех 8 зонах 0 конфликтов открытых граней.
- `VerifyCloudSea`: 6 сторон, 284 облака, 1797 долей; все без физики.
  Повторные apply CloudSea и FootballCityLandmarks ничего не перестраивают.
- `VerifyWorldLayout` в Server Play: 1 мир, 8 полей, 10 слотов, 7 тренировок,
  4 обычных яйца, все обязательные опоры/ссылки на месте.
- Edit snapshot: CFrame/Size/флаги всех 1556 частей с collide/touch/query
  совпадают. Ещё 272 объекта яиц и трёх действующих рейтингов сохранили
  геометрию/цвет/видимость либо текст/положение/размер GUI.
- Update Log 0.2.1: новая дата и два итоговых пункта; автор Ball team без выдуманного
  аватара. Открытие, раскрытие/сворачивание, подпись автора, прокрутка и
  закрытие проверены на отдельном canvas через действующие HudPanels/UpdateLogView.
  Изолированный ScreenGui использовал Sibling; игровые окна/профили не менялись.
- Уточнение по снимку пользователя: подписи мячей выровнены по общей высоте
  каждого ряда, независимый bob отключён только для подписей. В Client за
  2.6 s смещение подписей 0, а мячи продолжают двигаться. С фронтальной камеры
  все Power/Price внутри ряда имеют одинаковую измеренную высоту TextBounds.
  Coming Soon удалён из сцены и текущего черновика журнала; восстановлены
  исходные строки, заголовок «ДОНАТ» и значок Robux.
- `node RojoTest/tools/check.mjs`: 102 Lune, 5 Node, StyLua, Selene,
  Rojo build и типы — 0 диагностик. Зависимости уже полные, Wally install пропущен гейтом.
- Независимый visual-critic: 5/5 по рубрике правок. Мелкая надпись rooftop
  с дальнего плана остаётся вторичной; сам новый силуэт виден отдельно от фасадов.

Play остановлен, временные GUI/модули и camera bindings удалены; качество
рендера и blur восстановлены. В Output ошибок игрового кода нет; известное
предупреждение Rojo об asset 203785492 осталось. Мобильные проверки,
публикация, коммит и push не выполнялись. Ручную сцену следует сохранить в Studio.

Снимки текущего прохода: `.tools/map-readability-2026-11-03/` (локальные артефакты).

---

Текущая карта — Football City, World1. Старые результаты, включая проверки
двух миров до их объединения, сохранены в
[истории до 02.11.2026](history/verification-through-2026-11-02.md).

## Очистка 03.11.2026

- До очистки сделаны резервный коммит и push `a010fd2` в `origin/main`.
- `node RojoTest/tools/check.mjs` прошёл до и после изменений: StyLua,
  Selene, Lune, Node-тесты, Rojo build/sourcemap, проверка ProfileStore,
  ссылок модулей и типов. Типизация: 0 известных, новых и устаревших ошибок.
- Зависимости Wally восстановлены в отдельной папке с неизменным lock-файлом;
  все 336 файлов совпали с рабочими с учётом перевода строк одной лицензии.
  Packages сохранён на диске и снят с отслеживания Git.
- `VerifyTrainingBounces`: 10 125 проверок, семь дорожек.
- `VerifyTransparentCleanup`: удалены две неиспользуемые прозрачные накладки
  и четыре их дочерних объекта; 20 195 оставшихся деталей сохранили геометрию
  и физику, проверены семь тренировочных траекторий. Повторный план пуст.
- Play запущен и остановлен: сервер и клиент без MessageError, персонаж
  появился, в мире восемь полей, семь тренировок, десять слотов мячей.
  Появилось штатное окно Welcome Back; награды не забирались. Полный проход
  открытия всех меню не выполнялся.
- Дополнительная проверка prepare/apply временно вернула исторический декор.
  В Edit также выявился старый кэш City v3. Актуальные исходники и зависимости
  загружены заново; сцена возвращена к Football City v9, без возврата старой карты.
  Эта проверка не требуется при будущей уборке файлов.
- Финальный `VerifyFootballCityArt`: 181 законченный объект, 3107 граней со studs,
  32 проверки опоры мебели, 0 пересечений разных объектов.
- Финальный `VerifyCloudSea`: 6 участков, 284 облака, 1791 объёмная часть,
  физическая опора всех восьми полей сохранена.
- На первом этапе архивы не удалялись. Результат разрешённой позднее чистки
  архивов приведён ниже. Ручную сцену нужно сохранить в Studio; Git и
  standalone Rojo build её не заменяют.

Мобильная проверка не выполнялась. Игра не публиковалась, Update Log не менялся:
очистка не добавляет игроку новую механику или оформление.

## Продолжение очистки 03.11.2026

По явному указанию пользователя удалены 55 старых архивных веток: 84 300
экземпляров, включая WorldLayoutState.World2. Кандидаты проверены по исходникам
игры, ручным инструментам, скриптам Studio и входящим Instance-ссылкам.
Зависимости между архивами учитывались до удаления. Ветка с внешней ссылкой
и все архивы, используемые кодом, сохранены.

Перед удалением сохранён контрольный снимок каждого объекта Workspace.Map:
Parent/Name, свойства геометрии, материалов и физики, UI/эффектов, атрибуты,
теги и pivots. Кандидаты сначала отсоединены без уничтожения. Сверка всех
38 419 объектов (включая корень Map), затем Play, затем повторная сверка
прошли. Только после этого архивы уничтожены. В Edit строители и prepare/apply
не запускались; текущая карта Football City v9 не пересоздавалась.

Play: персонаж загрузился; ошибок сервера/клиента нет; 8 полей, 7 тренировок,
10 слотов мячей, WorldLayoutReady=true, старого журнала World2 нет.
WorldBackups теперь содержит 80 805 потомков, рабочий журнал World1 — 13 128.
Оставшиеся архивы нужны сборщикам, проверкам или живым ссылкам.

На диске удалены ещё 107 заменённых файлов моделей/UI (79,59 МиБ), ранее
сохранённых в a010fd2, и две проверенные конфликтные копии старого README.
Полный check.mjs после удаления ассетов прошёл, типизация — 0 ошибок.
Игра не публиковалась; новые коммит и push не выполнялись.

Точный список удалённых веток: [cleanup-archives-2026-11-03.json](cleanup-archives-2026-11-03.json).

## Функциональная проверка перед push — 03.11.2026

Игровые исходники и runtime-шаблоны сравнены с резервным a010fd2: изменений
содержимого нет, удалены только пять ранее неиспользуемых модулей.
В Edit строители не запускались. Контрольный снимок 38 418 потомков Map
после двух Play-сессий подтвердил неизменность Parent/Name, атрибутов,
геометрии, материалов, физики и pivots. Карта осталась Football City v9.

Проверено в Studio Server на изолированном состоянии без изменения прогресса игрока:

- BallGameplay: 151 проверка, все 10 размеров/шаблонов, покупка, повторное
  бесплатное экипирование, отказ при нехватке денег/неизвестном ID, анимация.
- EggInteraction: безопасные точки у четырёх яиц, перенос тестового стенда,
  отказ при отсутствии яйца или пола; временный стенд удалён.
- MovingTraining: 71 проверка на семи дорожках.
- TwoStageKick: 19 проверок двух стадий, множителей, повторных token и отмены.
- TrainingBoost: 174 проверки, семь дорожек и три платных продукта на mock-контексте.
- PersistenceAudit: изоляция Studio/Production, отказ от непостоянного fallback,
  повтор загрузки после ошибок, сохранение обязательства выдать питомца,
  защита от повторного чека и отложенное перерождение.
- Common/Uncommon/Rare/Rainbow: по 100 детерминированных исходов, цены,
  четыре разных загруженных меша каждого пула, сохранность старых pet ID.

Client:

- Шесть семейств FlightVisuals: по семь контактов, нет повторных/запоздалых
  звуков или всплесков; локальные декоративные тестовые мячи удалены.
- Серверный Snapshot получен обычным запросом через игровые remotes.
- На изолированном экземпляре действующих UI-компонентов с копией Snapshot
  проверены вкладки Balls/Pets/Eggs, переключение и кнопка закрытия.
  Все изображения мячей и яиц в открытых вкладках загрузились.
- Settings, Update Log, Rebirth, Daily, Gifts открыты и закрыты на отдельном
  тестовом canvas. Отправка покупок/получения наград была заменена локальным
  сборщиком команд; прогресс игрока не менялся. Тестовые GUI уничтожены.

Настоящее сохранение проверено отдельно: новая запись QA_RoundTrip в
BallProfiles_Studio_v1, подтверждённый save, перезапуск Play, чтение Skill,
Wins, Rebirths, best, настройки звука, питомца и экипировки. Данные совпали;
созданный этой проверкой ключ удалён через RemoveAsync. Production и реальные
ключи игроков тестом не читались и не изменялись.

При прогоне обновлены три устаревшие ручные проверки: путь TrainingZone заменён
на WorldRefs, геометрический центр внешнего декора мяча отделён от его
авторского pivot, ожидание прежних пяти Common-петов заменено текущими четырьмя.
Соответствующий игровой код не менялся. В итоговой Play-сессии MessageError
сервера и клиента отсутствуют. Проверка типов в полном гейте — без ошибок.

Публикация игры и реальные оплаты не проверялись. Мобильные проверки не выполнялись.
Git сохраняет файловую часть проекта; ручную сцену необходимо сохранять в Studio отдельно.

## Ocean Depths · локации 2–8 · 05.11.2026

По выбранным PNG построены семь локаций после существующего Coral Reef.
В Studio Edit независимый `tools/VerifyOceanLocations.luau` подтвердил:
8 зон по контракту сцены, 402 наземных объекта с полным пятном опоры,
370 поддержанных каменных ярусов, 8753 HD-текстуры с повтором 4.8 и offsets=0,
231 физическое попадание в Field. Стыки расположены через 324 studs,
видимый декор не пересекает габарит полёта над центральной полосой.
Повторное применение Zone08 дало одинаковые 2735 потомков, без дубликатов.

Снимок до сборки сравнен с финальной Edit-сценой: из 70605 существовавших
BasePart удалено 0; изменены только 5 частей водного фона World2 для продления
до конца курса. Остальные 70600, включая World1, станции лобби и Coral Reef,
сохранили CFrame, Size, прозрачность и физические флаги. Финальный
TransparentCleanup.apply нашёл 0 кандидатов и удалил 0 объектов.

Все семь новых зон посещены в Play. Проверены соответствующие свет и туман,
движение водорослей/фауны, пульсации медуз и открытие верхней створки при
приближении персонажа. Pearl Grotto корректно работает при выгруженном
стримингом Field первой зоны. После возвращения в World1 его освещение
восстанавливается. В Vent Fields персонаж прошёл 16.957 studs: изменение
высоты 0, Health=100, FloorMaterial=SmoothPlastic. Шлейфы включены с Rate=12;
сохранены три последовательных Play-кадра. Ошибок игрового кода Ocean Depths
не обнаружено. Известные прежние предупреждения ассета 203785492 и пропуск
изменённого авторского World1 не относятся к этой сборке.

Набор Blender содержит 7 моделей / 4406 треугольников. GLB и FBX повторно
импортированы и проверены; сохранены 4 ракурса. Нативный набор Studio:
7 моделей / 763 экземпляра, XML round trip прошёл. Восстановление трёх
эффектов из effects.json проверено в Edit. Структурированные результаты:
[studio-validation.json](../Assets/OceanDepths/LocationKit/studio-validation.json).
У каждой новой локации есть studio-overview.png и studio-ground-check.png.

Update Log v0.4.0 проверен на ПК: открытие, раскрытие и сворачивание,
аватар и вклад Dakemo555, прокрутка до Y=200, закрытие с уничтожением окна.
Короткие заголовки читаются без пересечения с Details; снимок лежит в
LocationKit/studio-update-log.png. Полный `node RojoTest/tools/check.mjs`
прошёл: 117 unit-тестов, 5 проверок гейта, сборка Rojo, 0 новых ошибок типов.

Независимая визуальная рубрика — 4/5: опоры, открытая трасса, studs и темы
проходят; крупные регулярные скальные лица и повторяемые уступы проще
референсов, листья kelp прямее выбранных янтарных лент. Это художественное
расхождение, видимых обязательных ошибок опоры/компоновки не найдено.

Ограничения: это Studio-превью; переходы между мирами, прогрессия и покупки
World2 не подключены. Створка реагирует на персонажа, а не на прилёт мяча.
Мобильная производительность отложена до подготовки релиза. Play остановлен,
временные тестовые привязки удалены, камера, качество и Edit-свет восстановлены.
Игра не опубликована; ручную сцену необходимо сохранить в Studio отдельно.

### Перераспределение ориентиров после отзыва · 05.11.2026

По просьбе пользователя убрана правая глубокая впадина Abyssal Trench.
Вместо неё сплошной широкий берег со скалами и террасами, аналогичный левому,
с отличающимися профилями. Оба корабля и оба храма распределены по одному
на сторону; крупные группы Vent Fields чередуются между берегами.
Независимая визуальная проверка всех восьми зон не выявила обязательных
ошибок баланса сторон, опор, studs или чистого коридора.

Итоговый аудит: 444 наземных объекта, 394 каменных яруса, 8940 текстур,
231 попадание в Field — без ошибок. 77572 части вне четырёх изменённых зон
сохранили геометрию и физические флаги; удалено 0. В Play 66 лучей по обоим
берегам бывшей впадины попали в сплошную поверхность, пропусков 0.
Персонаж прошёл по правому берегу 16.961 studs, вертикальное отклонение 0,
Health=100. Кальмар продолжает двигаться, освещение зоны действует.
Клиент видит корабль и храм на каждом берегу. Полный check.mjs прошёл.
Обновлён текущий черновик Update Log v0.4.0; проверены открытие, раскрытие,
читаемость новых подробностей и закрытие на ПК. TransparentCleanup.apply:
0 кандидатов и удалений. Общие и правые виды — studio-balanced-*.png;
отдельный обзор Coral Reef — Assets/OceanDepths/studio-coral-balance-audit.png.

### 2026-11-05 · Animated Ocean Depths wildlife

Eleven Blender species imported as persistent skinned MeshParts; 30 schools (262 fish),
28 individual creatures, 58 routes. All scenery/HD-stud checks remain green: 8 zones,
444 grounded objects, 394 stone tiers, 8940 textures, 231 pitch hits. Preservation baseline
83038 parts: 0 missing, 0 changes to surviving Workspace geometry/physics, 630 old fauna
parts archived outside Workspace. Uploaded-package links are absent from the active wildlife.

GLB/FBX reverse imports: 22/22. Deformation bounds: 31 poses × 11 species, closed cycles
within 0.0001 studs. Full-world 60 s simulation: 104400 steps, 2 rejected unsafe steps,
minimum pair-envelope gap 0.2700 studs, 261/262 fish reshuffled, all 58 static route certificates
pass against 30249 visible obstacle bounds. Adaptive initial spacing and swept relative
movement prevent overlap, including low-rate catch-up steps. Atomic school models preserve
whole groups under streaming. Runtime distance culling pauses/resumes each group's own clock.

PC Play: screenshots in all eight locations, moving wings/tails/tentacles, correct colours and
World1 lighting restore. Update Log opened, expanded with Dakemo555 credits, and closed.
No new wildlife errors; old asset 203785492 warnings remain unrelated. Full check.mjs passes:
120 unit tests, 5 gate tests, Rojo build, 243 relative requires, 0 new type errors.
Evidence and recovery: Assets/OceanDepths/AnimatedSeaLife/{README.md,studio-validation.json}.
No mobile/release profiling, game publication, Git commit or push performed.

### 2026-11-05 · Developer travel and noclip flight

PC Play through the actual DEV → Карта buttons: World2 preview travel and World1 return
work, close the panel and preserve saved world/progress. Flight toggles its visible gold
indicator and movement constraints; Space raised the character about 45 studs in 0.9 s,
W moved about 48 studs in 1 s through a temporary collidable wall, and Shift+W moved
57.6 studs in 0.6 s. Ctrl descended 14.8 studs in 0.3 s. Hover holds position.
Disabling flight restored original collision values, normal Humanoid flags and controls.
Death/respawn clears flight, preview attributes and constraints; the new character is
alive with PlatformStand=false. Wrong payload types and unauthorized requests are rejected.
Temporary test wall removed; camera override removed; no saved-world changes from travel.
UI evidence: Assets/UI/DevPanel/world-travel-flight.png. Contract: docs/dev-navigation.md.

### 2026-11-05 · Larger and faster fish

Targeted Edit migration: all 268 fish (262 school members and 6 anglerfish) are 2× their
previous size and route speed, with matching 2× skeletal frequency. The other 22 creatures
retain their scale/speed. 36 fish routes were recertified; 29 origins moved, at most 80 studs.
All 58 final route certificates pass against 30,249 visible obstacle bounds. Reapplying the
migration changes zero route origins, speeds or scales. Scene preservation comparison found
zero missing or altered landscape parts; no stud texture edits.

Whole-world 60 s simulation: 169,200 integration steps, two rejected unsafe steps,
minimum full-deformation pair gap 0.5401 studs, all 262 school members reshuffled, maximum
school-envelope ratio 1 within float precision. Fish integrate at 1/60 s or less.
PC Play: enlarged fish viewed from normal player camera and both sides at close range;
root movement and changing bone transforms observed. Screenshots and numeric evidence:
Assets/OceanDepths/AnimatedSeaLife/{studio-fish-double-size*.png,fish-visibility-validation.json}.

`node RojoTest/tools/check.mjs` passed formatting, lint, 120 Lune tests, five verification
gate tests, Rojo build/sourcemap, 246 requires and type checking (zero known/new/stale errors).
Rclone had moved recent source/docs into conflict copies; recovered the newest versions,
preserving every conflict copy. No mobile test, commit, push or publication performed.

Fresh PC Play also verified the current Update Log entry: the 2× size/speed description,
Dakemo555 credit and avatar fit, details expand/collapse, and the window closes normally.
Evidence: Assets/UI/DevPanel/update-log-flight-fish.png. Play stopped after verification;
temporary camera bindings and test globals removed, Rojo kept running.

### 2026-11-05 · Ocean Depths atmosphere

All six agreed additions are implemented in the Studio preview: 16 close schools
(48 fish), an extra manta crossing, travelling jellyfish glow and squid encounters,
moving surface caustics, certified plankton/bubble pockets, spatial underwater audio,
grounded distant reefs and depth haze. Original 2× fish size/speed is retained.

Edit checks: all 30,806 pre-existing parts retain CFrame, Size, Color, transparency and
collision; none missing. All 162 new reef columns have full rectangular support on the
seabed extensions. All 75 route certificates pass against 30,433 visible bounds,
including decoration with CanQuery=false. The 60-second school simulation completed
228,600 integration steps, rejected three unsafe steps, maintained a minimum full-pose
pair gap of 0.3119 studs and reshuffled all 310 school members. New particles use bounded
clear volumes; bubble paths expire inside swept columns above their source surfaces.

PC Play: ordinary-camera captures in all eight zones; separate close surface and side
support captures. The default cloudy sky is covered by a local far enclosure even when
distant walls stream out. Independent visual review found no mandatory defects; full
support was then additionally checked numerically and from the side.

Real-time checks: a complete 82-second manta recording reached fully visible and fully
hidden states, with movement in 162 samples. A full jellyfish wave measured light brightness
from 0.2 to 1.45. All six selected sounds loaded in Edit and Client with non-zero measured
lengths. Effects/ReducedMotion integration disabled all new emitters and caustic overlays;
the existing sound bus handles mute. Saved preferences were not modified by the probes.

Streaming regression found and fixed: losing Field1 previously stopped the atmosphere
update. The controller now retains a measured origin and can derive it from another loaded
field. With Field1 temporarily absent on the client, Zone06 still had three active ambient
emitters, a playing vent loop and its underwater enclosure. The temporary anchor change
was restored. On World1 return the ambient sounds stopped, the music volume returned to
0.12, muffling disabled, normal camera restored and FogEnd returned to 2400.

The current Update Log v0.4.0 entry was opened, expanded/collapsed and closed on PC;
the new details and Dakemo555 credit fit. No game-script errors appeared; old sound
203785492/SurfaceSeparation warnings remain. Two failed AssistantCommand UI lookups
were test-harness mistakes, corrected during the same check.

Full gate: StyLua, Selene, 123 Lune tests, five verification-gate tests, Rojo build/sourcemap,
248 relative requires and zero known/new/stale type errors. Evidence and recreateable assets:
`Assets/OceanDepths/Atmosphere/`. No mobile test, commit, push or game publication.

### 2026-11-05 · Remove replaced ocean backgrounds

Removed six obsolete WaterGradient/WaterGradientSegment walls (and their SurfaceGuis)
and four static DepthCurtain parts. All were decorative with collision, touch and query
disabled; only their dedicated background containers were removed. WaterSurface and its
segment, ripples, sunlight, reefs and landscape remain. The builders no longer recreate
the old walls, and the client no longer toggles legacy gradient GUIs. The targeted removal
method does not rebuild the map. PC Play confirmed zero old walls and an active local
UnderwaterHorizon with no opening into the default sky. Screenshot:
Assets/OceanDepths/Atmosphere/studio-local-background-only.png. Play stopped afterward.

### 2026-11-05 · Ocean Depths portal and gameplay

Desktop Play used an isolated Studio profile. The portal opened on walking into
the dashed zone. Closing the window inside the zone held until the next entry.
Both generated banners loaded after sharing their Roblox Image assets with the
experience. The dashes moved on the ground in Play.

A new profile could not travel without enough Wins. At 100,007 Wins, the
Unlock button left 7 Wins and landed the player on the Ocean Depths apron.
Respawn kept World2. Return to World1 and re-entry to World2 preserved the
balance. A new session started in Football City with the unlock intact.

The Classic Ball prompt equipped the ball and charged 250 Wins. A timed
17,978 m kick crossed seven named boundaries, reached Pearl Grotto, activated
the shell and awarded 11,459 Wins and 168 Skill. Both lobbies displayed the
same rankings. The layout verifier found two worlds, 16 fields, 20 working ball
displays, and 14 training lanes and eight eggs including World2's placeholders.
The Update Log entry was checked in the scrollable PC window with details and
the author avatar.

### 2026-11-05 · Ocean training, eggs and location dividers

PC Play used the isolated Studio namespace
BallProfiles_Studio_World2StationsQA_20261105. The source storage routing was
restored after startup. World2's seven lanes all started through the ordinary
training loop and awarded Skill. Lane 2 rejected zero rebirths, then started
after the requirement was met. The seven lane multipliers retain their existing
rebirth requirements and apply the world's triple Skill reward.

VerifyRandomTraining passed 19,451 assertions for 2,016 shots on 14 lanes.
The expanded regression caught coordinate rounding near Ocean Depths' goals.
TrainingGoal now accepts a 0.001-stud plane tolerance, and the same full
regression passed afterward. VerifyTrainingBoost passed 329 assertions on
14 lanes with isolated receipt fixtures. Real paid products remain unconfigured.

The nearest Common Egg panel displayed 500 Wins. Pressing E opened its real
hatch presentation, deducted 500 and granted a pet with the triple world boost.
Common x3, Uncommon, Rare and Rainbow deducted 1,500, 5,000, 50,000 and 400,000
Wins respectively, with the expected pet counts and boosts. Insufficient Wins
rejected a triple Rainbow hatch. Clicking Open Again deducted the correct
400,000 and granted another pet. Existing persistence retains individual
pet boosts.

VerifyWorldLayout passed for two worlds, 16 fields, 20 ball displays, 14 lane
signs, eight ordinary eggs and seven Ocean dividers. Special-egg prompts
were present in both worlds. The dividers stand on the seven location seams,
are 30 studs tall and 50% transparent, show the correct names on both faces,
and have collision, touch and query disabled. They were inspected at player
height from the front and side and in Edit from behind. Targeted Edit
application also proved idempotent, without rebuilding the authored worlds.

The Update Log opened, scrolled, expanded and collapsed on PC, with readable
details and a loaded Dakemo555 avatar. Its summary was shortened after the
first visual check to fit the row.

Final fresh PC Play confirmed the shorter summary fits. Existing Edit dividers
survived normal startup. The complete gate passed with 124 Lune tests, five gate
tests and zero known/new/stale type errors. No game-script errors appeared in
the final run. The pre-existing 203785492 asset warning and SurfaceSeparation
message remain. Studio returned to Edit.
# 2026-11-05 · Ocean egg integration

Five approved Blender eggs imported and arranged Common → Legendary in World2.
301/301 native CSG components completed; Jelly has 30 translucent components.
PC Play confirmed levitation and five active outlines, correct themed prompt
names, and startup without new game errors. Four normal approach raycasts find
ground. The static gate passes 126 unit tests, five gate tests and zero type
diagnostics. No paid hatch or reward mutation, mobile test or publication.

# 2026-11-05 · Nautilus egg cradles

- Five World2 ShellCradle models replaced from the selected Blender concept 5.
- Approved smooth GLB Model 70791212451135 uploaded once to Dakemo555 with explicit
  consent. Use and dependencies granted only to universe 10770268214. Source
  bounds/orientation checked; all importer-grey material colors restored.
- 29 imported MeshParts plus a two-piece contact foot per cradle. Original shells,
  native source and imported package preserved outside Workspace.
- Reapply: zero drift; 316 static stand and interaction parts unchanged.
- 45 contact probes: zero misses and no air gap. Eggs retain 7.5-stud height,
  0.06-stud static rim clearance, names, order and existing purchase anchors.
- PC Play: five eggs move, five cradles stay static, five outlines activate;
  effects remain active. Dakemo555 / 11789507527 confirmed. No purchase or profile edit.
- Full check.mjs passes: StyLua, Selene, 126 Lune tests, five gate tests,
  Rojo build, 266 requires, ProfileStore integrity and zero type errors.
- Preloading actual shell Models succeeds for all 155 MeshPart references.
  Independent visual review 4/4; central spiral confirmed in an isolated temporary
  inspection copy, removed afterward. Update Log opening/closing, current text,
  author and readability verified on PC.
- Play stopped; Edit camera frames the stand. Save the place for manual assets.
