# Pet inventory concepts

2026-11-08. Static desktop UI sketches generated with the built-in image_gen tool from the user's supplied references. No UI implementation or Roblox upload.

- `concept-01-detached-right.png`: standalone perspective card on the right; chosen by the user.
- `concept-02-attached-right.png`: raised detail card attached to the window.
- `concept-03-detached-left.png`: large standalone card on the left.
- `concept-01b-reference-buttons.png`: button exploration. Large lime Equip Best, cyan Recycle/Power/Craft icon capsule, separate team/storage counters, chunky red Unequip and close button. Dark inventory, pet data and detached 3D card retained.
- `concept-01c-translucent-flat-card.png`: translucent-shell exploration. Original-style translucent grey-blue window with a thin black border and small upright red X; approved lower buttons retained. Right detail is a flat UI plane shown in 3D perspective, with no thick sidewall. Exact follow-up prompt, provenance and visual checks: `refinement-01c.json`.
- `concept-01d-rounded-contained-footer.png`: current refinement. Rounded corners on the flat perspective card; all three footer groups fit inside the main black frame with clear padding. Grid well shortened to free footer space; approved button style, translucent shell and pet data retained. Exact prompt and provenance: `refinement-01d.json`.

The user requested moving the buttons toward the supplied simulator UI reference. This feedback applies to this exploration; no permanent standard was written. The selected layout and buttons are visual proposals. Cursor parallax, card rotation, hover, press, hit targets and motion settings have not been implemented or tested. The directional arrow only illustrates intended movement.

Exact prompts and source/output mapping: `prompts.json`. Source reference images are preserved under `references/`. Generated images are not production UI assets or Roblox image IDs. No player-facing Update Log entry applies to these sketches.

Visual checks: all four pets, multipliers and three equipped checks preserved; Balls/Pets/Eggs sidebar absent; final 01 and 01B have one Unequip action on the detail card; footer labels and close button readable. See the appended static-design acceptance in `design/ACCEPTANCE.md`.
