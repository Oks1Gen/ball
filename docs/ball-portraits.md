# Ball inventory portraits

All ten balls use generated ImageLabel portraits in `CollectorUI/InventoryPages.luau`, in both the grid and selected-item detail. The legacy `HudPanels` inventory uses the same images under its moving visual plate. `Modules/BallCardArt.luau` maps the existing saved ball IDs to uploaded Image assets. World, held and flying ball models are unchanged.

Runtime sources: `Assets/UI/Balls/v1/ui-normalized/`; asset IDs: `Assets/UI/Balls/v1/roblox-assets.json`. Original ImageGen files remain in `final/`. The normalization measures the largest inscribed circle of each alpha silhouette with an exact Euclidean distance transform, centers the body and gives every ball a 660px diameter on a transparent 1024px square. Decorations are preserved with at least 52px canvas clearance. Measured body diameters after resampling: 659.32–660.63px (under 0.2% spread). This prevents Sun's orbital ring and stars from shrinking its ball. Both UI contexts use ScaleType.Fit with the same image box per item; no per-ball UI scaling or stretching.

Verification, October 31, 2026:

- Full `node RojoTest/tools/check.mjs` passed: StyLua, Selene, 89 Luau tests, 5 gate tests, Rojo build and type check (0 new, 0 stale). Two resolved type-check baseline entries were refreshed.
- Rojo-delivered source verified in the target place 106456161057435.
- Studio Play, desktop 1366×767: mounted the actual Pages.Balls component in an isolated React fixture using the game's Sibling ZIndexBehavior. All ten Image assets loaded; all grid portraits were ImageLabels with equal 79×65px image boxes, and no ball ViewportFrames. The selected portrait box remained 164×191px across Rubber, Volcano and Sun; real GUI clicks updated the expected asset correctly. No purchase/equip request was sent.
- Screenshots verified consistent visible sphere sizes, transparency, preserved outlines and decorations. The fixture showed all ten cards together.
- Mounted the real legacy Update Log panel, verified the new entry is readable, scrolling changes CanvasPosition, and close hides the window.
- The normal gameplay screen was waiting for an offline claim; the fixture avoided claiming it or editing profile progress. Test GUI and temporary changes were removed, original GUI enable states restored, Play stopped.
- Mobile checks deferred under AGENTS.md.
