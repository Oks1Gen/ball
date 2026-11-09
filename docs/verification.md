# Проверки проекта

## Frost Egg models and portraits — 2026-11-09

Five pets were modeled in headless Blender using the reference proportions
and the revised saturated palette. All fifteen model exports passed isolated
reimport. The built-in ImageGen portraits passed the 512 × 512 RGBA and uniform
24 px contour checks. Roblox approved all ten assets and granted Ball access
including model dependencies.

Desktop Play showed all five textured models from four angles and in the
follower controller. The outlined portraits loaded in Pets, the detail card,
the Egg collection, the proximity catalogue, the hatch stage and Pet Workshop.
The proximity test used the real Frost stand and an isolated discovery state.
The scroll test reached the Legendary portrait. Golden and mutation forms
kept their textures. The hatch showed the formatted ×3.16 Skill label.

All 10,000 roll values per egg were checked. Frost follows 55/30/10/4/1%.
Legacy Frost pet IDs, item UIDs, boosts, equipment and discoveries were
verified against a fixture. Update Log expansion, collapse, scrolling, author
and close were checked in Play. The project gate passed 151 Lune and five gate
tests with zero type errors. Test copies were removed and Play was stopped.
[Studio evidence](../RojoTest/assets/pets/frost-v1/verify-studio.json)

## Forest Egg models and portraits — 2026-11-09

Three approved Roblox models and three outlined portrait images are shared with
Ball. Each model uses one textured MeshPart. Studio Play confirmed mesh and
texture loading, front, side, rear and underside views, follower scale and
collision flags. Normal portraits loaded in Pets, the selected detail card,
the Egg collection, the egg proximity catalogue, hatching and Pet Workshop.
The undiscovered Moon Owl was black in the catalogue. Golden Bloom Fox retained
its texture and tint.

The 10,000 Forest Egg rolls yielded 5,500 Common, 3,000 Uncommon, 1,000 Rare,
400 Epic and 100 Legendary. Isolated legacy records kept species IDs, item UIDs,
equipment and discovery flags while adopting the new names. Update Log v0.8.0
was opened, expanded, collapsed and scrolled on desktop. Its author and text
fit were verified. The full gate passed 151 Lune and five gate tests with zero
type diagnostics. Fixtures were removed and Play was stopped.
Evidence: `RojoTest/assets/pets/forest-v1/verify-studio.json`.

## Pets rarity colours and Common outline — 2026-11-09

The detail plane now derives its gradient, outline/halo and rarity pill from the selected pet rarity. Native PC selection Rare→Uncommon→Common verified live gradient endpoints against Theme.Rarity (80%/40% RGB); names fit. Common card and pill outlines match the main window's Theme.Outline exactly RGB12,13,19; Common text is white. Other rarity rims/halo follow their palette. Final Common halo is neutral Theme.Outline→white12%, removing the remaining fixed cyan. No new assets or saved inventory changes. Source delivered through Rojo; project gate log: `RojoTest/.tools/pets-rarity-check.log`. No mobile test or publication.

## Pets 01D: composition revision after rejection — 2026-11-09

The first implementation's functional checks did not establish visual acceptance. Revised against the approved image: overall design1120, larger desktop scale (1.10 at1366×767), closer flat rounded card, viewport inset correction, calibrated perspective, larger trimmed portraits and labels, brighter teal face, short button gloss, Golden Scarlet art and shard icon. Original translucent fill/close artwork retained. Details: [pets-inventory.md](pets-inventory.md).

Fresh Play: source delivery confirmed; native plane Equip/Unequip, disabled Team Full rejection, golden image loaded, Recycle confirmation blocks detail, Recycle4→3/Best/sort/Craft in isolated canonical fixture; real Craft opens Window_PetCraft and removes plane/surface. Scroll60 reached Y500. Effects Off rotation0, On resumed. Three repeated close/open cycles left one plane; final close left none. At final desktop scale, extreme tilt sweep left21.105px minimum close clearance and69.080px right margin; all footer groups stay inside shell at1.14 including shadow allowance. Update Logv0.8.0 opened, expanded/collapsed and closed; changed details fit510×68 in511.07×76.81. Author Dakemo555 confirmed in Play.

Final gate:149 Lune +5 verification tests, StyLua/Selene, Rojo build, ProfileStore integrity,284 relative requires,0 type diagnostics. Log: `RojoTest/.tools/pets-v2-check.log`. New PNGs use Git LFS; both moderation Approved and universe Use sharing succeeded. No new UI runtime errors; existing startup ContentId203785492 type-mismatch warnings remain unrelated.

Evidence: `Assets/UI/Pets/immersive-v2/verification/results.json` and `2026-11-09-pc-geometry.png`. The image is diagnostic: engine capture omits AlwaysOnTop SurfaceGui, so AlwaysOnTop/blur/brightness/local character/follower visibility were temporarily changed, then restored. It is not an exact normal-color/blur screenshot. No mobile test, live spending, save mutations, standard write, commit or game publication. Play stopped. Visual approval is pending the user's review.

## Pets inventory 01D — 2026-11-09

Implemented the user-selected 01D with React/Ripple: original translucent shell/close art, no Pets sidebar, contained chunky footer, live counts and a rounded paper-thin perspective SurfaceGui. Existing gameplay requests preserved. New four individual alpha icons uploaded/approved and shared with universe10770268214; all loaded in Play. Exact design, implementation and ownership: [pets-inventory.md](pets-inventory.md).

Final `node RojoTest/tools/check.mjs`: **149 Lune +5 gate tests**, StyLua/Selene/Rojo build/ProfileStore integrity pass, **0 known/new/stale type errors**. Log: `RojoTest/.tools/pets-ui-check-console.log`. Mandatory Rojo HTTP200; final source delivered and fresh Play used.

PC evidence: native projected Equip/Unequip clicks in isolated canonical fixture; hover1.08, disabled press0.96 without dispatch; confirmation blocks detail; cancel preserves4, confirm4→3 fixture pets; Best/Craft/Sort; real Craft opens Window_PetCraft and destroys detail.60-pet scroll reached last row; empty Find Eggs works. Five rapid reversals retain exactly one plane/surface; final close leaves neither. No real pet spending or test remote/profile writes.

Effects Off:0 radians motion/scale1; On resumes0.14959rad sampled tilt. Camera move screen-anchor error0.000372px. Extreme tilt sweep leaves at least29.879px from close button at its maximum growth and21.48px to the screen edge. Footer groups remain inside shell including max1.14 growth. Names wrap and fit. Sound via existing SkippingSounds: IsLoaded/Playing true,0.845417s length. Runtime error log clean on final Play.

Update Log v0.8.0,2026-11-09,published=false: confirmed Dakemo55511789507527, loaded avatar, open/close, expand/collapse, description fit and scroll189.588px. Prior releases retained. No publication or commit.

Capture limitation reproduced with an independent native SurfaceGui: engine capture omits AlwaysOnTop output. Normal screenshot therefore lacks the card. A separately labelled geometry proof temporarily uses world-pass rendering, Brightness2, no blur and hidden local character/followers; all settings restored. Files and machine-readable results: `Assets/UI/Pets/immersive-v1/verification/`. Not claimed as an exact normal-runtime color/blur screenshot. Mobile deferred by project instruction; Play stopped and temporary fixtures/observers removed.

## Progression balance implementation — 2026-11-08

Implemented user-approved balance with explicit overrides: balls add training bonuses only; bubbles retain x5–15 and paid x67/69/144 values with a 14-second interval; rebirth requirements, multiplier and all lane gates/multipliers remain unchanged. Tunables and migration rules are documented in [balance.md](balance.md). Earlier CEO proposal below is historical.

Full `node RojoTest/tools/check.mjs` passed on the final code: formatting, Selene with zero warnings, 140 Lune tests, five gate tests, Rojo build, 274 relative requires, pinned server-only ProfileStore integrity, Studio tool/source checks and zero Luau diagnostics. Logs: `RojoTest/.tools/balance-check-console.log`, `lune.log`, `typecheck-summary.txt`. Git diff confirms Economy changed only shot power's lower bound, not rebirth math. No tracked conflict files were introduced; pre-existing AGENTS.md/restoration work preserved.

Studio target place 106456161057435, universe 10770268214. Author reconfirmed in Client as Dakemo555 / 11789507527. Source delivery through Rojo checked before fresh Play. Final Server results:

- `VerifyBalanceRuntime.luau`: 14 checks, Commands/Snapshot isolated state, zero gameplay profile writes. Buying a ball increases training but preserves current distance; replayed recycling/claims cannot grant again.
- `VerifyTwoStageKick.luau`: 19 checks, bounded timing, stage tokens/replays/cancellation and separate perfect accents. Returned min 0.85, max 1.35, mixed perfect stages 1.1.
- `VerifyBallGameplay.luau`: 151 checks, all ten models, additive tiers, prices, ownership transactions and animation, isolated inventory.
- Actual scene at 20,000 Skill: weak 2,911 m, neutral 3,127 m, perfect 3,571 m. Rainbow Secret multiplier x10; bubble interval 14 seconds. Rebirth requirements 50K/80K and final lane x64 / 16 rebirths confirmed.

PC UI checks used `PreviewBalance.luau`: production React components and isolated data without gameplay remotes. Ball +X cards; pet upgrade spent 10 Shards and changed Common 1.15 to 1.165; recycle confirmation and successful removal/shard payout; task Claim added exactly 40 Wins and one Shard. Protected Secret/equipped/paid cases covered by Lune and runtime checks. Final egg screen showed 55/30/13.95/1/0.05%, with Secret reachable by scrolling; fractional multiplier displayed as 1.675. Pet portrait assets reported IsLoaded=true. Update Log v0.6.0 showed Dakemo555/avatar, four entries, details expanded/collapsed and scrolling. Captures: Balance_PC_Balls, Balance_PC_Pets_Sibling, Balance_PC_Challenges, Balance_PC_Secret_Final, Balance_PC_Crafting_Final, Balance_PC_Recycle_Confirm and Balance_PC_Log_Expanded. Some fixture captures predate the final optional Secret power increase from 7.75 to 10; final server readback above verifies x10.

Main client's `ProgressionReward` feedback was delivered separately and its toast text observed without a reward mutation. A SoundService listener confirmed success Sound 91735091370012 with Playing=true and IsLoaded=true. A separate CollectorUI handle displayed an isolated Secret hatch: five real E key presses, full highest-tier reveal, Eclipse Cat / Secret / x10 labels and Continue. Capture: Balance_PC_Secret_Reveal. No hatch remote or profile write. The observer and hatch handle were removed afterward. Existing asset 203785492 type warnings and SurfaceSeparation's guarded authored-part skip remain; the only extra Output error came from an early verification request before remotes were ready, corrected by waiting for readiness. No builders manually invoked, no mobile test, publication, purchases or sales changes. Fixtures removed; Play stopped; Rojo remains running.

Still unmeasured: full fresh-player time to first rebirth and later progression/retention under the new balance. Fixed-loadout calculations are hypotheses, not observed session times.

## CEO balance audit — 2026-11-08

Read-only source review and Studio MCP inspection of place 106456161057435 / universe 10770268214. Rojo HTTP 200; Studio in Edit. Confirmed current economy constants, lanes, egg costs and authored shot limits (World1 17,897 m; World2 17,907 m). In World1 at 20,000 Skill and default ball, Config returns 3,127 m before timing; the current x6 perfect reaches the limit.

`node design/balance-model-2026-11-08.mjs` completed with exit 0. All five World1 shot snapshots match Studio's returns. Calculated rare-drop distribution, fixed-loadout training times and rebirth sensitivity through r=30. Proposed values remain hypotheses; no Play session, fresh-player timing, cohort/retention measurement or cloud sales-state check was performed. Existing scene, source, profiles and purchase configuration were not changed. No builders or UI automation used.

Proposal and assumptions: [balance review](../design/balance-review-2026-11-08.md). Scoped acceptance appended to `design/ACCEPTANCE.md`; earlier restoration results preserved. No Update Log entry applies to this analysis-only task.

## Original gameplay restored — 2026-11-08

At the user's explicit request, removed the experimental downhill implementation, declarative input tree, tests, prototype scene and prototype-only scene archives. Restored the original server/client/loading bootstraps, networking and WorldRefs byte-for-byte from the pre-prototype Git revision. Removed the unpublished experimental release drafts; the disk Update Log contains one restoration entry. User changes to AGENTS.md were preserved.

Edit comparison verified all 83,530 original World1/World2 parts unchanged in identity, CFrame, Size, transparency and collide/touch/query flags. Original scene/source safety backups were retained. Desktop Play loaded SkippingHUD, CollectorUI, BallTopbar, original training/tutorial interfaces and SkippingRemotes; the avatar spawned in World1 at (54, 23.598, 129.6). No DownhillRemotes were created. Remaining orphaned prototype ModuleScripts/input objects were removed from Edit after checking the corresponding source files were deleted. Full gate: 132 Lune tests, five gate tests, formatting, Selene, Rojo build, ProfileStore integrity and zero Luau diagnostics passed.

Rojo HTTP responds, but the Studio plugin reported disconnection and did not receive the last restoration-log edit after a file touch. The original gameplay bootstraps in Studio were already verified restored; the remaining log delivery requires reconnecting the Studio Rojo plugin. No UI automation was used. A full replay of purchases/progression and a new mobile test were outside this rollback.

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


## Pet Workshop implementation — 2026-11-08

User-directed replacement of the previous shard upgrade system: duplicate fusion through Golden/Diamond/Rainbow, higher-form jackpots, five random replacing mutations, reference-adapted React UI and a lobby station. No publication, purchases or loaded-profile test writes.

- Rojo HTTP 200 before work and continuation; all source via disk/Rojo. Fresh Studio Play, player Dakemo555 confirmed. Exactly one station remains in Lobby through startup. The initial missing LayoutKey caused duplicate stations/prompts; fixed and fresh Play confirmed native E opens the real workshop with HUD hidden and blur. No whole-map builders invoked manually.
- Unit tests cover all material counts, full form chain and terminal Rainbow, exact mutation weights, higher-form boundaries, all-consumed failure, primary mutation inheritance, equipped/paid guards, duplicate selection, stale revisions, weak-over-strong replacement, origin matching and reload/refund idempotence. Full check gate evidence: `RojoTest/.tools/workshop-check-console.log`.
- Studio `VerifyPetWorkshop`: **20 checks**, isolated Commands context, policy not ready/restricted, equipped/duplicate inputs, consumption, exact shard cost, cooldown, replay, snapshot invalidation, saved form/mutation/power. `VerifyBalanceRuntime`: **14 checks**, updated for mutation costs; balls, flight, Secret and rebirth regression. Both returned profileWrites=0.
- PC production UI exercised through isolated PreviewPetWorkshop: real button clicks choose and auto-fill five, remove slot five, display **80%** with Fail20/Golden79.12/Diamond0.8/Rainbow0.08, confirmation and roulette. A seeded unit=.99999 demonstrates Normal→Rainbow jackpot; seeded outcomes are fixtures only, never production RNG. Golden and Rainbow vertex colours, intact facial features, Diamond and mutation labels read visually. Cosmic→Wind spent exactly10 Shards and retained Diamond; sound91735091370012 observed Playing=true, IsLoaded=true.
- Captures: WorkshopFinalSelection, WorkshopGoldenVertices, WorkshopFiveMutationOdds, WorkshopDowngradeResult, WorkshopEightyPercentFinal, WorkshopRainbowFinal, WorkshopNativePanelFinal, WorkshopUpdateLogFinal. Earlier QA overlays occasionally included the actual panel beneath; fixture now hides/restores existing windows. Main-game capture confirms one window.
- Update Log current unpublished draft is v0.7.0 with five entries. Open/close, new version/author, scrolling and details expansion checked on PC: pet entry Expanded=true with202.85px height (collapsed57.11px). Confirmed nick/UserId preserved.
- Machine source uses39 native parts authored in Blender, with .blend/.glb/.fbx retained. All three reimport to39 meshes,916 triangles; materials present. Source/render/verification in Assets/PetWorkshop. Actual Studio placement front at player height observed, footprint9/9 rays supported atY20.24; native prompt opens after duplicate fix. Final four Edit angles checked separately below.
- Existing Output asset203785492 type mismatch and SurfaceSeparation authored-part skip warning predate this task. No new errors accepted. Optional editable-mesh allocation has explicit cosmetic fallback; low-memory device testing remains unmeasured.
- New sounds/particles were not generated. Buttons use existing motion/sounds, vertical reel Ripple, reveal existing Sunburst/success sound, mutation outline. Mobile deferred by project instruction. Full new-player/endgame pacing and retention remain unmeasured; see backlog.

- Final gate: **147 Lune tests + 5 gate tests**, StyLua/Selene zero warnings, Rojo build,279 resolved relative requires, pinned ProfileStore integrity, Luau **0 new/known/stale errors**. Logs end in All checks passed.
- Failure UI separately verified on final fresh Play: one selected pet consumed,10 of11 fixture pets remain, Fail result and consumption message shown; built-in failure sound observed Playing=true/IsLoaded=true. Fixture now explicitly dismisses old cosmetic receipts before mounting; no real profile writes.
- Final Edit captures WorkshopInspectedFront/Left/Rear/Right visually checked: full supported foundation, clear surrounding route, no duplicate machine. Play stopped, temporary UI/sound observers removed; Rojo remains running. First capture immediately after Stop temporarily had no focused handler, subsequent captures succeeded.


## Pet Workshop inventory fix — 2026-11-08

- Repro: user screenshot showed no eligible pets despite ownership; workshop consumed `data.pets`, but Snapshot.apply deliberately strips pets/equipped from data and stores them in inventory. The original fixture had the wrong shape. This was a client view integration bug, not deleted player pets.
- Fixed split inventory reads and all equipped lookups. `PetWorkshopState` tests use the real client Snapshot.apply: inventory update → progress-only payload → replacement inventory. Equipped/protected/Rainbow remain visible with reasons and a direct unequip action. Fixture now uses `data` without pets/equipped and a separate `inventory`.
- Fresh Play on the actual profile: **6 real pet cards** displayed, including four matching Scarlet Mushrooms; auto-fill selected four for **80%** and correct full odds. Mutations displayed all6; insufficient2 Shards shows a disabled spin. Captures WorkshopInventoryBugFixedLive, WorkshopRealPetsAutoFillFixed, WorkshopRealMutationViewFixed. Real pets were not consumed for verification.
- Prompt service observed false while the real window was open and true after closing. Station prompt no longer overlaps the modal. Shared modal suppression also preserves hatch behavior by replacing the separate hatch-only state.
- Canonical-shape fixture:11 pets/3 equipped all visible with Equipped badges; Unequip to craft removed qa1 from the fixture's equipped array, kept qa2/qa3 and spent nothing. Auto-fill skipped the remaining equipped pets, five eligible pets became one Golden (11→7). Mutation then spent10 Shards (100→90), Cosmic→Wind, Diamond preserved. This fixture sends no gameplay remotes or profile writes.
- Full gate: **149 Lune tests +5 gate tests**, formatting/lint/build/ProfileStore/types passed,0 new/known/stale errors. Log: `RojoTest/.tools/workshop-fix-check-console.log`. Output has only the pre-existing203785492 asset mismatch and authored SurfaceSeparation skip. Mobile deferred by project rules.

## Forest Egg roster concepts — 2026-11-09

Static design proposal only: `Assets/Pets/ForestEgg/concepts-v1/`. First display
title Forest Egg verified in EggSigns; current Common pool has four chances
55/30/14/1% from Core/Balance. Built-in ImageGen produced one visually inspected
1536x1024 roster sheet: Clover Bunny, Acorn Squirrel, Bloom Fox, Grove Guardian.
The cube proportions follow the three user references. Rarity adds visible
secondary forms rather than only colors. PNG copy SHA256 equals the generation
source; prompt, references and scope limitations retained beside it.

KB consulted: Shape Language and Silhouette Testing (roster test, Checklist),
Chibi Character Rules in Practice (Checklist). Static silhouette comparison
applied; actual game size, rear views, 3D assets, animation and Studio lighting
not verified. No source implementation, Update Log, profiles, publication or
permanent-standard writes. Code checks are inapplicable to this image-only task.

### Forest Egg simplified roster v2 — 2026-11-09

User liked soft style and forms, requested less foliage/detail. Built-in ImageGen
edit saved in `Assets/Pets/ForestEgg/concepts-v2/` with exact prompt and notes.
Visually verified clean fox body, two tails, bare guardian antlers with two glowing
tips, no leaf mantle/amulet/particles; bunny clover and squirrel cap simplified.
Faces, cube forms, labels and odds retained. Source/copy SHA256 matches; v1 kept.
Rojo HTTP 200; static-only scope, no game implementation or permanent-standard write.

### Forest Egg cube-base correction v3 — 2026-11-09

Built-in ImageGen edit in `Assets/Pets/ForestEgg/concepts-v3/` corrects fox and
guardian to single square cube bodies with tiny feet; flat front/side planes
and no separate head/torso visually confirmed. Soft style, appendages, names and
odds preserved. Exact prompt saved, copy/source hashes match, Rojo HTTP 200.
Static scope only; no game implementation, publication or permanent-standard write.

### Forest Egg five-pet roster v4 — 2026-11-09

User requires five designs per egg; first-egg sheet now contains exactly five.
Built-in ImageGen added Moon Owl (Epic): lavender cube, amber eyes, ivory mask
and crescent, small wings. All five cube bases and soft rendering visually
confirmed in `Assets/Pets/ForestEgg/concepts-v4/forest-egg-five-pets-v4.png`.
Proposed odds 55/30/10/4/1% total 100%; production pool remains unchanged.
Exact prompt/rationale saved, source/copy SHA256 matches, prior variants kept.
Rojo HTTP 200. Static scope; no gameplay, Studio/mobile or publication actions.

## World1 remaining egg pet concepts — 2026-11-09

Four built-in ImageGen sheets in `Assets/Pets/World1/remaining-eggs-v1/`:
Frost, Magma, Void and Solar Crown. Exactly five complete cube pets per sheet
(20 new concepts), visually inspected against approved Forest v4. Soft plastic,
flat cube planes, small feet and minimal decoration retained; species and large
secondary silhouettes distinguish tiers. Void includes Secret Singularity.
Names/rarities checked; no probabilities shown. Solar Crown's five-pet design
exploration does not change its existing guaranteed premium reward.

All PNG headers confirm1536x1024; source/copy SHA256 matches in verification.json.
Exact prompts and full rosters saved beside sheets. KB roster/silhouette/chibi
checklists from current task reused; no Studio/runtime silhouette claims made.
Rojo HTTP200 verified first. Static-only work: no game source, reward pool,
profiles, Update Log, permanent-standard, commit, upload or publication changes.

## World2 pet reference library and saturation revision — 2026-11-09

Five new sheets for Kelp/Leviathan/Treasure/Abyss/Jelly, exactly five pets each.
World2 titles/themes verified in OceanEggCatalog and ocean-eggs.md; Rojo HTTP200.
User requested richer saturated colors during generation; all five v1 sheets
were edited with built-in ImageGen into final v2, preserving species, cube
bases, faces, appendages and labels. V2 visually inspected against v1: vivid
lime/coral/emerald, strong blue/teal, rich red/gold, violet/cyan and saturated
translucent Jelly materials respectively. No pastel-primary material palette
remains in final colored bodies; small ivory masks provide contrast.

Current: `Assets/Pets/World2/concepts-v2/`. Original v1 retained as superseded.
Ten original/copied World2 PNG pairs have matching SHA256 and1536x1024 headers
in World2/verification.json. Exact generation/edit prompts saved locally.
Root Assets/Pets README and catalog.json index ten preferred egg sheets and50
pet concepts for future modeling. Three original user style refs and all
Forest revisions retained. Assets/Pets .gitignore exception prevents accidental
omission from a future authorized backup; existing PNG LFS applies.

Static-art scope; no 3D/Studio/mobile, rewards, purchases or profiles changed.
No Update Log, permanent standard, commit, push, asset upload or publication.

### Treasure Egg fifth pet replacement — 2026-11-09

Built-in ImageGen edit replaces rejected Treasure Mimic with Legendary Ruby
Koi (ruby square cube, emerald eyes, broad gold fins and fan tail). Four other
pets, saturated palette, captions and layout visually retained. Exactly five
complete pets, full new silhouette within cell. Saved PNG/exact prompt in
Assets/Pets/World2/concepts-v3; copy/source SHA256 matches. Catalog/modeling
index points at v3; older Mimic sheets retained as superseded. Rojo HTTP200.
Static scope only; no game/model/paid reward or permanent-standard changes.

## Clover Bunny Blender model and exports — 2026-11-09

Rojo HTTP200; connected Blender5.2.3, original default Scene inspected/backed up.
Requested species Clover Bunny built against approved Forest v4 despite Frost
name in request. Created one soft cube body, cream/pink palette, green textured
iris gradients/two catchlights, alpha blush, tiny feet, bent ear/clover/rear tail.
Actual front/rear Blender renders reviewed; ear silhouette and lighting refined.

Files in Assets/Pets/ForestEgg/models/CloverBunny/v1/model: clean single-scene
BLEND, GLB and FBX. Evaluated export9,988 triangles; max1,330 per component,
zero degenerates,31 exported meshes. Two image resources packed/embedded;
GLB no external URI; FBX extracted its embedded images under isolated-copy.fbm.
Same-session independent reimports preserve bounds/orientation: BLEND/GLB error0,
FBX0.00000036. All three reimport renders checked for colors, eyes, blush and ears.
Details: work/export-validation.json and roundtrip-*.png; source scripts retained.

Original Cube/Camera/Light transforms unchanged. Asset collection also linked
into original Scene; clean CloverBunny scene left active in the open Blender.
Verification scenes/copies removed; before/full-authoring backups saved in work.
Catalog links model files. No Studio import/upload, gameplay/profile/Update Log,
permanent-standard, commit or publication changes. In-engine behavior unverified.

## Egg preview — 2026-11-09

Rojo delivered the new React view to the Ball place. A PC Play capture shows
the Forest Egg title, three discovered portraits, one black silhouette, real
drop rates, and prices for one and three eggs. All four portraits were loaded
and black in a fresh-player fixture. Adding one discovery restored its colour
with no corresponding pet in inventory. The Admin Egg's 3D fallback rendered
black, and Void Egg showed 0.05% for the Secret pet. Guaranteed mode showed one
pet at 100%.

Native clicks dispatched counts 1 and 3 to isolated callbacks and dispatched
neither with full storage. Play confirmed switching eggs, three approach and
retreat cycles, blocking during a modal, and reopening on modal close. Hover
and press reached 1.08 and 0.96. Opening reached 0.05 → 1.06 → 1, closing
reached 0.05 before fade, and Effects Off reset portrait and button motion.
The opening sound was observed in SoundService. Update Log v0.8.0 opened,
scrolled, expanded and collapsed the new item, loaded its avatar and closed.

Lune verified migration from current inventory, retention after recycling and
normalization, per-profile isolation, and clearing on full reset. Studio
verified reload on in-memory data. No hatch transaction against the real
profile was run. The full gate passed 151 Lune cases and five gate tests with
zero type diagnostics. Play stopped and its test fixtures were removed.
Mobile verification is deferred under AGENTS.md.

Evidence is in `Assets/UI/EggPreview/verification/`.

### Egg preview in 3D — 2026-11-09

This revision supersedes the earlier screen placement. PC Play measured the
billboard at 634 px and 366.5 px across two zooms. The centre attachment moved
0.36 studs with the egg and matched its model bounds within 0.00003 studs.
The centre and the left/right offsets stayed on the billboard. The round E,
Hatch 1 and Hatch 3 sent 1/1/3 through native mouse clicks to isolated callbacks.
E/R sent 1/3, and turning the camera away removed the shortcut and tutorial
target. The tutorial hand matched its projected target within 0.27 px.

Switching stands and leaving restored the native signs. The Update Log blocked
the billboard, opened and scrolled, expanded and collapsed the revised item,
and loaded the author avatar. Closing it restored the egg UI. The final gate
passed 151 Lune tests and five gate tests with zero type diagnostics.

Studio capture omits the always-on-top billboard. The saved composition shot
uses a temporary depth offset and size compensation. Production depth and size
were restored, then Play was stopped. Native input was tested with production
depth settings. Evidence is in `Assets/UI/EggPreview/verification/` under
`2026-11-09-worldspace.*`.

### Egg preview viewport fit — 2026-11-09

PC Play at 1366×767 measured the native billboard at two camera distances
and near all four edges. All six samples fit between the measured HUD bounds
with at least 10 px clearance. E stayed centred in the close and far samples.
Native clicks after both horizontal and vertical adjustment dispatched 1/1/3
to isolated callbacks. The last-kick caption hid on approach and returned on
leaving. The revised Update Log was checked on PC and Play stopped.

The close diagnostic screenshot and measurements are in
`Assets/UI/EggPreview/verification/2026-11-09-viewport-fit.*`. The screenshot
uses a temporary copy with depth and size compensation. Native input and
fit were checked on the production billboard. The full verification gate
passed with 151 Lune cases, five gate tests and zero type diagnostics.

### Forest Egg replacement completion — 2026-11-09

Clover Bunny and Acorn Squirrel now replace the remaining mushroom and cake
templates. Their saved species IDs stay unchanged. Profile normalization
verified the new names, equipped UID, Golden form and both discovery flags.
The five Forest portraits now share a 24 px black outline at 512 × 512,
matching Frost. Two new Model assets and five bold Image assets were approved
and granted to Ball. Asset IDs and operations are saved beside the exports.

Fresh PC Play loaded every Forest portrait and texture. The production
portrait/model components displayed all five together; the production Pets
page displayed five ordinary portraits and both Golden replacement meshes.
The obsolete Golden mushroom exception was removed. Both real follower
components resolved the replacement meshes, kept textures and disabled
collisions. Fixtures were isolated from saved profiles and removed afterward.

Evidence: `RojoTest/assets/pets/forest-v1/verify-completion.json`,
`studio-complete.jpg` and `studio-golden-inventory.jpg`. The full project gate
passed 151 Lune tests, five gate tests, formatting, lint, Rojo build and zero
type diagnostics. No old displayed mushroom/cake names or portrait URLs
remain in runtime sources. Play stopped; map layout was not rebuilt.

### Magma Egg models and UI — 2026-11-09

Five vibrant pets now replace the third World1 egg's visuals. The saved egg
ID remains Rare; Shark/CloudBird/AngelCat/IceCat map to Coal Mole/Cinder
Gecko/Ember Ram/Inferno Phoenix. Blaze Bat adds the Epic slot. Exhaustive
10,000-roll verification gives 55/30/10/4/1. Existing equipment, UIDs,
Golden form and discoveries survived isolated profile normalization.

All fifteen BLEND/GLB/FBX files passed isolated reimport, matching triangle
counts and bounds within 0.000001 units, with packed images. Five models
have 5,464 / 6,912 / 8,208 / 7,748 / 9,852 triangles. All 78 authored mesh
parts are closed manifolds with positive signed volume. Front, back and
roundtrip render contact sheets are saved beside the modeling source.

Five ImageGen portraits from actual model renders are transparent 512px
RGBA with a uniform 24 px black outline. All ten uploads are Approved and
granted to Ball, including dependencies. Runtime uses independent Rojo
templates with white tint, canonical rotation and a 1.8-stud cube body.
The temporary inserted package copies were removed; prior templates are
archived as an unreferenced file outside the scene.

PC Play loaded every portrait and texture. Four imported model angles,
actual follower components, Golden/Flame texture retention, production
inventory, egg collection, mystery silhouettes, hatch results and workshop
were verified using isolated UI snapshots and client data. Both hatch tiers
displayed readable names and x2.8/x4.6 boosts. The production proximity
controller mounted to the actual Magma_Plate_01 anchor and read back all
five loaded portraits; the native billboard did not appear in MCP capture,
so its identical production panel was captured separately. This was an
asset replacement, with no changes to the billboard's runtime code.

The same-day unpublished Update Log was updated and checked on PC for
open/close, expand/collapse, scrolling, text fit and Dakemo555's avatar.
Full gate passed 151 Lune tests, five gate tests, lint/formatting, Rojo build,
ProfileStore integrity and zero type diagnostics. Temporary fixtures were
removed and Play stopped. No map builder or purchase was invoked.

Evidence: `RojoTest/assets/pets/magma-v1/verify-studio.json`,
`verify-exports.json`, `verify-topology.json` and saved Studio screenshots.

### Void Egg models and UI — 2026-11-09

All five BLEND/GLB/FBX sets passed reimport with packed textures and matching
bounds and triangle counts. The Blender topology audit found 76 closed parts
across the five pets. Each upload uses one mesh and an embedded 1024 px atlas.
The portrait exporter verified 512 px RGBA and a 24 px outline for each PNG.

All ten assets received approval and permission for Ball. The five template
meshes, textures and portrait IDs loaded in PC Play. The production UI rendered
all five in inventory, egg catalogue, hatch results and workshop. The proximity
controller read back five loaded portraits and the correct discovery tints
at the actual Void stand. The admin icon helper and follower controller
resolved all five visuals. A Golden Rift Wyrm retained the textured mesh.

The 10,000 possible rolls gave 5,500 / 3,000 / 1,395 / 100 / 5 by slot.
An isolated saved profile kept all five species IDs, UIDs, discovery flags,
equipment, Golden form and Cosmic mutation. Singularity displayed Secret
and ×10 Skill on the hatch result. The Update Log opened, expanded, scrolled,
collapsed and closed with the credited avatar loaded.

The project gate passed 151 Lune tests, five gate tests and type checking.
Temporary fixtures were removed and Play stopped. Results and captures are in
`RojoTest/assets/pets/void-v1/`.

### Solar Crown Egg models, UI and Wins hatch — 2026-11-09

All fifteen editable Blender, GLB and FBX files passed independent reimport.
The topology audit found 89 closed mesh parts. Each Studio upload packs one
mesh with a 1024 px color atlas. All five built-in ImageGen portraits passed
512 px RGBA and 24 px black contour checks. Roblox approved all ten assets
and granted Ball access to their dependencies.

The fifth Football City stand uses its original Celestial shell. A targeted
Edit update replaced the legacy caption and verified all 29 other parts kept
their geometry and collision properties. Fresh Play confirmed the real prompt
and hatch destination. The normal server hatch code ran with isolated state.
It charged 900,000 Wins for three pets, gated capacity, availability and policy,
and guaranteed Honey Bee for a restricted player. All 10,000 rolls matched
55/30/10/4/1%. Solar Crown appeared only in World1. The existing Shop offer
showed Glitched Dragon at ×25 Skill with Off Sale status. The isolated paid
reward test confirmed the same dragon ID and boost after normalization.

PC Play verified all five models and textures in follower components, plus
matching portraits in the egg preview, collection, inventory, workshop,
admin panel and hatch results. The catalogue shows all five cards without
scrolling at 1366×767. Native Hatch and Hatch 3 clicks dispatched the correct
egg and count in the test fixture. The Update Log opened, expanded, scrolled,
collapsed and closed with Dakemo555's confirmed avatar.

The project gate passed 151 Lune tests, five gate tests, formatting, Selene,
Rojo build and Luau type checking. Studio captures and results are stored in
`RojoTest/assets/pets/solar-crown-v1/`. The verification fixtures used isolated
state and were removed before returning to Edit.
