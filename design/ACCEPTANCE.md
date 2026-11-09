# Acceptance — original gameplay restoration

2026-11-08. Profile: prototype. Scope: removal of the rejected experiment and restoration of the original game. Based on `mem.mjs accept --cwd C:/Users/dakem/Documents/RobloxGames/ball --profile prototype` (69 cross-domain items); unrelated art, shop, VFX, new-project and motion-style criteria are out of scope, not counted as passed.

- [x] Original bootstraps, networking and world references restored: reviewed Git diff and clean status for these files (RBX-03, WF-11).
- [x] Real server-only ProfileStore preserved: project integrity/routing gate passed (RBX-04).
- [x] Formatting, Selene, Rojo build, 132 Lune tests and five verification tests passed, with zero type diagnostics (RBX-05).
- [x] Both authored worlds unchanged: 83,530 part comparisons in Edit; zero differences (WORLD-01/02 preservation scope).
- [x] Desktop original game loaded: World1 spawn, SkippingHUD/CollectorUI/BallTopbar and SkippingRemotes observed in Play. No mobile checks (WF-05).
- [x] Experimental course, controls, modules and prototype-only archives removed; original safety backups retained. No unrelated file cleanup (WF-01, WF-06).
- [x] Disk documentation and restoration Update Log entry describe the final rollback (WF-03).
- [ ] Last Update Log edit delivered through Rojo and checked in its UI (WF-11, BALLUI-06): Studio's plugin disconnected. HTTP server is responding; original bootstraps were already restored and tested. Pending plugin reconnection, not counted as passed.

7 / 8 scoped checks complete. See `docs/verification.md` for evidence and limitations. No standard rules, references, inbox items, commits or publication were created.

## CEO balance audit — 2026-11-08

Profile: prototype. Scope: read-only progression audit and a proposed numerical model. Existing restoration acceptance above is preserved. The 69-item standard was generated with `mem.mjs accept`; implementation, visuals, mobile UI and publication checks are outside this audit and are not counted as passed.

- [x] Mandatory Rojo server checked before continuing the project audit: HTTP 200 on localhost:34872; no second server started (WF-10).
- [x] Active source formulas, training contacts, pet stacking, egg costs, gifts, ball effects, offline rewards and rebirth reset were inspected. Evidence: source paths and observations in `balance-review-2026-11-08.md`.
- [x] Studio MCP confirmed target place/universe, current configuration and scene-derived shot limits; no world builders, Play restart or UI automation used (WF-05, WF-11).
- [x] Reproducible arithmetic completed: `node design/balance-model-2026-11-08.mjs`, exit 0. Current model reproduces all five World1 shot snapshots returned by Studio; rarity mean/median/p90/p95 and rebirth sensitivity through r=30 are reported.
- [x] Facts, proposed parameters, model assumptions and unavailable telemetry are separated; unsupported late progression is explicitly identified (WF-03, WF-06).
- [x] Existing game source, saved profiles, paid rights and scene left untouched by this audit. Only audit documentation/model and this appended checklist were written. No player-facing Update Log entry applies to an analysis-only task.
- [ ] Proposed progression verified in Play: not implemented; remains a future implementation check.
- [ ] Target session times and retention effect measured: no fresh-player sessions or cohort telemetry collected; model estimates are not counted as observed results.

6 / 8 audit checks complete. The two remaining checks concern the proposed gameplay, not completed implementation. No permanent standard changes, commits, purchases, live experiments or publication.

## Progression implementation — 2026-11-08

Profile: prototype. This section supersedes the audit's pending implementation status. User overrides: additive training balls; no direct flight bonus; bubbles twice less frequent with original strengths; no rebirth/lane changes. Standard generated again with `mem.mjs accept`; unrelated art/map/new-project/mobile checks excluded, not marked passed. Moment inventory: `balance-implementation.md`.

- [x] Rojo HTTP 200, target Studio verified, source delivery checked and fresh Play used. No duplicate server or UI automation (WF-10/11).
- [x] Additive training formula, exact rare-drop count, normal pet migration, paid/custom preservation, upgrade boundaries, malformed input and duplicate claims verified by 140 Lune tests (RBX-03/04/05).
- [x] Full formatting/lint/build/type/integrity gate passed, zero diagnostics. Evidence in `RojoTest/.tools/balance-check-console.log` (RBX-05).
- [x] Server runtime: 184 isolated checks across VerifyBalanceRuntime, VerifyTwoStageKick and VerifyBallGameplay. No gameplay profile mutations. Rebirth math and lanes preserved.
- [x] New progression UI uses existing React components and shared motion. PC fixture exercised upgrade, recycle confirmation, claim states, odds scrolling and readable multipliers; imported/raster portraits loaded (RBX-02, WF-05).
- [x] Update Log v0.6.0 author confirmed in Client; date/version/text/avatar and details expand/collapse observed. Historical restoration entry retained (BALLUI-06).
- [x] Feedback retains existing button/notification springs and sound paths. Main progression toast observed; isolated fixtures cleaned and Play stopped (FEEL-03 code/motion scope, WF-06).
- [x] Tunables, formulas, migration, evidence and limitations documented; no changes to permanent standard, publishing or paid rights (WF-03).
- [x] Main success sound observed Playing=true/IsLoaded=true; isolated full Secret reveal driven by five E presses and captured with x10 labels. No gameplay remote or profile mutation. Observer and hatch handle removed (FEEL-03).
- [ ] Full fresh-player session and retention/time targets: not measured. Fixed-loadout calculations are not a Play completion result.

9 / 10 scoped checks complete. Gameplay and feedback implemented and checked; full session pacing measurement remains pending. Mobile testing deferred by project instructions.


## Pet Workshop — 2026-11-08

Profile: prototype. Scope: duplicate-based forms, five replacing mutations, PC UI/feedback, persistent data and one station. Standard generated in `.tools/workshop-acceptance.txt`; unrelated new-project, mobile and new-particle requirements excluded by scope/project rules. Moment inventory: `pet-workshop-implementation.md`.

- [x] Rojo200, single agent, disk/Rojo source delivery and target Studio fresh Play; no map rebuild via manual builder, no Computer Use (WF-10/11).
- [x] Guaranteed five-pet craft, probabilistic1–4, higher-form outcomes and complete Normal→Golden→Diamond→Rainbow chain; exact configured odds and terminal Rainbow checked in Lune/Commands/UI.
- [x] Five mutations, exact weighted distribution, weaker result replaces stronger, exact spend, form retained; Cosmic→Wind fixture observed (code/economy scope).
- [x] Server owns random result/spends; policy, malformed selections, ownership/equipped guards, cooldown and replay boundary tested;20 isolated Commands checks,0 profile writes (RBX-03/04).
- [x] Old upgrade refund once, form/mutation/base/revision persist, no compounding; migration tests pass, paid/custom bonuses retained.
- [x] Full local gate:147 Lune +5 gate tests, formatting/lint/build/types/ProfileStore all pass (RBX-05).
- [x] PC UI adapts shared shell, blur, existing icon/chrome/button motion; selection, slots, autofill, odds, confirmation, reel, success/failure and mutation downgrade exercised (UI-03/04, SMOBM).
- [x] Feedback: reel motion, result art/model/labels, success and failure Sound.Playing/IsLoaded observed; temporary fixtures/observers cleaned (FEEL-03 scoped moments).
- [x] New station39 parts/916 source triangles, three model formats reimported;9/9 footprint support rays and four Edit angles inspected; exactly one station through boot and native E opens (world/3d scope).
- [x] Documentation/settings/asset sources and unpublished Update Log0.7.0 updated; confirmed Dakemo555 credit, expansion/collapse/scroll/open/close checked (WF-03, BALLUI-06).
- [ ] Full new-player and endgame pacing/retention measured: not collected. Starting tuning remains a hypothesis, not a cohort result.

**10 / 11 scoped checks complete.** Implementation acceptance complete; session pacing measurement remains pending. No mobile test, publication, purchase, commit or permanent standard write.


## Pet Workshop inventory regression — 2026-11-08

Profile: prototype; scope: missing pets, equipped eligibility and overlapping station prompt. The previous synthetic UI fixture did not verify the live split snapshot; its earlier display acceptance is superseded here.

- [x] Reproduced root cause in live source transport, compared progress/inventory contracts; no saved pets removed.
- [x] Real profile shows6 owned pets, matching auto-fill4/5 and mutation view; observed on fresh Play, not inferred from fixture.
- [x] Equipped/protected/terminal pets stay visible with reasons; direct unequip and protected autofill exercised on the corrected canonical fixture.
- [x] Canonical fixture performs successful fusion, updates inventory count and replaces mutation with exact cost; no real spending.
- [x] Station prompt hidden while modal open; prior prompt state restored after close; common modal/hatch flow audited.
- [x]149 Lune +5 gate checks pass, including real Snapshot.apply regression tests and eligibility cases; type/lint/build clean.
- [x] Current unpublished Update Log and docs updated; Studio QA cleaned, Play stopped; no publication/commit/mobile test.

**7 / 7 scoped checks.** Long-session pacing remains the separate open item above.

## Pet inventory concept sketches — 2026-11-08

Profile: prototype. Scope: static desktop visual exploration only. Standard generated with `mem.mjs accept`; implementation, Play, mobile, motion, gameplay and publication criteria are outside this task and are not counted as passed. Existing acceptance sections are preserved.

- [x] Rojo checked before project work: HTTP 200 at localhost:34872; no duplicate server started (WF-10).
- [x] User references distinguished: original Pets UI supplies pet identity/data; immersive reference supplies perspective card treatment; subsequent reference supplies button design. Three compositions generated and visually inspected, with 01 selected by the user (UI-03, scoped visual comparison).
- [x] All sketches omit the Balls/Pets/Eggs sidebar. Four owned pets, their multipliers and three equipped checks remain visible. Final 01 and 01B have a single Unequip action on the detached right card. Evidence: final PNGs under `Assets/UI/Pets/immersive-concepts/2026-11-08/`.
- [x] Refinement 01B keeps the detached card/dark inventory and adopts large lime Equip Best, cyan illustrated action capsule, separate team/storage pill, thick contours and extruded button bases. Labels, actions, counts and screen margins visually inspected. No additional purchases or mechanics proposed.
- [x] Four final PNGs saved at 1672x941 and source/copy SHA256 matched; reference inputs, exact prompts, output provenance and limitations saved beside them. Git status contains no conflict copies (WF-01/04/06, artifact scope).

**5 / 5 scoped static-design checks complete.** Cursor parallax, rotation, hover/press, motion settings and hit targets remain unimplemented and unverified. No source UI, scene, profiles, Update Log, permanent standard, commit or publication changed by this task.

### Concept 01C refinement

Same date/profile and static-only scope. Rojo rechecked: HTTP 200. Exact prompt and provenance: `Assets/UI/Pets/immersive-concepts/2026-11-08/refinement-01c.json`.

- [x] Main backing visibly translucent over the blurred world, grey-blue with a thin black frame; original-style small upright red square close button. Evidence: `concept-01c-translucent-flat-card.png` compared visually with the user's current UI screenshot.
- [x] Approved lower Equip Best, Recycle/Power/Craft and team/storage controls retained; all four pet data labels and three equipped checks visible.
- [x] Right detail is depicted as a single flat plane in 3D perspective; thick blue sidewall and separate pet depth removed. Motion remains an illustration, not a runtime test.
- [x] PNG, exact prompt and new references saved; source/copy SHA256 matched. No conflict copies, source/UI implementation changes or permanent-standard writes.

**4 / 4 scoped static refinement checks complete.** Previous concepts retained. Interactive behavior remains unimplemented and unverified.

### Concept 01D refinement

Same date/profile and static-only scope. Rojo rechecked: HTTP 200. Evidence: `Assets/UI/Pets/immersive-concepts/2026-11-08/concept-01d-rounded-contained-footer.png`; exact prompt/provenance: `refinement-01d.json` beside it.

- [x] Detached flat perspective card has four rounded corners; no thick sidewall added. Visually inspected generated output.
- [x] Equip Best, utility capsule and team/storage capsule, including their drawn bases, fit inside the main black border with visible side/bottom padding. Grid well reduced from below without obscuring pet tiles.
- [x] Approved button design, translucent main backing, original-style close X and all pet data retained. PNG saved and source/copy SHA256 matched.

**3 / 3 scoped static refinement checks complete.** Prior variants retained; runtime input and 3D motion remain outside these sketches.

## Pets 01D implementation — 2026-11-09

Profile: prototype. This section supersedes the sketches' unimplemented status. Standard regenerated to `RojoTest/.tools/pets-ui-acceptance.txt`. Scope: desktop inventory UI; phone tests excluded by AGENTS.md, unchanged gameplay/economy/map/commerce/new-project criteria excluded rather than passed. Moment inventory: `design/pets-inventory-implementation.md`.

- [x] Mandatory Rojo HTTP200; target place106456161057435, disk edits delivered and fresh Play used. Single agent, no Computer Use or world builders (WF-10/11).
- [x] React Luau/Ripple retained; server-only ProfileStore unchanged and hash/routing gate passes (RBX-02/03/04).
- [x] Main shell/close match existing UI; no Pets sidebar; approved contained footer and existing pet art. Four new separate transparent icons generated, approved/shared and IsLoaded=true in Play (UI-01/03/04, artifact scope).
- [x] Footer including maximum1.14 growth stays within shell; long names wrap/fit; extreme tilt keeps29.879px close/card separation and21.48px screen margin. Evidence in `verification/results.json` beside assets (UI-02/06, SMOBM-02).
- [x] Rounded single-plane detail:24px radius, invisible0.01-stud support/PartRole, PlayerGui-owned native buttons. Projected Equip/Unequip, hover1.08 and disabled press0.96 measured in canonical isolated fixture; disabled action not dispatched.
- [x] Canonical60-pet fixture scrolls via native wheel to the last rendered row. Empty Find Eggs works and removes the plane. Real inventory remained4/60; no fixture touched saved profiles.
- [x] Recycle confirmation blocks detail; cancel preserves4 and confirm4→3 fixture pets. Best/Sort/Craft callbacks exercised; real Craft opens Window_PetCraft and removes the pet detail.
- [x] Effects Off freezes tilt/scale, On resumes. Camera tracking error0.000372px. Five rapid reversal cycles leave one plane/surface; final close leaves zero (SMOBM-05/10, motion/cleanup scope).
- [x] Shared window/button animation retained; reused project click IsLoaded/Playing=true through SkippingSounds, measured0.845417s. Feedback moments documented (FEEL-03 scoped UI actions).
- [x] Final full check:149 Lune +5 gate tests, StyLua/Selene/build/require/ProfileStore pass and0 known/new/stale diagnostics. Log `.tools/pets-ui-check-console.log` (RBX-05).
- [x] Update Log0.8.0 for2026-11-09 with confirmed Dakemo55511789507527; author/avatar, opening/closing, expand/collapse, fit and scroll checked. published=false, history preserved.
- [x] Documentation, prompts, Image/Decal IDs, evidence and capture limitations saved; final runtime errors empty, temporary observers/fixtures removed, capture changes restored and Play stopped. No commit/publication/permanent standard write.
- [ ] Exact normal-runtime screenshot including AlwaysOnTop plane: engine capture omits it. Reproduced with an independent plain native SurfaceGui; a separately labelled world-pass proof verifies geometry/content but is not counted as this screenshot check. See `docs/pets-inventory.md` and `Assets/UI/Pets/immersive-v1/verification/results.json`.

**12 / 13 scoped checks complete.** Remaining item is the engine screenshot limitation; functional PC checks passed. Mobile deferred by project rules.

## Forest Egg pet roster sketches — 2026-11-09

Profile: prototype. Scope: names and one static 2x2 concept sheet; criteria from
`mem.mjs accept` scoped to this deliverable. Gameplay, UI motion, models, Play,
mobile and publishing are outside this task, not counted as passed.

- [x] Rojo HTTP 200 verified before project reads; server started hidden with the required default.project.json and port 34872. Initial sandbox socket denial resolved by an approved local connectivity check.
- [x] Actual first-egg display title Forest Egg and four existing chances 55/30/14/1% checked in EggSigns, GameConfig and Core/Balance.
- [x] User reference proportions retained: rounded cubes, tiny feet, large expressive eyes and smooth plastic shading. Four full-body characters visually reviewed in `Assets/Pets/ForestEgg/concepts-v1/forest-egg-roster-v1.png`.
- [x] Forest theme and rarity are carried by distinct large forms: long ears, acorn-capped squirrel tail, two fox tails/flower collar, broad guardian antlers/leaf mantle/amber seeds. Static sheet inspected; runtime silhouette readability remains unverified.
- [x] PNG, user reference copies, exact built-in ImageGen prompt, names and limitations saved together. Source/copy SHA256 matches. No game source changes or permanent standard writes.

**5 / 5 scoped static-design checks complete.** User preference remains pending;
this is a proposal, not approval to replace or import game pets.

### Forest Egg simplification v2 — 2026-11-09

Same prototype/static-only scope. User likes soft rendering and pet shapes;
requested less detail/foliage. Rojo HTTP 200 rechecked before this edit.

- [x] Four forms, expressions, rarity labels and 55/30/14/1% preserved in the visually inspected v2 PNG.
- [x] Fox floral collar and guardian foliage/mantle/amulet/particles removed; bunny clover and squirrel cap simplified. Twin tails and broad antlers keep silhouette distinctions.
- [x] ImageGen edit prompt, PNG and scope notes saved in `Assets/Pets/ForestEgg/concepts-v2/`; copy/source SHA256 matches. Original preserved; no permanent-standard write.

**3 / 3 static refinement checks complete.** In-game rendering remains unverified.

### Forest Egg square-base correction v3 — 2026-11-09

Same static prototype scope; Rojo HTTP 200 verified.

- [x] Fox and guardian visually show one square box body with flat faces and tiny feet, matching the upper pets' construction; separate head/torso removed.
- [x] Soft rendering, facial identities, two fox tails, guardian antlers, four labels/odds and minimal decoration preserved in `Assets/Pets/ForestEgg/concepts-v3/forest-egg-roster-v3.png`.
- [x] Exact built-in ImageGen prompt and scope notes retained; image source/copy hashes match. Earlier versions preserved. No game or permanent-standard changes.

**3 / 3 scoped static checks complete.** Runtime geometry and game-scale appearance remain unverified.

### Forest Egg five-pet roster v4 — 2026-11-09

User requires five pet designs in every egg. This task completes the first
egg concept only. Prototype static scope; Rojo HTTP 200 verified.

- [x] Exactly five pets visually present: bunny, squirrel, fox, new Moon Owl, guardian. Owl follows forest theme with a simple nocturnal palette/crescent.
- [x] All five use single square cube bodies, soft edges and tiny feet; no separate head/torso or restored foliage. Original four identities retained.
- [x] Proposed 55/30/10/4/1% labels visually correct and total 100%; explicitly distinguished from unchanged production 55/30/14/1% pool.
- [x] Sheet, exact built-in ImageGen prompt and design rationale retained in `Assets/Pets/ForestEgg/concepts-v4/`; source/copy hashes match. Earlier versions preserved.

**4 / 4 scoped static checks complete.** Other egg concepts and in-game
implementation are outside this request; no permanent-standard write.

## World1 remaining egg roster concepts — 2026-11-09

Prototype static-design scope. Four remaining eggs, including premium Solar
Crown, requested after approval of Forest Egg's five-pet sheet. Reused the
generated standard checklist; runtime/UI/motion/economy criteria are outside scope.

- [x] Rojo HTTP 200 checked before project work. Actual four display titles verified in EggSigns; premium production pool distinguished from concept proposal.
- [x] Exactly five complete pets in each of Frost, Magma, Void and Solar Crown: 20 new pet concepts visually inspected in four PNGs.
- [x] All core bodies read as single square cubes with small soft bevels, tiny feet and faces directly on front; no separate head/neck/torso. Soft materials and low detail follow approved Forest reference.
- [x] Species/silhouettes and palettes fit each egg; broad wings/horns/tails/halo/orbit carry rare identities. Void retains a Secret concept. No new probability values shown or production reward changes.
- [x] All names/rarity labels readable and correct, full appendages inside cells. Four files are 1536x1024 with source/copy SHA256 matching (`verification.json`).
- [x] Exact built-in ImageGen prompts, roster names, design rationale, provenance and limitations saved in `Assets/Pets/World1/remaining-eggs-v1/`; prior Forest concepts preserved. No permanent-standard write.

**6 / 6 scoped static checks complete.** User revisions pending. 3D geometry,
game-scale readability, Play and probability/balance implementation unverified.

## World2 pet concepts and saved modeling reference library — 2026-11-09

Prototype static-art scope. User requested five pets for each World2 egg and
project-local preservation of references for later modeling, then explicitly
requested brighter saturated World2 colors instead of pastel.

- [x] Rojo HTTP200 checked before work. Five World2 themes/keys verified against OceanEggCatalog and docs/ocean-eggs.md.
- [x] Exactly five square-base pets for each of Kelp, Leviathan, Treasure, Abyss and Jelly; 25 new species concepts, names/rarities read visually.
- [x] All five final v2 sheets have visibly stronger actual material saturation than v1; soft edges/faces/species retained. Jelly remains translucent. Flat cube fronts/sides stay readable.
- [x] Full appendages remain inside cells; labels correct and no percentages introduced. Each PNG header confirms1536x1024; original/copy SHA256 matches in World2/verification.json.
- [x] All10 preferred sheets and50 named concepts indexed locally in Assets/Pets/README.md and catalog.json. Original user refs, exact prompts, earlier versions and provenance preserved. World2 v1 clearly superseded by v2; Forest current version is v4.
- [x] Assets/Pets allowed through .gitignore with existing PNG LFS rules. Docs index links library; no source implementation or permanent-standard write.

**6 / 6 scoped static checks complete.** New sheets await user corrections.
3D topology, turnarounds, transparency ordering, Studio lighting and game-scale
readability remain unverified. No commit, push, upload or publication performed.

### Treasure fifth pet replacement v3 — 2026-11-09

Static prototype scope. User rejected Treasure Mimic; Rojo HTTP200 checked.

- [x] Fifth pet replaced by Ruby Koi: single ruby cube, gold fins/fan tail, green eyes; saturated palette and soft style visually retained.
- [x] Four other pets, names/rarities/layout preserved; exactly five complete pets in v3 PNG. Ruby Koi remains inside its cell.
- [x] PNG/prompt saved, source/copy SHA256 matches; catalog and modeling index now select v3 and Ruby Koi. Prior sheets retained as history. No permanent-standard write.

**3 / 3 scoped static checks complete.** User review and 3D checks pending.

## Clover Bunny Blender model — 2026-11-09

Prototype scope: one static editable model, placed in the open Blender, plus
portable deliverables. User named Frost Egg but specifically requested Clover
Bunny; Forest v4 is the correct species reference. No egg reassignment.

- [x] Rojo HTTP200 checked first; Blender MCP scene/version/units inspected. Original default scene preserved and backed up before model creation.
- [x] Reference opened; single soft square body, cream/pink/green palette, upright/folded ears, tiny feet, low glossy eyes/catchlights, blush, clover and round rear tail compared in actual front/rear renders.
- [x] Face orientation -Y and root at ground; separate meaningful parts/modifiers retained. Evaluated export9,988 triangles, maximum1,330 per part, zero degenerate triangles; closed volumes outward. Face overlays intentional.
- [x] Clean BLEND contains only one asset scene, no staging/default objects; two used images packed. GLB has no external resources; FBX carries embedded images extracted/packed by importer.
- [x] BLEND, GLB and FBX independently reimported from isolated deliverable copies. Dimensions/orientation checked; bounds error at most0.00000036 units. Three reimport renders visually match colors/eyes/blush/forms.
- [x] User scene's original object transforms preserved; verification copies removed. Clean CloverBunny scene active with material colors. Source scripts, reports, previews and full-session backup saved; catalog indexes all3 model files.

**6 / 6 scoped Blender/export checks complete.** User visual approval, Roblox
import, in-engine appearance/performance and animation are outside this task.
No source gameplay, Update Log, permanent-standard write, commit or publication.

## Pets 01D — visual revision after rejection, 2026-11-09

Profile: prototype. Scope: the user's six requested corrections to the first implementation. Reused `mem.mjs context ui motion code feel` and `accept --profile prototype`. KB: UI Style Directions / From a direction to tokens, Common mistakes, Checklist; World-Space UI / Common mistakes and Checklist. Take geometry from the approved image and preserve the project stack. The KB phone check is excluded by AGENTS.md. Prior functional acceptance does not establish visual approval.

- [x] Rojo HTTP200 and latest source delivery confirmed; React/Ripple and server-only ProfileStore preserved.
- [x] Original translucent shell and close artwork preserved; close moved22design px inside for card clearance. Source plus diagnostic screenshot.
- [x] Overall composition enlarged, card brought closer, and viewport inset corrected. Final scale1.10; sweep close clearance21.105px/right margin69.080px.
- [x] Flat rounded card retained; larger name/power labels, teal face and bounded tilt. Diagnostic capture, native text bounds and Effects Off/On measured.
- [x] Pet alpha padding trimmed without distortion; golden portrait and shard icon are separate generated transparent PNGs, Approved/shared/loaded, sources/prompts/IDs recorded in immersive-v2/manifest.json.
- [x] Footer has larger labels, short gloss and underside; all groups remain inside shell including1.14 scale/shadow allowance. Final numeric bounds recorded.
- [x] Native Equip/Unequip/disabled action, selection, recycle confirmation, fixture Recycle4→3/Best/sort/Craft; real Craft transition and60-pet scrolling verified without changing saved pets.
- [x] Effects Off stops rotation; On resumes. Three reopen cycles leave one plane; close/Craft leave zero planes/surfaces.
- [x] Final149 Lune +5 gate tests, formatting/lint/build/type/integrity checks pass. git diff --check clean. Existing unrelated startup asset warning documented.
- [x] Same unpublishedv0.8.0 entry rewritten; Dakemo555 identity confirmed, PC open/close/expand/collapse/readability checked. Docs/evidence saved and Play stopped.
- [ ] Exact normal AlwaysOnTop + blur visual capture: Roblox capture limitation persists. Diagnostic image is explicitly labelled and its temporary changes restored. No claim of pixel-identical normal rendering.

**10 / 11 scoped technical checks complete.** Visual comparison is supplied for review; the user has not yet approved the new appearance. No mobile test, permanent-standard write, commit, push or game publication.

### Follow-up: rarity background and Common frame — 2026-11-09

Scope: colour binding only, plus the user's explicit correction that Common must use the main window's dark frame. No layout or motion changes.

- [x] Native selection Rare/Uncommon/Common updates the detail gradient from Theme.Rarity; endpoints match80%/40% RGB and title bounds fit.
- [x] Common card and rarity-pill rims match Theme.Outline RGB12,13,19; neutral halo and white rarity text verified in fresh Play. Uncommon/Rare rim and halo match their rarity palette.
- [x] Final149+5 gate tests pass with0 type diagnostics; source delivery and git diff --check verified.
- [x] Current unpublishedv0.8.0 item updated; PC log open/expand/collapse/close verified, details489.5×85 fit511.07×94.53. Evidence saved, Play stopped; no saved-pet mutation.

**4 / 4 scoped checks complete.** Evidence: `Assets/UI/Pets/immersive-v2/verification/2026-11-09-rarity-colours.json`. Normal-render capture limitation and mobile deferral from the broader revision still apply.

## Egg preview — 2026-11-09

Prototype scope: the desktop proximity overlay and saved pet discoveries.
KB: Pet Hatching and Following End to End, Common mistakes and Checklist.
Rates come from the existing pools, and grants remain server-owned.

- [x] PC capture shows the game's theme, rarity cards, real chances, and one/triple action prices. The Normal selector is absent. UI-01, UI-03, UI-04, UI-05.
- [x] Fresh fixture has black portraits. A discovery restores colour without an inventory copy. The 3D fallback obeys discovery, and migration, retention and reset pass Lune.
- [x] Proximity opens, switches and closes over repeated approaches. Modal overlap blocks actions. Native clicks send 1/3 to isolated callbacks and full storage blocks both.
- [x] Ripple motion uses shared tokens. Hover 1.08, press 0.96, open 0.05–1.06, close 0.05 and Effects Off were observed. The right-hand buttons keep their visual gap. SMOBM-01–03, SMOBM-05–10, SMOBM-12–13.
- [x] Portraits float over rotating rays, and the opening sound is present in SoundService. Hatch uses the existing reveal. FEEL-01, FEEL-03.
- [x] Rojo source verified in Studio, full gate passed 151+5 tests with zero type diagnostics, Update Log checked with the confirmed author, and temporary Play fixtures removed. RBX-02–05, WF-03, WF-11.

**6 / 6 scoped prototype checks passed.** Evidence: `Assets/UI/EggPreview/verification/` and `docs/verification.md`. Modal HUD/blur is outside this proximity overlay. Mobile testing is deferred by project rules.

### World space correction — 2026-11-09

Prototype scope: place the catalogue and hatch controls around the egg in 3D.
KB: World-Space UI, BillboardGui placement and input, Common mistakes, Checklist.

- [x] Live attachment tracks the model centre and levitation. Two camera zooms give the expected perspective scaling. The catalogue is left of the egg, E is centred, and Hatch 3 sits below.
- [x] Native Play clicks dispatch 1/1/3. E/R dispatch 1/3. Off-camera shortcuts are inactive. Known and undiscovered portraits still use the correct tint.
- [x] Switching and leaving restore the old sign. The tutorial projects its hand to E. Effects Off opens instantly, and Update Log hides and restores the billboard.
- [x] Rojo source verified, 151 Lune and five gate tests passed with zero type diagnostics, Update Log checked and Play stopped.
- [ ] Production depth mode visual capture. The diagnostic screenshot uses temporary depth and size settings because Studio capture omits the production billboard. Play input was tested with production settings.

**4 / 5 scoped checks passed.** Evidence: `Assets/UI/EggPreview/verification/2026-11-09-worldspace.*`. Mobile verification remains deferred.

### Egg preview viewport fit — 2026-11-09

Prototype scope: keep the 3D egg interface within the usable PC viewport.
KB: Off-Screen Objective Markers and Waypoint Arrows, Common mistakes and Checklist.

- [x] Close and far samples keep E on the egg. All four edge samples fit between the live HUD bounds with at least 10 px clearance.
- [x] Native mouse clicks still dispatch 1/1/3 after offset in both axes. The last-kick caption clears Buy Egg and returns on exit.
- [x] Rojo source confirmed, 151 Lune and five gate tests pass, Update Log verified in Play and test copies removed.

**3 / 3 scoped checks passed.** Evidence: `Assets/UI/EggPreview/verification/2026-11-09-viewport-fit.*`. The earlier production screenshot limitation and mobile deferral still apply.

### Acorn Squirrel Blender model — 2026-11-09

Prototype scope covers the second Forest Egg model and its reference renders. Rojo answered HTTP 200 before work. Blender ran in background mode.

- [x] Front and rear renders show the square caramel body, cream markings, amber eyes, short paws, and cocoa-capped acorn tail. The unseen rear follows the same palette.
- [x] Model has 9,678 evaluated triangles, ground pivot, and −Y front. The triangle check reports zero degenerate faces.
- [x] BLEND, GLB, and FBX reimports preserve bounds and front orientation. Three embedded textures and the smile survive reimport. Review renders and measurements are in `Assets/Pets/ForestEgg/models/AcornSquirrel/v1/work/`.

**3 / 3 scoped Blender checks passed.** Roblox Studio appearance remains unverified.

### Forest Egg models 3–5 — 2026-11-09

Prototype scope covers Bloom Fox, Moon Owl and Grove Guardian. Rojo responded
with HTTP 200 and the models were built in background Blender. KB sections
used were Chibi Character Rules in Practice and Shape Language and Silhouette
Testing.

- [x] Front and rear renders show the reference palette and rounded square bodies. Bloom Fox has two cream-tipped tails, Moon Owl has scalloped wings and a crescent, and Grove Guardian has branched antlers with amber tips. The unseen sides follow the single reference angle.
- [x] The geometry audit confirms a ground pivot and −Y front for each model, zero degenerate triangles, and evaluated budgets of 7,872, 7,652, and 9,392 triangles.
- [x] All nine model files were reimported from isolated copies. Render checks retain facial details, body markings, and silhouette. The measurements confirm matching triangle counts, packed maps, and bounds error below 0.000001 units.
- [x] Catalog paths and both render sheets resolve. Evidence is under `Assets/Pets/ForestEgg/models/`.

**4 / 4 scoped Blender checks passed.** Roblox Studio appearance remains unverified.

### Forest Egg UI portraits — 2026-11-09

Prototype scope covers PNG artwork for Bloom Fox, Moon Owl and Grove Guardian.
The source renders use a front-left camera with both the front and top visible.

- [x] Built-in ImageGen preserved the face, palette and signature shapes in all three portraits. Blender input renders, generated originals, reference and exact prompts are retained.
- [x] Each delivered PNG is 512 × 512 RGBA. The solid black outer contour measures 18 px at all four bounds, with transparent margins of at least 22 px.
- [x] The preview on slate blue and the 150, 100, 64 and 48 px samples on a dark UI color show readable silhouettes, eyes and key accessories.

**3 / 3 scoped artwork checks passed.** Evidence is under
`Assets/UI/Pets/forest-egg-v1/`.

### Forest Egg import and UI — 2026-11-09

- [x] Three Model and three Image assets approved and shared with the target universe, including model dependencies.
- [x] One textured mesh per pet loaded in Play. Verified four angles, follower scale and disabled collisions. Golden retains the baked texture and tint.
- [x] All three portraits loaded in the collection, detail and egg panels, hatch reveal and workshop. Discovery tint and scroll behavior were checked on desktop.
- [x] Exhaustive roll counts match the concept split. Existing Rare and Legendary UIDs, species IDs, discoveries and equipment survive profile normalization.
- [x] Update Log entry and confirmed author checked on desktop. Full project gate passed and Play was stopped after fixture cleanup.

**5 / 5 scoped checks passed.** Results and asset IDs are under
`RojoTest/assets/pets/forest-v1/`.

### Frost Egg models and UI — 2026-11-09

- [x] Five soft square models match the reference silhouettes and use the later saturated palette. Blender front and rear renders and fifteen isolated reimports are saved. Every model stays under 10,000 evaluated triangles.
- [x] Five ImageGen portraits have transparent backgrounds and an equal 24 px black contour at 512 × 512. Their silhouettes and faces were checked at 150, 100, 64 and 48 px.
- [x] All ten Roblox assets are approved and accessible to Ball. The five textures and meshes loaded in Play, with verified orientation, follower scale and collision flags.
- [x] Portraits loaded in Pets, the detail card, both egg views, hatch results and workshop. Checked mystery tint, the Legendary card after scrolling, and the two highest-rarity hatch cards. Golden and Frost variants retain their textures.
- [x] Frost roll counts match 55/30/10/4/1%. Four saved species IDs retain equipment and discoveries. The new Epic can be recycled.
- [x] Update Log entry and author checked on desktop. Project gate passed 151 Lune and five gate tests with zero type errors. Test fixtures were removed and Play stopped.

**6 / 6 scoped checks passed.** Evidence is in
`RojoTest/assets/pets/frost-v1/verify-studio.json`.

### Forest Egg remaining replacements — 2026-11-09

- [x] Both authored Blender models exported as one textured mesh each, 9,988 and 9,678 triangles. Imported geometry, colors and scale checked against the source in Studio.
- [x] All five Forest portraits share transparent RGBA and a 24 px black outline. Native ImageGen sources, prompts and final preview saved in the UI manifest.
- [x] All seven required uploads approved and granted to Ball. Fresh PC Play loaded every portrait and texture; production model/portrait components and the actual inventory page were visually checked.
- [x] Common/Uncommon saved IDs, equipped UID, Golden form and discoveries survive normalization. Real follower components use the new meshes; obsolete Golden mushroom art is no longer referenced.
- [x] Update Log includes all five Forest names and the confirmed author. Full gate passed 151 Lune tests and five gate tests, zero type errors. Temporary fixtures removed, Play stopped, no map rebuild.

**5 / 5 scoped prototype checks passed.** Evidence is in
`RojoTest/assets/pets/forest-v1/verify-completion.json`.

### Magma Egg vibrant concept revision — 2026-11-09

- [x] All five original species, labels and rarity tiers retained in the generated sheet. Cube bodies, tiny paws, horns, wings and tail counts visually checked against the attachment.
- [x] Saturated charcoal/orange/violet/red/gold palette visually checked; soft forms and readable light facial patches preserved.
- [x] Full-size PNG, original attachment and exact ImageGen prompt saved under `Assets/Pets/World1/remaining-eggs-v2/`; catalog points to v2. This is concept art only, with no live game change.

**3 / 3 scoped prototype checks passed.** Image revision awaits user feedback.

### Magma Egg production models and portraits — 2026-11-09

- [x] All five pets use the vibrant reference, a soft square body, tiny paws and the original rarity silhouettes. Front and rear Blender renders visually reviewed.
- [x] Fifteen standalone BLEND/GLB/FBX files reimport with matching geometry and packed textures; all models below 10,000 triangles. All 78 authored mesh parts closed and outward-facing.
- [x] Five separately generated UI portraits retain the model view, colors and appendages, with transparent RGBA and the same 24 px black outline as Forest/Frost. Final preview visually checked.
- [x] Ten approved Roblox assets shared with Ball. Imported front/side/back/underside views, follower scale, no collisions and texture retention on variants checked in PC Play.
- [x] Five portraits loaded in production inventory, egg catalogue, mystery panel, hatch reveal and workshop. Native proximity controller read back correct portraits at the real stand; its capture limitation is recorded in verification.md, with a separate production panel screenshot.
- [x] Four saved species IDs preserve UIDs, equipment, forms and discovery history. Exact 10,000-roll distribution, Update Log interactions/author and the complete project gate checked. Fixtures removed and Play stopped.

**6 / 6 scoped prototype checks passed.** Evidence under
`RojoTest/assets/pets/magma-v1/`. No game publication performed.

### Void Egg models and portraits — 2026-11-09

- [x] Five square bodies, bright colors and reference silhouettes reviewed from the front and rear. Singularity has a separate orbit ring and cyan edges.
- [x] Five standalone BLEND/GLB/FBX sets passed reimport with packed images. Each pet has fewer than 10,000 triangles, with 76 closed parts across the set.
- [x] Five ImageGen portraits from actual Blender renders use transparent RGBA and a 24 px black outline. Final contact sheet and prompts saved.
- [x] Ten approved assets loaded through Rojo in Ball. Desktop Play verified models, followers, variants, inventory, the catalogue and nearby egg panel, hatch, workshop and admin portraits.
- [x] Five saved IDs and existing weights preserved in the roll and profile checks. Update Log verified with Dakemo555's avatar. Project gate passed and Play stopped.

**5 / 5 scoped prototype checks passed.** Evidence in `RojoTest/assets/pets/void-v1/`.

### Solar Crown Egg models and Wins hatch — 2026-11-09

Profile prototype covers five new World1 pets, their portraits and the fifth stand.

- [x] Five soft square bodies, reference silhouettes and vivid gold palette verified in Blender front and rear renders. BLEND, GLB and FBX roundtrips match their geometry and packed textures.
- [x] Five separate ImageGen edits preserve their model views. Final transparent PNGs measure 512×512 with a uniform 24 px black outline. The manifest contains exact prompts and approved asset IDs.
- [x] Each Roblox mesh and atlas loaded in Play, including all five in follower components. The five portraits loaded in the production egg preview, catalogue, inventory, hatch, workshop and admin components.
- [x] Solar Crown uses the existing World1 stand and charges 300K Wins for one and 900K for three. Its rolls and the restricted route matched the displayed odds. The Shop retained the existing Glitched Dragon offer.
- [x] Fresh PC Play confirmed five cards fit the catalogue, both hatch buttons dispatch and the Update Log opens, expands, scrolls and closes with the credited avatar. Gate passed 151 Lune tests, five gate tests and zero type errors. Play fixtures were removed.

Evidence is under `RojoTest/assets/pets/solar-crown-v1/`.
