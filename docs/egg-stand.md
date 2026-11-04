# Shared egg stand

Seat palette now matches the elemental replacements: Common green, Uncommon
icy blue, Volcanic gold, Rare dark lava burgundy; Rainbow retains its purple.
`EggStandStyle.colorSeats` colors only SeatRim/SeatInset facets and runs on both
existing and freshly cloned stands. Colouring itself leaves the geometry,
materials and physics unchanged; lowering and studs are described below. The runtime palette supersedes the older
authoring stand's original seat colors.

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

## Lower stand with textured studs — 2026-11-03

After the template is placed, `EggStandStyle` squashes the whole stand
vertically about its base, once, marked by the `EggStandLowered` attribute
(factor ≈ 0.684). The front band (Bay) becomes exactly one lobby stud row,
`GroundStudPitch × WorldScale` = 1.2 studs. The plan shape, seats and steps
stay. The 282 modelled bump blocks (`*_Studs<N>`) moved to
`ServerStorage.WorldBackups.EggStandStudBumps_20261103`; each keeps its slot
in `OriginalParent`.

`StandStuds` Textures use the lobby source, tile 4.8 and
`StudsTransparency`. They go on every upward face and on all vertical faces of
the one-row bands. The arc's front is the WedgePart slope. `Face = Top` draws
on it but projects local Z onto the longer slope, so `StudsPerTileV` is
shortened by Z/√(Y²+Z²). This was checked with a grid probe in Studio: square
cells, one row. Seats get their own lattice texture (see below). Eggs,
anchors and captions follow the seats; the visible gap is 0.06 at the current
scale. The seat centers in the table above predate both world scales and this
lowering.

**Path colours and rim.** `recolor` paints the stand in `Palette.Path`. The
base band (Foundation) and the raised back lip (RearRim) are `PathEdge`; seat
pads keep their egg colours. `rim` builds `EggStand.Rim` on every apply: a
`PathEdge` strip one stud row wide (1.2) and 0.05 thick on the stand top. It
follows the outline of the union of the Bay top faces, offset inward with mitred
corners. Each edge is a rectangle plus right-angle wedges at its ends, so the
pieces don't overlap (no coplanar flicker). Rim parts have no collision. Only
the middle of each edge, a whole number of studs long, carries studs. The
leftovers at both ends and the mitre triangles are smooth `RimJoint` parts in
the same colour, so no stud is cut at a corner.

`fitSeats` keeps every slot's octagons (SeatRim, SeatInset, the volcanic
RaisedBay) at least 0.15 inside the rim's inner edge. It shrinks them
horizontally about `SeatCenter` by a binary-searched factor stored in
`SeatFit`: Common/Rainbow 0.910, Uncommon/Rare 0.932, Volcanic 0.755. A
second apply finds them already inside and leaves them as they are. Eggs keep
their size and seat height.

**Centre steps.** `steps` snaps both treads to whole studs. The back line,
where the upper tread meets the stand, and the heights stay as authored. The
upper tread is 14.4 × 2.4 (was 14.08 × 2.38). The lower tread is 16.8 × 4.8:
one stud wider on each side, with an exposed front of 2.4 (was 2.14, so its
front moved 0.26 forward). `StepRim` lays a `PathEdge` strip one stud wide and
0.05 thick along each tread's open front and sides. The strips carry
whole-stud textures and have no collision. The inner row of each tread stays
path grey. The authored size and position are kept in
`OriginalSize`/`OriginalCFrame`, so a re-apply does not drift. Floor rays
across the steps read 20.24 → 21.03 → 21.60 → 22.05 (each rise ≤ 0.8). Undo
waypoint: "Before egg stand step rim". Undo waypoints: "Before/After egg stand path colours".

**Uniform lattice seats.** `seats` gives every slot the volcanic seat format
in a `SeatPad` model: a `PathEdge` dark plinth, a slot-coloured pad and a lighter
inset (Rainbow keeps its purples). The dark plinth keeps it from blending into
the grey stand. `hideSupport` also removes the Textures from the hidden legacy
pedestals: a Texture draws even on a fully transparent part, and those old
studs showed through the seat and the bottom of the egg. Layer thicknesses are 0.375, 0.27 and 0.03
stud pitches, as on the volcanic seat after lowering; all seats top out at the
same height. Each layer is an axis-aligned octagon on the 1.2 stud lattice:
plinth 8 studs across with a 2-stud corner cut, pad 6/1, inset 4/1. The
rectangles carry the lobby studs texture (tile 4.8, offset 0). Every piece is a
whole number of studs, so the studs are whole at every edge. The half studs
along the diagonals are smooth wedges. The original wedge fans (132 parts) are in
`ServerStorage.WorldBackups.EggStandSeatFans_20261103` with `OriginalParent`.
Each seat turns with the stand segment under it. The yaw comes from the nearest
rim edge, folded to ±45°, and is stored in `SeatYaw`: Common/Rainbow ∓8.8°,
Uncommon/Rare ∓9.8°, Volcanic 0. The seat is then centred across its segment.
From the authored position (`SeatOrigin`) it moves only perpendicular to the
segment, to the point of largest plinth-to-rim clearance (`SeatClearance`
0.66–0.76; front and back gaps are equal within 0.01). It keeps its place along
the arc. A re-apply always starts from `SeatOrigin`, so nothing drifts. Eggs,
prompts and captions follow the seat. Undo waypoints: "Before egg stand lattice
seats", "Before rotate egg seats".

Rollback: Ctrl+Z to "Before lower egg stand" before saving. After saving,
remove the `lower`/`studs` calls, delete EggStand and apply again: the stand is
re-cloned from the unchanged `EggStandTemplate`, bumps included.

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
