# Pets inventory implementation — 01D

Scope: implement the approved desktop concept with React Luau/Ripple. Original translucent shell/close art, no Pets sidebar, contained footer, flat rounded SurfaceGui card in perspective. Preserve real inventory, variants, Equip Best, equip/unequip, sort, recycle confirmation and Pet Workshop. Other inventory screens retain their existing navigation. No mobile test, scene rebuild, paid changes or publication.

## Visual revision after user rejection — 2026-11-09

The first implementation was rejected for its composition and distant card. Keep the approved 01D image as the comparison target. Changes: composition width1180→1120, anchor X +120→+45, four-corner-based perspective, viewport inset correction, larger alpha-trimmed pet portraits/text, Golden Scarlet portrait, shard icon, contained glossy footer and larger labels. Close art is unchanged; its centre moves22 design pixels inside the shell to clear the tilted card.

Existing feedback moments below remain applicable. No new sound or camera shake; pointer motion stays subtle and Effects Off cancels it. Functional checks and visual comparison are separate: the normal AlwaysOnTop/blur capture limitation still applies, and user visual approval has not yet been received.

## Feedback moments

| Moment | Sound | UI / visual movement | Duration / behavior |
| --- | --- | --- | --- |
| Open / close | reused project UI selection sound | shared window pop, HUD slide and blur; card follows same envelope | existing bouncy-motion tokens |
| Pointer over detail | none for continuous movement | bounded 3D tilt with Ripple spring | while visible; freezes with Effects Off |
| Select pet | reused project UI selection sound | selected outline/check and detail replacement; button spring | immediate data, shared motion |
| Equip / Best | existing confirmed result notification | button press/release, checks and live counters update | existing response path |
| Recycle | existing confirmation/result path | explicit confirmation; no silent deletion | existing response path |
| Sort / Craft | reused project UI selection sound | button spring; sorting or workshop transition | shared motion |

KB: `World-Space UI - BillboardGui and SurfaceGui`, SurfaceGui/Common mistakes; `UI and GUI Animation`, hero stages/Common mistakes. Apply: PlayerGui-owned SurfaceGui, bounded canvas, one placement loop while mounted, cleanup and ReducedMotion support. Preserve server authority; test interactions without real profile spending through isolated fixtures.

Validation complete for the desktop scope:149 Lune +5 gate tests; zero diagnostics; fresh Play/source delivery; native SurfaceGui clicks/hover/disabled press; scroll60/empty/recycle fixture; real Craft; motion Off/On; camera anchoring; max-scale footer and extreme-tilt close/card gaps; final cleanup; v0.8.0 Update Log identity/controls. Exact evidence and capture caveat: `Assets/UI/Pets/immersive-v1/verification/results.json`. Mobile remains deferred by project rules. No publication, commit, profile spending or standard write.
