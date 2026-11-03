# Shared egg stand

The five original egg models now sit on one connected shallow curved stand in
`Workspace.Map.World1.Lobby.EggShop.EggStand`. Common/Uncommon mirror
Rainbow/Rare around the lobby axis X=55; Volcanic stays at the center. The
existing plaza, waterfall, leaderboards and surrounding scene are preserved.

## Persistent asset and placement

`RojoTest/assets/egg-stand/egg-stand.rbxmx` is the durable native Roblox version
of the approved Blender stand. It uses Parts and WedgeParts, including actual
stud geometry; no session-only EditableMesh content or mesh upload is needed.
It omits only Blender's tiny edge bevels. The template is mapped to
`ServerStorage.EggStandTemplate`. `export_native.py` regenerates it from the
Blender source; JSON and FBX authoring sources remain alongside it.

`server/EggStandStyle.luau` runs at the end of WorldService and can be applied
independently in Edit without invoking legacy world builders. It measures the
paving and leaderboard clearance, clones the template once, fits it to the
available width, and places the original eggs by visible bounds. A second apply
does not move them further. Each slot has a transparent `SeatCenter` marker;
the complete stand's pivot is at its ground origin. The current visible width
is 118 studs, leaving five studs on each side of the inner paving. WedgePart
bounding boxes conservatively include empty triangular space; their aggregate
Model bounding box is larger than the actual stand silhouette.

Seat centers in studs (X, Y, Z):

| Egg | Center |
|---|---|
| Common | 102.2, 24.233, 275.458 |
| Uncommon | 78.795, 24.233, 280.139 |
| Volcanic | 55, 25.110, 282.479 |
| Rare | 31.205, 24.233, 280.139 |
| Rainbow | 7.8, 24.233, 275.458 |

Original imported egg visuals retain their size (10 studs high). Their bottoms
are 0.08 studs above the seats. Shells, interaction anchors and captions move
with the eggs. Legacy `EggPedestal`, `EggRing` and premium `Pedestal` remain
invisible semantic supports for the existing builders/client, with explicit
roles. All five purchase prompts, prices and egg IDs are preserved.
`Shared.VolcanicEggVisual` reads the premium model's display height and gap and
refreshes placement after `EggStandVersion` changes, including an already
created local visual. Unconfigured places retain the old defaults.

## Backup and verification — 2026-11-03

- Edit backup: `ServerStorage.WorldBackups.BeforeEggStand_20261103.EggShop`.
  The previous detached session preview was parked beside it, outside Workspace.
- Native asset: 483 visible parts plus five semantic seat markers in six slot
  models. No empty MeshIds are used by the active stand.
- 21,695 parts outside EggShop retain CFrame, Size, transparency and physics.
- Repeated narrow apply: zero transform/size drift, no extra stand clone.
- All 125 ray probes across the five seat tops hit the intended top height.
- Server Play: all five existing eggs keep their heights and 0.08-stud gaps;
  Client Play: the volcanic visual is also 10 studs high with the same gap.
- Five original prompts preserved; all four normal egg approach destinations
  resolve to ground. No hatch, purchase, receipt or profile edit was triggered.
- `check.mjs`: 107 Lune tests, five gate tests, formatting, lint, Rojo build,
  requires and typecheck pass. On this Windows machine luau-lsp corrupts
  Cyrillic paths; the successful gate used a temporary ASCII directory junction
  and Node `--preserve-symlinks --preserve-symlinks-main`, with no baseline changes.
- Update Log text was merged into the current 0.2.1 draft. Opening, scrolling
  and closing were exercised through the production panel API in Client Play;
  temporary UI was removed. Pixel-level readability could not be confirmed in
  Play: MCP reported a 1x1 viewport and screen capture did not complete. Edit
  composition was inspected in the normal desktop view. No mobile test.

The place must still be saved in Studio by the user. Nothing was committed,
uploaded as a Roblox asset or published as a game.
